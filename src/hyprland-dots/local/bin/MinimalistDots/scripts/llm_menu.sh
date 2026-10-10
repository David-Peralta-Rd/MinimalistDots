#!/usr/bin/env bash
# llm-menu.sh — menú wofi para levantar/apagar servidores llama.cpp.
#
#   1ª pulsación : si no hay nada corriendo, abre el menú para elegir modelos.
#   2ª pulsación : si hay servidores corriendo (o cargando), los apaga.
#   Pulsar mientras el menú está abierto lo cancela.
#
# Chat/edición  -> puerto 8080
# Autocompletar -> puerto 8081
# Tu config.yaml de Continue no cambia: solo cambia el modelo que hay detrás de cada puerto.

set -u

# ---------- Configuración ----------
MODEL_DIRS=("$HOME/.cache/llama.cpp" "$HOME/models")   # dónde buscar archivos .gguf
BIG_PORT=8080
SMALL_PORT=8081
BIG_THREADS=6
SMALL_THREADS=2
SMALL_CTX=4096
GPU_LAYERS=""        # vacío = que llama.cpp decida; 0 = solo CPU; 99 = todo a la Vega (prueba con llama-bench)
READY_TIMEOUT=300    # segundos máximos esperando que cada modelo cargue
RAM_MARGIN_GIB=3     # margen para sistema + contexto al estimar si cabe en RAM
# -----------------------------------

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/llm-servers"
LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/llm-servers"
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/llm-toggle"
BIG_PID_FILE="$STATE_DIR/big.pid"
SMALL_PID_FILE="$STATE_DIR/small.pid"
LAST_FILE="$CONF_DIR/last"
NONE_LABEL="— Ninguno —"

mkdir -p "$STATE_DIR" "$LOG_DIR" "$CONF_DIR"

# ---------- Utilidades ----------
notify() {
    notify-send -a "LLM local" -t 5000 "$1" "${2:-}"
}

menu() {
    wofi --dmenu --insensitive --prompt "$1"
}

is_running() {
    local pid_file="$1"
    [[ -f "$pid_file" ]] && kill -0 "$(cat "$pid_file")" 2>/dev/null
}

stop_server() {
    local pid_file="$1" pid
    [[ -f "$pid_file" ]] || return 0
    pid="$(cat "$pid_file")"
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null
        for _ in {1..20}; do
            kill -0 "$pid" 2>/dev/null || break
            sleep 0.25
        done
        kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null
    fi
    rm -f "$pid_file"
}

friendly_name() {
    local n
    n="$(basename "$1" .gguf)"
    echo "${n##*-GGUF_}"
}

model_bytes() {
    local f="$1" prefix
    if [[ "$f" =~ ^(.*)-00001-of-[0-9]{5}\.gguf$ ]]; then
        prefix="${BASH_REMATCH[1]}"
        stat -L -c %s "$prefix"-*-of-*.gguf 2>/dev/null | awk '{ s += $1 } END { print s + 0 }'
    else
        stat -L -c %s "$f" 2>/dev/null || echo 0
    fi
}

gib() {
    awk -v b="$1" 'BEGIN { printf "%.1f", b / 1073741824 }'
}

mem_available_bytes() {
    awk '/^MemAvailable:/ { print $2 * 1024 }' /proc/meminfo
}

# ---------- Descubrir modelos ----------
declare -A MODEL_PATH=()
MODEL_LABELS=()

scan_models() {
    local dir file base label
    for dir in "${MODEL_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        while IFS= read -r -d '' file; do
            base="$(basename "$file")"
            [[ "${base,,}" == *mmproj* ]] && continue
            # En modelos partidos en shards, mostrar solo el primero.
            if [[ "$base" =~ -([0-9]{5})-of-[0-9]{5}\.gguf$ ]] && [[ "${BASH_REMATCH[1]}" != "00001" ]]; then
                continue
            fi
            label="$(friendly_name "$file")  [$(gib "$(model_bytes "$file")") GB]"
            while [[ -n "${MODEL_PATH[$label]:-}" ]]; do label+=" *"; done
            MODEL_PATH["$label"]="$file"
            MODEL_LABELS+=("$label")
        done < <(find -L "$dir" -maxdepth 3 -type f -name '*.gguf' -print0 | sort -z)
    done
}

# Muestra el menú y devuelve la ruta elegida ("-" si eligió Ninguno).
# Código de salida 1 = el usuario canceló.
pick_model() {
    local prompt="$1" choice
    choice="$({ echo "$NONE_LABEL"; printf '%s\n' "${MODEL_LABELS[@]}"; } | menu "$prompt")"
    [[ -z "$choice" ]] && return 1
    if [[ "$choice" == "$NONE_LABEL" ]]; then
        echo "-"
    else
        echo "${MODEL_PATH[$choice]}"
    fi
}

pick_context() {
    local choice
    choice="$(printf '%s\n' \
        "16K — equilibrado" \
        "8K — menos RAM, más rápido" \
        "32K — más contexto, más RAM" \
        | menu "Contexto del modelo de chat")"
    case "$choice" in
        8K*)  echo 8192 ;;
        16K*) echo 16384 ;;
        32K*) echo 32768 ;;
        *)    return 1 ;;
    esac
}

label_or_none() {
    if [[ "$1" == "-" ]]; then echo "$2"; else friendly_name "$1"; fi
}

# ---------- Arranque ----------
start_server() {   # pid_file modelo puerto ctx threads log [args extra...]
    local pid_file="$1" model="$2" port="$3" ctx="$4" threads="$5" log="$6"
    shift 6
    local args=(-m "$model" --alias "$(friendly_name "$model")" --port "$port" -c "$ctx" -t "$threads")
    [[ -n "$GPU_LAYERS" ]] && args+=(-ngl "$GPU_LAYERS")
    args+=("$@")
    setsid llama-server "${args[@]}" >"$log" 2>&1 < /dev/null &
    echo $! >"$pid_file"
}

# 0 = listo, 1 = timeout, 2 = apagado a mano, 3 = el proceso murió
wait_ready() {
    local port="$1" pid_file="$2" elapsed=0 pid
    while (( elapsed < READY_TIMEOUT )); do
        [[ -f "$pid_file" ]] || return 2
        pid="$(cat "$pid_file")"
        kill -0 "$pid" 2>/dev/null || return 3
        if curl -sf "http://127.0.0.1:${port}/health" >/dev/null 2>&1; then
            return 0
        fi
        sleep 2
        elapsed=$(( elapsed + 2 ))
    done
    return 1
}

# ---------- Dependencias ----------
for cmd in llama-server wofi notify-send curl flock; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "llm-menu: falta '$cmd' en el PATH" >&2
        command -v notify-send >/dev/null 2>&1 && notify "LLM local: error" "Falta instalar: $cmd"
        exit 1
    fi
done

# ---------- Toggle: si hay algo corriendo, apagar ----------
if is_running "$BIG_PID_FILE" || is_running "$SMALL_PID_FILE"; then
    stop_server "$BIG_PID_FILE"
    stop_server "$SMALL_PID_FILE"
    notify "LLM local apagado" "Servidores detenidos y RAM liberada."
    exit 0
fi

# Si el menú ya está abierto, volver a pulsar lo cancela.
exec 9>"$STATE_DIR/menu.lock"
if ! flock -n 9; then
    pkill -x wofi
    exit 0
fi

# ---------- Elegir combinación ----------
scan_models
if (( ${#MODEL_LABELS[@]} == 0 )); then
    notify "LLM local: sin modelos" "No encontré .gguf en: ${MODEL_DIRS[*]}"
    exit 1
fi

big="" small="" ctx=""

if [[ -f "$LAST_FILE" ]]; then
    mapfile -t last < "$LAST_FILE"
    last_big="${last[0]:--}" last_small="${last[1]:--}" last_ctx="${last[2]:-16384}"
    last_ok=1
    [[ "$last_big" != "-" && ! -f "$last_big" ]] && last_ok=0
    [[ "$last_small" != "-" && ! -f "$last_small" ]] && last_ok=0
    if (( last_ok )); then
        repeat_label="↻ Repetir: $(label_or_none "$last_big" "sin chat") + $(label_or_none "$last_small" "sin autocompletado") (ctx $last_ctx)"
        manual_label="⚙ Elegir manualmente"
        first="$(printf '%s\n' "$repeat_label" "$manual_label" | menu "LLM local")"
        [[ -z "$first" ]] && exit 0
        if [[ "$first" == "$repeat_label" ]]; then
            big="$last_big" small="$last_small" ctx="$last_ctx"
        fi
    fi
fi

if [[ -z "$big" ]]; then
    big="$(pick_model "Modelo de CHAT / EDICIÓN (:$BIG_PORT)")" || exit 0
    small="$(pick_model "Modelo de AUTOCOMPLETADO (:$SMALL_PORT)")" || exit 0
    ctx=16384
    if [[ "$big" != "-" ]]; then
        ctx="$(pick_context)" || exit 0
    fi
fi

if [[ "$big" == "-" && "$small" == "-" ]]; then
    notify "LLM local" "No elegiste ningún modelo."
    exit 0
fi

# ---------- Verificar RAM ----------
need=$(( RAM_MARGIN_GIB * 1073741824 ))
[[ "$big" != "-" ]] && need=$(( need + $(model_bytes "$big") ))
[[ "$small" != "-" ]] && need=$(( need + $(model_bytes "$small") ))
avail="$(mem_available_bytes)"
if (( need > avail )); then
    answer="$(printf '%s\n' "Continuar de todos modos" "Cancelar" \
        | menu "RAM justa: necesitas ~$(gib "$need") GB, libres $(gib "$avail") GB")"
    [[ "$answer" == "Continuar de todos modos" ]] || exit 0
fi

printf '%s\n%s\n%s\n' "$big" "$small" "$ctx" > "$LAST_FILE"

# ---------- Levantar ----------
PORTS=() PID_FILES=() NAMES=()
notify "LLM local iniciando..." "Cargando modelos, esto puede tardar."

if [[ "$big" != "-" ]]; then
    start_server "$BIG_PID_FILE" "$big" "$BIG_PORT" "$ctx" "$BIG_THREADS" "$LOG_DIR/big.log" --jinja
    PORTS+=("$BIG_PORT"); PID_FILES+=("$BIG_PID_FILE"); NAMES+=("Chat :$BIG_PORT → $(friendly_name "$big")")
fi
if [[ "$small" != "-" ]]; then
    start_server "$SMALL_PID_FILE" "$small" "$SMALL_PORT" "$SMALL_CTX" "$SMALL_THREADS" "$LOG_DIR/small.log"
    PORTS+=("$SMALL_PORT"); PID_FILES+=("$SMALL_PID_FILE"); NAMES+=("Autocomplete :$SMALL_PORT → $(friendly_name "$small")")
fi

# Liberar el candado: a partir de aquí, pulsar el atajo apaga todo.
exec 9>&-

# ---------- Esperar a que respondan ----------
ok_lines=() fail_lines=()
for i in "${!PORTS[@]}"; do
    wait_ready "${PORTS[$i]}" "${PID_FILES[$i]}"
    rc=$?
    case $rc in
        0) ok_lines+=("${NAMES[$i]}") ;;
        2) exit 0 ;;   # apagado a mano durante la carga
        3) rm -f "${PID_FILES[$i]}"; fail_lines+=("${NAMES[$i]} (se cerró; mira $LOG_DIR)") ;;
        *) fail_lines+=("${NAMES[$i]} (sin respuesta; mira $LOG_DIR)") ;;
    esac
done

if (( ${#fail_lines[@]} == 0 )); then
    notify "LLM local listo" "$(printf '%s\n' "${ok_lines[@]}")"
else
    notify "LLM local: problemas" "$(printf '%s\n' "${fail_lines[@]}")"
fi

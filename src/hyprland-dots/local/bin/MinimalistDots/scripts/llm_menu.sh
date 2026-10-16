#!/usr/bin/env bash
# ==============================================================================
# LLM local — menú (Quickshell, md_menu) para levantar / apagar servidores llama.cpp
#   Chat / edición  -> puerto 8080
#   Autocompletado  -> puerto 8081
#
# Uso:
#   llm-menu.sh toggle   (por defecto) Atajo: si hay servidores los apaga; si hay
#                        un menú abierto lo cancela; si no, abre el menú.
#   llm-menu.sh start    Abre el menú e inicia.
#   llm-menu.sh stop     Apaga todo.
#   llm-menu.sh status   Muestra qué está corriendo.
#
# Si algo falla en silencio, mira:  ~/.cache/llm-servers/menu.log
# ==============================================================================
set -uo pipefail

# ---------- Configuración ----------------------------------------------------
# Carpetas donde buscar archivos .gguf ya descargados
MODEL_DIRS=("$HOME/.cache/llama.cpp" "$HOME/.cache/huggingface/hub" "$HOME/models")

# Modelos que llama-server puede descargar solo la primera vez (-hf).
# Formato:  "Etiqueta|repo[:cuantización]|tamaño aprox. en GB"
PRESETS=(
    "Qwen3-Coder 30B-A3B Q4_K_M|unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:Q4_K_M|18.6"
    "Qwen2.5-Coder 1.5B Q8_0 (autocompletado)|ggml-org/Qwen2.5-Coder-1.5B-Q8_0-GGUF|1.7"
)

BIG_PORT=8080
SMALL_PORT=8081
BIG_THREADS=6
SMALL_THREADS=2
SMALL_CTX=4096
# GPU (Vega integrada). 0 = solo CPU y SIN inicializar Vulkan (recomendado: la Vega
# comparte la RAM y suele dar "device lost"). Un número N = N capas a la Vega.
# Vacío = que llama.cpp decida (puede fallar en APUs).
GPU_LAYERS=0
READY_TIMEOUT=600     # segundos máximos esperando que cargue (la 1ª vez incluye descarga)
RAM_MARGIN_GIB=3      # margen para sistema + contexto al estimar si cabe en RAM

# -----------------------------------------------------------------------------

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/llm-servers-$UID"
LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/llm-servers"
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/llm-toggle"
BIG_PID_FILE="$STATE_DIR/big.pid"
SMALL_PID_FILE="$STATE_DIR/small.pid"
PROMPT_FILE="$STATE_DIR/prompt.pid"   # proceso que está mostrando los menús
LAST_FILE="$CONF_DIR/last"
MENU_LOG="$LOG_DIR/menu.log"
NONE_LABEL="— Ninguno —"

mkdir -p "$STATE_DIR" "$LOG_DIR" "$CONF_DIR"

log() { printf '%s %s\n' "$(date +%T)" "$*" >> "$MENU_LOG"; }

# Las notificaciones nunca rompen el script (igual que en el pomodoro).
notify() {
    log "notify: $1 | ${2:-}"
    notify-send -a "LLM local" -t 6000 "$1" "${2:-}" 2> /dev/null || true
}


# ==============================================================================
# MENÚ (md_menu, Quickshell)
# ==============================================================================
MD_MENU="$(dirname "$SELF")/md_menu"

# menu <titulo>   (las opciones llegan por stdin; imprime la línea elegida)
menu() {
    "$MD_MENU" llm --prompt "$1" || true
}


# ==============================================================================
# UTILIDADES
# ==============================================================================
is_running() {
    [ -f "$1" ] && kill -0 "$(cat "$1" 2> /dev/null)" 2> /dev/null
}

stop_server() {
    local pid_file="$1" pid
    [ -f "$pid_file" ] || return 0
    pid="$(cat "$pid_file" 2> /dev/null || true)"
    if [ -n "$pid" ] && kill -0 "$pid" 2> /dev/null; then
        kill "$pid" 2> /dev/null || true
        for _ in {1..40}; do
            kill -0 "$pid" 2> /dev/null || break
            sleep 0.25
        done
        kill -0 "$pid" 2> /dev/null && kill -9 "$pid" 2> /dev/null
    fi
    rm -f "$pid_file"
}

gib() { awk -v b="$1" 'BEGIN { printf "%.1f", b / 1073741824 }'; }

mem_available_bytes() { awk '/^MemAvailable:/ { print $2 * 1024 }' /proc/meminfo; }

# Una "ref" es una ruta a un .gguf  o  "hf:repo[:cuant]" (se descarga con -hf).
friendly_name() {
    local ref="$1" n
    if [[ "$ref" == hf:* ]]; then
        n="${ref#hf:}"; n="${n##*/}"; n="${n%%:*}"; n="${n%-GGUF}"
    else
        n="$(basename "$ref" .gguf)"; n="${n##*-GGUF_}"
    fi
    echo "$n"
}

ref_bytes() {
    local ref="$1" prefix preset size
    if [[ "$ref" == hf:* ]]; then
        for preset in "${PRESETS[@]}"; do
            IFS='|' read -r _ repo size <<< "$preset"
            [ "hf:$repo" = "$ref" ] && { awk -v g="$size" 'BEGIN { printf "%d", g * 1073741824 }'; return; }
        done
        echo 0; return
    fi
    if [[ "$ref" =~ ^(.*)-00001-of-[0-9]{5}\.gguf$ ]]; then
        prefix="${BASH_REMATCH[1]}"
        stat -L -c %s "$prefix"-*-of-*.gguf 2> /dev/null | awk '{ s += $1 } END { print s + 0 }'
    else
        stat -L -c %s "$ref" 2> /dev/null || echo 0
    fi
}


# ==============================================================================
# DESCUBRIR MODELOS
# ==============================================================================
MODEL_LABELS=(); MODEL_REFS=()

add_entry() {
    local label="$1" ref="$2" n=2 base="$1" l
    for l in "${MODEL_LABELS[@]+"${MODEL_LABELS[@]}"}"; do
        if [ "$l" = "$label" ]; then label="$base ($n)"; n=$((n + 1)); fi
    done
    MODEL_LABELS+=("$label"); MODEL_REFS+=("$ref")
}

scan_models() {
    local dir file base preset label repo size real
    declare -A seen=()

    for dir in "${MODEL_DIRS[@]}"; do
        [ -d "$dir" ] || continue
        while IFS= read -r -d '' file; do
            base="$(basename "$file")"
            [[ "${base,,}" == *mmproj* ]] && continue
            # Modelos partidos en trozos: mostrar solo el primero.
            if [[ "$base" =~ -([0-9]{5})-of-[0-9]{5}\.gguf$ ]] && [ "${BASH_REMATCH[1]}" != "00001" ]; then
                continue
            fi
            # Evitar duplicados (el caché de huggingface usa enlaces simbólicos)
            real="$(readlink -f "$file")"
            [ -n "${seen["$real"]+x}" ] && continue
            seen["$real"]=1
            add_entry "$(friendly_name "$file")  [$(gib "$(ref_bytes "$file")") GB]" "$file"
        done < <(find -L "$dir" -maxdepth 6 -type f -name '*.gguf' -print0 2> /dev/null | sort -z)
    done

    for preset in "${PRESETS[@]}"; do
        IFS='|' read -r label repo size <<< "$preset"
        add_entry "⬇ $label  [~$size GB, se descarga]" "hf:$repo"
    done
}

# pick_model <titulo>  → imprime la ref elegida ("-" = ninguno). Falla si se cancela.
pick_model() {
    local choice i
    choice="$({ echo "$NONE_LABEL"; printf '%s\n' "${MODEL_LABELS[@]}"; } | menu "$1")"
    [ -z "$choice" ] && return 1
    if [ "$choice" = "$NONE_LABEL" ]; then echo "-"; return 0; fi
    for i in "${!MODEL_LABELS[@]}"; do
        if [ "${MODEL_LABELS[$i]}" = "$choice" ]; then
            echo "${MODEL_REFS[$i]}"; return 0
        fi
    done
    return 1
}

pick_context() {
    local choice
    choice="$(printf '%s\n' "16K — equilibrado" "8K — menos RAM, más rápido" "32K — más contexto, más RAM" \
        | menu "Contexto del chat")"
    case "$choice" in
        8K*)  echo 8192 ;;
        16K*) echo 16384 ;;
        32K*) echo 32768 ;;
        *)    return 1 ;;
    esac
}

label_or_none() { if [ "$1" = "-" ]; then echo "$2"; else friendly_name "$1"; fi; }


# ==============================================================================
# ARRANQUE
# ==============================================================================
# start_server <pid_file> <ref> <puerto> <ctx> <hilos> <log> [args extra...]
# El PID se escribe desde el propio proceso (bash -c + exec), así siempre es el
# de llama-server aunque setsid se bifurque.
start_server() {
    local pid_file="$1" ref="$2" port="$3" ctx="$4" threads="$5" log="$6"
    shift 6
    local args=()
    if [[ "$ref" == hf:* ]]; then args+=(-hf "${ref#hf:}"); else args+=(-m "$ref"); fi
    args+=(--alias "$(friendly_name "$ref")" --host 127.0.0.1 --port "$port" -c "$ctx" -t "$threads")
    if [ "$GPU_LAYERS" = "0" ]; then
        args+=(-ngl 0 --device none)      # CPU pura: ni siquiera toca Vulkan
    elif [ -n "$GPU_LAYERS" ]; then
        args+=(-ngl "$GPU_LAYERS")
    fi
    args+=("$@")

    rm -f "$pid_file"
    log "start: llama-server ${args[*]}"
    setsid bash -c 'echo $$ > "$1"; shift; exec "$@"' _ "$pid_file" llama-server "${args[@]}" \
        > "$log" 2>&1 < /dev/null &

    # Esperar a que el PID quede escrito (evita falsos "apagado a mano")
    for _ in {1..60}; do [ -s "$pid_file" ] && break; sleep 0.05; done
}

# 0 = listo · 1 = tiempo agotado · 2 = apagado a mano · 3 = el proceso murió
wait_ready() {
    local port="$1" pid_file="$2" elapsed=0 pid
    while [ "$elapsed" -lt "$READY_TIMEOUT" ]; do
        [ -f "$pid_file" ] || return 2
        pid="$(cat "$pid_file" 2> /dev/null || true)"
        { [ -n "$pid" ] && kill -0 "$pid" 2> /dev/null; } || return 3
        if curl -sf --max-time 2 "http://127.0.0.1:${port}/health" > /dev/null 2>&1; then
            return 0
        fi
        sleep 2
        elapsed=$((elapsed + 2))
    done
    return 1
}


# ==============================================================================
# COMANDOS
# ==============================================================================
check_deps() {
    local missing=()
    for cmd in llama-server qs curl; do
        command -v "$cmd" > /dev/null 2>&1 || missing+=("$cmd")
    done
    if [ "${#missing[@]}" -gt 0 ]; then
        notify "LLM local: faltan programas" "Instala: ${missing[*]}"
        return 1
    fi
}

stop() {
    stop_server "$BIG_PID_FILE"
    stop_server "$SMALL_PID_FILE"
}

status() {
    local any=0
    if is_running "$BIG_PID_FILE";   then echo "chat         :$BIG_PORT   PID $(cat "$BIG_PID_FILE")";     any=1; fi
    if is_running "$SMALL_PID_FILE"; then echo "autocomplete :$SMALL_PORT   PID $(cat "$SMALL_PID_FILE")"; any=1; fi
    [ "$any" -eq 0 ] && echo "apagado"
    return 0
}

start() {
    check_deps || return 1

    if is_running "$BIG_PID_FILE" || is_running "$SMALL_PID_FILE"; then
        notify "LLM local" "Ya está activo."
        return 0
    fi

    echo $$ > "$PROMPT_FILE"
    trap 'rm -f "$PROMPT_FILE"' EXIT

    scan_models

    local big="" small="" ctx="" first repeat_label manual_label
    local last_big last_small last_ctx last_ok
    local -a last=()

    if [ -f "$LAST_FILE" ]; then
        mapfile -t last < "$LAST_FILE"
        last_big="${last[0]:--}"; last_small="${last[1]:--}"; last_ctx="${last[2]:-16384}"
        last_ok=1
        [ "$last_big" != "-" ]   && [[ "$last_big" != hf:* ]]   && [ ! -f "$last_big" ]   && last_ok=0
        [ "$last_small" != "-" ] && [[ "$last_small" != hf:* ]] && [ ! -f "$last_small" ] && last_ok=0
        if [ "$last_ok" -eq 1 ]; then
            repeat_label="↻ Repetir: $(label_or_none "$last_big" "sin chat") + $(label_or_none "$last_small" "sin autocompletado") (ctx $last_ctx)"
            manual_label="⚙ Elegir manualmente"
            first="$(printf '%s\n' "$repeat_label" "$manual_label" | menu "LLM local")"
            [ -z "$first" ] && return 0
            if [ "$first" = "$repeat_label" ]; then
                big="$last_big"; small="$last_small"; ctx="$last_ctx"
            fi
        fi
    fi

    if [ -z "$big" ]; then
        big="$(pick_model "Modelo de CHAT / EDICIÓN (:$BIG_PORT)")" || return 0
        small="$(pick_model "Modelo de AUTOCOMPLETADO (:$SMALL_PORT)")" || return 0
        ctx=16384
        if [ "$big" != "-" ]; then
            ctx="$(pick_context)" || return 0
        fi
    fi

    if [ "$big" = "-" ] && [ "$small" = "-" ]; then
        notify "LLM local" "No elegiste ningún modelo."
        return 0
    fi

    # --- ¿Cabe en RAM? ---
    local need avail answer
    need=$((RAM_MARGIN_GIB * 1073741824))
    [ "$big" != "-" ]   && need=$((need + $(ref_bytes "$big")))
    [ "$small" != "-" ] && need=$((need + $(ref_bytes "$small")))
    avail="$(mem_available_bytes)"
    if [ "$need" -gt "$avail" ]; then
        answer="$(printf '%s\n' "Continuar de todos modos" "Cancelar" \
            | menu "Necesitas ~$(gib "$need") GB y hay $(gib "$avail") GB libres")"
        [ "$answer" = "Continuar de todos modos" ] || return 0
    fi

    printf '%s\n%s\n%s\n' "$big" "$small" "$ctx" > "$LAST_FILE"

    # A partir de aquí ya no hay menús abiertos: pulsar el atajo apaga todo.
    rm -f "$PROMPT_FILE"
    trap - EXIT

    local -a ports=() pid_files=() names=() logs=()
    notify "LLM local iniciando..." "Cargando modelos; la primera vez descarga."

    if [ "$big" != "-" ]; then
        start_server "$BIG_PID_FILE" "$big" "$BIG_PORT" "$ctx" "$BIG_THREADS" "$LOG_DIR/big.log" --jinja
        ports+=("$BIG_PORT"); pid_files+=("$BIG_PID_FILE"); logs+=("$LOG_DIR/big.log")
        names+=("Chat :$BIG_PORT → $(friendly_name "$big")")
    fi
    if [ "$small" != "-" ]; then
        start_server "$SMALL_PID_FILE" "$small" "$SMALL_PORT" "$SMALL_CTX" "$SMALL_THREADS" "$LOG_DIR/small.log"
        ports+=("$SMALL_PORT"); pid_files+=("$SMALL_PID_FILE"); logs+=("$LOG_DIR/small.log")
        names+=("Autocomplete :$SMALL_PORT → $(friendly_name "$small")")
    fi

    local -a ok_lines=() fail_lines=()
    local i rc tail_log
    for i in "${!ports[@]}"; do
        wait_ready "${ports[$i]}" "${pid_files[$i]}"
        rc=$?
        case $rc in
            0) ok_lines+=("${names[$i]}") ;;
            2) return 0 ;;   # alguien lo apagó durante la carga
            3) rm -f "${pid_files[$i]}"
               tail_log="$(tail -n 2 "${logs[$i]}" 2> /dev/null | tr '\n' ' ')"
               fail_lines+=("${names[$i]} se cerró: ${tail_log:-sin detalle}") ;;
            *) fail_lines+=("${names[$i]}: sin respuesta (mira ${logs[$i]})") ;;
        esac
    done

    if [ "${#fail_lines[@]}" -eq 0 ]; then
        notify "LLM local listo" "$(printf '%s\n' "${ok_lines[@]}")"
    else
        notify "LLM local: problemas" "$(printf '%s\n' "${fail_lines[@]}")"
    fi
}

# Mismo atajo: si hay menús abiertos los cancela; si hay servidores los apaga; si no, inicia.
toggle() {
    if [ -f "$PROMPT_FILE" ] && kill -0 "$(cat "$PROMPT_FILE" 2> /dev/null)" 2> /dev/null; then
        kill "$(cat "$PROMPT_FILE")" 2> /dev/null || true
        "$MD_MENU" --close
        rm -f "$PROMPT_FILE"
        return 0
    fi

    if is_running "$BIG_PID_FILE" || is_running "$SMALL_PID_FILE"; then
        stop
        notify "LLM local apagado" "Servidores detenidos y RAM liberada."
    else
        start
    fi
}

case "${1:-toggle}" in
    toggle) toggle ;;
    start)  start ;;
    stop)   stop; notify "LLM local apagado" ;;
    status) status ;;
    *)
        echo "Uso: $(basename "$0") {toggle|start|stop|status}" >&2
        exit 1
        ;;
esac

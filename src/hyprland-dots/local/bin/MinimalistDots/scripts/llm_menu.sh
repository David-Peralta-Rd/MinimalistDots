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
#   llm-menu.sh doctor   Diagnóstico: llama-server, red, Hugging Face, disco y RAM.
#   llm-menu.sh up [chat|fim|all]
#                        Arranque SIN menús con los modelos de ~/.config/ai/models.env
#                        (lo usa ai.sh / ai-up para agentes y Continue). Mismos PID,
#                        logs y puertos que el menú: status y stop funcionan igual.
#
# Los modelos que no tengas se descargan con curl (reanudable) a ~/models.
# Si algo falla, mira:  ~/.cache/llm-servers/menu.log  y  download.log
# ==============================================================================
set -uo pipefail

# ---------- Configuración ----------------------------------------------------
# Dónde se guardan los modelos descargados y dónde buscar archivos .gguf
DOWNLOAD_DIR="$HOME/models"
MODEL_DIRS=("$DOWNLOAD_DIR" "$HOME/.cache/llama.cpp" "$HOME/.cache/huggingface/hub")

# Modelos que el script puede descargar solo (archivo exacto de Hugging Face).
# Formato:  "Etiqueta|repo|archivo.gguf|tamaño aprox. en GB"
PRESETS=(
    "Qwen3-Coder 30B-A3B Q4_K_M|unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF|Qwen3-Coder-30B-A3B-Instruct-Q4_K_M.gguf|18.6"
    "Qwen2.5-Coder 1.5B Q8_0 (autocompletado)|ggml-org/Qwen2.5-Coder-1.5B-Q8_0-GGUF|qwen2.5-coder-1.5b-q8_0.gguf|1.7"
)
HF_BASE="${HF_BASE:-https://huggingface.co}"   # puedes apuntarlo a un mirror
# Conexiones en paralelo al descargar (máx. 16). Requiere aria2; sin él se usa curl (1 conexión).
DL_CONNECTIONS=16

BIG_PORT=8080
SMALL_PORT=8081
BIG_THREADS=6
SMALL_THREADS=2
SMALL_CTX=4096
# GPU (Vega integrada). 0 = solo CPU y SIN inicializar Vulkan (recomendado: la Vega
# comparte la RAM y suele dar "device lost"). Un número N = N capas a la Vega.
# Vacío = que llama.cpp decida (puede fallar en APUs).
GPU_LAYERS=0
READY_TIMEOUT=600     # segundos máximos esperando que el modelo cargue en memoria
RAM_MARGIN_GIB=3      # margen para sistema + contexto al estimar si cabe en RAM

# ---------- Configuración compartida con el módulo de IA (ai.sh) --------------
# ~/.config/ai/models.env (opcional) fija modelos, puertos, hilos y contexto para
# `llm_menu.sh up`, y es lo mismo que usan Continue y los agentes. Si existe, sus
# valores mandan sobre los de arriba. El menú sigue funcionando igual sin él.
AI_ENV="${AI_ENV:-${XDG_CONFIG_HOME:-$HOME/.config}/ai/models.env}"
if [ -f "$AI_ENV" ]; then
    # shellcheck disable=SC1090
    source "$AI_ENV"
    BIG_PORT="${CHAT_PORT:-$BIG_PORT}"
    BIG_THREADS="${THREADS:-$BIG_THREADS}"
    SMALL_PORT="${FIM_PORT:-$SMALL_PORT}"
    SMALL_THREADS="${FIM_THREADS:-$SMALL_THREADS}"
    SMALL_CTX="${FIM_CTX:-$SMALL_CTX}"
    GPU_LAYERS="${NGL:-$GPU_LAYERS}"
fi
CHAT_CTX="${CHAT_CTX:-16384}"

# -----------------------------------------------------------------------------

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/llm-servers-$UID"
LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/llm-servers"
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/llm-toggle"
BIG_PID_FILE="$STATE_DIR/big.pid"
SMALL_PID_FILE="$STATE_DIR/small.pid"
PROMPT_FILE="$STATE_DIR/prompt.pid"   # proceso que está mostrando los menús
DL_FILE="$STATE_DIR/download.pid"     # proceso que está descargando un modelo
DL_LOG="$LOG_DIR/download.log"
LAST_FILE="$CONF_DIR/last"
MENU_LOG="$LOG_DIR/menu.log"
NONE_LABEL="— Ninguno —"

mkdir -p "$STATE_DIR" "$LOG_DIR" "$CONF_DIR"
CURL_PID=""
PROGRESS_ID=""

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

# Una "ref" es una ruta a un .gguf  o  "dl:repo/archivo.gguf" (se descarga con curl).
friendly_name() {
    local ref="$1" n
    n="$(basename "$ref" .gguf)"
    n="${n##*-GGUF_}"
    echo "$n"
}

dl_file() { local x="${1#dl:}"; echo "${x##*/}"; }
dl_repo() { local x="${1#dl:}"; echo "${x%/*}"; }
dl_path() { echo "$DOWNLOAD_DIR/$(dl_file "$1")"; }

preset_bytes() {
    local preset label repo file size
    for preset in "${PRESETS[@]}"; do
        IFS='|' read -r label repo file size <<< "$preset"
        [ "dl:$repo/$file" = "$1" ] && { awk -v g="$size" 'BEGIN { printf "%d", g * 1073741824 }'; return; }
    done
    echo 0
}

ref_bytes() {
    local ref="$1" prefix
    if [[ "$ref" == dl:* ]]; then
        if [ -f "$(dl_path "$ref")" ]; then stat -L -c %s "$(dl_path "$ref")"; else preset_bytes "$ref"; fi
        return
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
    local dir file base preset label repo gfile size real part extra
    declare -A seen=() have_file=()

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
            have_file["$base"]=1
            add_entry "$(friendly_name "$file")  [$(gib "$(ref_bytes "$file")") GB]" "$file"
        done < <(find -L "$dir" -maxdepth 6 -type f -name '*.gguf' -print0 2> /dev/null | sort -z)
    done

    for preset in "${PRESETS[@]}"; do
        IFS='|' read -r label repo gfile size <<< "$preset"
        [ -n "${have_file["$gfile"]+x}" ] && continue     # ya está descargado: aparece arriba
        extra="se descarga"
        part="$DOWNLOAD_DIR/$gfile.part"
        [ -f "$part" ] && extra="descarga a medias: $(gib "$(stat -c %s "$part")") GB"
        add_entry "⬇ $label  [~$size GB, $extra]" "dl:$repo/$gfile"
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
# start_server <pid_file> <ruta .gguf> <puerto> <ctx> <hilos> <log> [args extra...]
# El PID se escribe desde el propio proceso (bash -c + exec), así siempre es el
# de llama-server aunque setsid se bifurque.
start_server() {
    local pid_file="$1" ref="$2" port="$3" ctx="$4" threads="$5" log="$6"
    shift 6
    local args=(-m "$ref")
    args+=(--alias "$(friendly_name "$ref")" --host 127.0.0.1 --port "$port" -c "$ctx" -t "$threads")
    if [ "$GPU_LAYERS" = "0" ]; then
        args+=(-ngl 0)                    # CPU pura
        # ni siquiera toca Vulkan (solo si esta versión de llama-server conoce --device)
        supports_device_flag && args+=(--device none)
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
# DESCARGA DE MODELOS (curl, reanudable)
# No usamos `llama-server -hf`: depende de cómo se compiló llama.cpp (libcurl/OpenSSL),
# falla en silencio según la red y no avisa del espacio en disco.
# ==============================================================================
supports_device_flag() {
    if [ -z "${HAS_DEVICE_FLAG:-}" ]; then
        if llama-server --help 2>&1 | grep -q -- '--device'; then HAS_DEVICE_FLAG=1; else HAS_DEVICE_FLAG=0; fi
    fi
    [ "$HAS_DEVICE_FLAG" = "1" ]
}

# Notificación de progreso: la va reemplazando (-r) y muestra una barra (hint "value")
progress_notify() {
    local id; local -a rep=()
    [ -n "$PROGRESS_ID" ] && rep=(-r "$PROGRESS_ID")
    id="$(notify-send -a "LLM local" -t 4000 -p ${rep[@]+"${rep[@]}"} -h "int:value:$3" "$1" "$2" 2> /dev/null)" || return 0
    [ -n "$id" ] && PROGRESS_ID="$id"
}

# Bytes realmente descargados: aria2 reserva el archivo "a trozos" (disperso), por eso
# se mide el espacio ocupado en disco y no el tamaño aparente.
disk_bytes() { du -B1 "$1" 2> /dev/null | awk '{ print $1 + 0 }'; }

remote_size() {
    curl -sIL --max-time 30 "$1" 2>> "$DL_LOG" | tr -d '\r' \
        | awk 'tolower($1) == "content-length:" { l = $2 } END { print l + 0 }'
}

# download_model <ref dl:...>  → 0 si el archivo quedó completo en $DOWNLOAD_DIR
download_model() {
    local ref="$1" repo file url dest part total have need free cur pct last=0 rc err
    repo="$(dl_repo "$ref")"; file="$(dl_file "$ref")"
    url="$HF_BASE/$repo/resolve/main/$file"
    dest="$DOWNLOAD_DIR/$file"; part="$dest.part"

    if ! mkdir -p "$DOWNLOAD_DIR" 2> /dev/null; then
        notify "No se puede crear $DOWNLOAD_DIR" "Revisa los permisos de tu carpeta personal."
        return 1
    fi

    total="$(remote_size "$url")"
    [ "${total:-0}" -lt 1048576 ] && total="$(preset_bytes "$ref")"     # HEAD falló: usa el tamaño aproximado
    have=0; [ -f "$part" ] && have="$(disk_bytes "$part")"
    need=$((total - have)); [ "$need" -lt 0 ] && need=0

    # ¿Cabe en el disco? (en un Linux minimalista suele ser lo primero que falla)
    free="$(df --output=avail -B1 "$DOWNLOAD_DIR" 2> /dev/null | tail -n 1 | tr -d ' ')"
    if [ -n "$free" ] && [ "$need" -gt 0 ] && [ "$free" -lt "$need" ]; then
        notify "Sin espacio para descargar $file" "Hacen falta ~$(gib "$need") GB y hay $(gib "$free") GB libres en $DOWNLOAD_DIR."
        return 1
    fi

    log "download: $url -> $dest (total ~$total, ya hay $have)"
    printf '%s descarga %s\n' "$(date '+%F %T')" "$url" >> "$DL_LOG"
    local tool="curl"
    command -v aria2c > /dev/null 2>&1 && tool="aria2c"
    notify "Descargando $(friendly_name "$file")" "$(gib "$total") GB desde Hugging Face ($( [ "$tool" = aria2c ] && echo "$DL_CONNECTIONS conexiones" || echo "1 conexión; instala aria2 para ir más rápido" )). Pulsa el atajo otra vez para cancelar."

    if [ "$total" -gt 0 ] && [ "$have" -ge "$total" ] && [ ! -f "$part.aria2" ]; then
        rc=0                              # el .part ya estaba completo
    else
        if [ "$tool" = "aria2c" ]; then
            # Trozos de 8 MB repartidos en N conexiones; -c reanuda; sin preasignar el archivo
            aria2c -c -x "$DL_CONNECTIONS" -s "$DL_CONNECTIONS" -k 8M \
                --file-allocation=none --disk-cache=64M \
                --max-tries=5 --retry-wait=3 --connect-timeout=20 \
                --auto-file-renaming=false --allow-overwrite=true \
                --summary-interval=0 --console-log-level=warn --download-result=hide \
                -d "$DOWNLOAD_DIR" -o "$file.part" "$url" >> "$DL_LOG" 2>&1 &
        else
            curl -L --fail --retry 5 --retry-delay 3 --retry-all-errors --connect-timeout 20 \
                -C - -sS -o "$part" "$url" >> "$DL_LOG" 2>&1 &
        fi
        CURL_PID=$!
        while kill -0 "$CURL_PID" 2> /dev/null; do
            sleep 3
            if [ "$total" -gt 0 ]; then
                cur="$(disk_bytes "$part")"
                pct=$((cur * 100 / total))
                if [ "$pct" -ge $((last + 10)) ]; then
                    last=$pct
                    progress_notify "Descargando $(friendly_name "$file")" "$pct % — $(gib "$cur") de $(gib "$total") GB" "$pct"
                fi
            fi
        done
        wait "$CURL_PID"; rc=$?
        CURL_PID=""
    fi

    if [ "$rc" -ne 0 ]; then
        err="$(tail -n 6 "$DL_LOG" 2> /dev/null | awk '!seen[$0]++' | tail -n 2 | tr '\n' ' ')"
        notify "Falló la descarga de $file" "$tool terminó con código $rc. ${err:-Revisa tu conexión.} (log: $DL_LOG)"
        return 1
    fi

    cur="$(stat -c %s "$part" 2> /dev/null || echo 0)"
    if [ "$total" -ge 1048576 ] && [ "$cur" -lt $((total * 99 / 100)) ]; then
        notify "Descarga incompleta de $file" "Tiene $(gib "$cur") de ~$(gib "$total") GB. Vuelve a intentarlo: continúa donde quedó."
        return 1
    fi
    mv -f "$part" "$dest" || return 1
    progress_notify "Modelo descargado" "$(friendly_name "$file")" 100
    log "download ok: $dest"
}

# resolve_ref <ref> → deja la ruta local del .gguf en $RESOLVED (descargándolo si hace falta).
# Va por variable global (no por $(...)) para que cancelar con el atajo funcione al instante.
RESOLVED=""
resolve_ref() {
    local ref="$1"
    if [[ "$ref" == dl:* ]]; then
        RESOLVED="$(dl_path "$ref")"
        [ -f "$RESOLVED" ] || download_model "$ref" || return 1
    else
        RESOLVED="$ref"
    fi
}

cleanup() { rm -f "$PROMPT_FILE" "$DL_FILE"; }

on_term() {
    [ -n "$CURL_PID" ] && kill "$CURL_PID" 2> /dev/null
    cleanup
    exit 143
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

# Diagnóstico para instalaciones nuevas: dice qué falta y por qué no descarga.
doctor() {
    local ok="✔" bad="✘" problems=0 preset label repo file size code free
    echo "== LLM local: diagnóstico =="

    if command -v llama-server > /dev/null 2>&1; then
        echo "$ok llama-server: $(llama-server --version 2>&1 | grep -m1 -i 'version' || echo 'instalado')"
        if supports_device_flag; then echo "$ok --device soportado (CPU pura con GPU_LAYERS=0)"
        else echo "· --device no existe en esta versión (se omite solo)"; fi
    else
        echo "$bad llama-server no está instalado (paquete llama-cpp)"; problems=$((problems + 1))
    fi

    if command -v aria2c > /dev/null 2>&1; then echo "$ok aria2c: descargas con $DL_CONNECTIONS conexiones en paralelo"
    else echo "· aria2c no instalado: se descarga con 1 conexión (instala el paquete aria2 para más velocidad)"; fi

    for cmd in curl qs; do
        if command -v "$cmd" > /dev/null 2>&1; then echo "$ok $cmd"
        else echo "$bad falta $cmd"; problems=$((problems + 1)); fi
    done

    code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "$HF_BASE" 2>&1)"
    if [ "$code" = "200" ] || [ "$code" = "301" ] || [ "$code" = "302" ]; then
        echo "$ok Hugging Face responde (HTTP $code)"
    else
        echo "$bad No se puede llegar a $HF_BASE (HTTP ${code:-sin respuesta}). Revisa red, DNS, proxy o certificados (ca-certificates)."
        problems=$((problems + 1))
    fi

    for preset in "${PRESETS[@]}"; do
        IFS='|' read -r label repo file size <<< "$preset"
        code="$(curl -sIL -o /dev/null -w '%{http_code}' --max-time 20 "$HF_BASE/$repo/resolve/main/$file" 2>&1)"
        if [ "$code" = "200" ]; then echo "$ok $file existe en Hugging Face (~$size GB)"
        else echo "$bad $file → HTTP ${code:-sin respuesta} (el archivo cambió de nombre o no hay red)"; problems=$((problems + 1)); fi
    done

    mkdir -p "$DOWNLOAD_DIR" 2> /dev/null
    free="$(df --output=avail -B1 "$DOWNLOAD_DIR" 2> /dev/null | tail -n 1 | tr -d ' ')"
    echo "· Espacio libre en $DOWNLOAD_DIR: $(gib "${free:-0}") GB"
    echo "· RAM libre: $(gib "$(mem_available_bytes)") GB"
    echo "· Logs: $MENU_LOG | $DL_LOG | $LOG_DIR/big.log | $LOG_DIR/small.log"

    if [ "$problems" -eq 0 ]; then echo "Todo en orden."; else echo "Problemas encontrados: $problems"; fi
    [ "$problems" -eq 0 ]
}

status() {
    local any=0
    if is_running "$BIG_PID_FILE";   then echo "chat         :$BIG_PORT   PID $(cat "$BIG_PID_FILE")";     any=1; fi
    if is_running "$SMALL_PID_FILE"; then echo "autocomplete :$SMALL_PORT   PID $(cat "$SMALL_PID_FILE")"; any=1; fi
    if [ -f "$DL_FILE" ] && kill -0 "$(cat "$DL_FILE" 2> /dev/null)" 2> /dev/null; then
        echo "descargando… (log: $DL_LOG)"; any=1
    fi
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
    trap cleanup EXIT
    trap on_term TERM INT

    scan_models

    local big="" small="" ctx="" first repeat_label manual_label
    local last_big last_small last_ctx last_ok
    local -a last=()

    if [ -f "$LAST_FILE" ]; then
        mapfile -t last < "$LAST_FILE"
        last_big="${last[0]:--}"; last_small="${last[1]:--}"; last_ctx="${last[2]:-16384}"
        last_ok=1
        [ "$last_big" != "-" ]   && [[ "$last_big" != dl:* ]]   && [ ! -f "$last_big" ]   && last_ok=0
        [ "$last_small" != "-" ] && [[ "$last_small" != dl:* ]] && [ ! -f "$last_small" ] && last_ok=0
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

    # --- Descargar lo que falte (pulsar el atajo mientras descarga lo cancela) ---
    rm -f "$PROMPT_FILE"
    echo $$ > "$DL_FILE"
    local big_path="-" small_path="-"
    if [ "$big" != "-" ]; then
        resolve_ref "$big" || return 1
        big_path="$RESOLVED"
    fi
    if [ "$small" != "-" ]; then
        resolve_ref "$small" || return 1
        small_path="$RESOLVED"
    fi

    # A partir de aquí ya no hay menús ni descargas: pulsar el atajo apaga todo.
    rm -f "$DL_FILE"
    trap - EXIT TERM INT

    local -a ports=() pid_files=() names=() logs=()
    notify "LLM local iniciando..." "Cargando modelos en memoria."

    if [ "$big" != "-" ]; then
        start_server "$BIG_PID_FILE" "$big_path" "$BIG_PORT" "$ctx" "$BIG_THREADS" "$LOG_DIR/big.log" --jinja
        ports+=("$BIG_PORT"); pid_files+=("$BIG_PID_FILE"); logs+=("$LOG_DIR/big.log")
        names+=("Chat :$BIG_PORT → $(friendly_name "$big")")
    fi
    if [ "$small" != "-" ]; then
        start_server "$SMALL_PID_FILE" "$small_path" "$SMALL_PORT" "$SMALL_CTX" "$SMALL_THREADS" "$LOG_DIR/small.log"
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

# Arranque sin menús: modelos, puertos, hilos y contexto salen de models.env.
# Imprime por la terminal (no usa notificaciones): pensado para ai-up y scripts.
#   AI_FORCE=1 llm_menu.sh up chat   -> arranca aunque la RAM libre parezca justa
up() {
    local which="${1:-chat}" want_chat=0 want_fim=0 cmd
    case "$which" in
        chat) want_chat=1 ;;
        fim)  want_fim=1 ;;
        all)  want_chat=1; want_fim=1 ;;
        *)    echo "Uso: $(basename "$0") up [chat|fim|all]" >&2; return 2 ;;
    esac

    for cmd in llama-server curl; do
        command -v "$cmd" > /dev/null 2>&1 || { echo "Falta '$cmd' (paquete llama-cpp / curl)." >&2; return 1; }
    done

    local need=$((RAM_MARGIN_GIB * 1073741824)) avail
    if [ "$want_chat" -eq 1 ] && ! is_running "$BIG_PID_FILE"; then
        [ -f "${CHAT_MODEL:-}" ] || {
            echo "No existe CHAT_MODEL: '${CHAT_MODEL:-sin definir}'. Edita $AI_ENV o descárgalo con el menú (SUPER+ALT+SHIFT+L)." >&2
            return 1
        }
        need=$((need + $(ref_bytes "$CHAT_MODEL")))
    fi
    if [ "$want_fim" -eq 1 ] && ! is_running "$SMALL_PID_FILE"; then
        [ -f "${FIM_MODEL:-}" ] || {
            echo "No existe FIM_MODEL: '${FIM_MODEL:-sin definir}'. Edita $AI_ENV o descárgalo con el menú (SUPER+ALT+SHIFT+L)." >&2
            return 1
        }
        need=$((need + $(ref_bytes "$FIM_MODEL")))
    fi

    avail="$(mem_available_bytes)"
    if [ "$need" -gt "$avail" ] && [ "${AI_FORCE:-0}" != "1" ]; then
        echo "Hacen falta ~$(gib "$need") GB y hay $(gib "$avail") GB libres. Cierra apps o baja CHAT_CTX en $AI_ENV (o AI_FORCE=1 para forzar)." >&2
        return 1
    fi

    local -a ports=() pid_files=() names=() logs=()
    if [ "$want_chat" -eq 1 ]; then
        if is_running "$BIG_PID_FILE"; then
            echo "chat ya está activo en :$BIG_PORT"
        else
            start_server "$BIG_PID_FILE" "$CHAT_MODEL" "$BIG_PORT" "$CHAT_CTX" "$BIG_THREADS" "$LOG_DIR/big.log" --jinja
            ports+=("$BIG_PORT"); pid_files+=("$BIG_PID_FILE"); logs+=("$LOG_DIR/big.log")
            names+=("chat :$BIG_PORT (ctx $CHAT_CTX, $BIG_THREADS hilos)")
        fi
    fi
    if [ "$want_fim" -eq 1 ]; then
        if is_running "$SMALL_PID_FILE"; then
            echo "autocompletado ya está activo en :$SMALL_PORT"
        else
            start_server "$SMALL_PID_FILE" "$FIM_MODEL" "$SMALL_PORT" "$SMALL_CTX" "$SMALL_THREADS" "$LOG_DIR/small.log"
            ports+=("$SMALL_PORT"); pid_files+=("$SMALL_PID_FILE"); logs+=("$LOG_DIR/small.log")
            names+=("autocompletado :$SMALL_PORT (ctx $SMALL_CTX, $SMALL_THREADS hilos)")
        fi
    fi
    [ "${#ports[@]}" -eq 0 ] && return 0

    echo "Cargando modelos en memoria (el de 30B tarda un poco)..."
    local i rc failed=0
    for i in "${!ports[@]}"; do
        wait_ready "${ports[$i]}" "${pid_files[$i]}"
        rc=$?
        case $rc in
            0) echo "listo: ${names[$i]}" ;;
            3) rm -f "${pid_files[$i]}"
               echo "se cerró: ${names[$i]}. Últimas líneas del log:" >&2
               tail -n 4 "${logs[$i]}" >&2 2> /dev/null || true
               failed=1 ;;
            *) echo "sin respuesta: ${names[$i]} (mira ${logs[$i]})" >&2; failed=1 ;;
        esac
    done
    return "$failed"
}

# Mismo atajo: si hay menús abiertos los cancela; si hay servidores los apaga; si no, inicia.
toggle() {
    if [ -f "$DL_FILE" ] && kill -0 "$(cat "$DL_FILE" 2> /dev/null)" 2> /dev/null; then
        kill "$(cat "$DL_FILE")" 2> /dev/null || true
        notify "Descarga cancelada" "Lo ya descargado se conserva; continuará donde quedó."
        return 0
    fi

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
    doctor) doctor ;;
    up)     up "${2:-chat}" ;;
    *)
        echo "Uso: $(basename "$0") {toggle|start|stop|status|doctor|up [chat|fim|all]}" >&2
        exit 1
        ;;
esac

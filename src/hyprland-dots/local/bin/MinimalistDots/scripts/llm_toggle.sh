#!/usr/bin/env bash
# Alterna (enciende/apaga) los servidores llama.cpp: chat/edit (8080) y autocomplete (8081).

set -u

# ---------- Configuración ----------
BIG_MODEL="unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:Q4_K_M"
BIG_PORT=8080
BIG_CTX=16384
BIG_THREADS=6

SMALL_MODEL="Qwen/Qwen2.5-Coder-1.5B-GGUF:Q8_0"
SMALL_PORT=8081
SMALL_CTX=4096
SMALL_THREADS=2

READY_TIMEOUT=300   # segundos máximos esperando que los modelos carguen
# -----------------------------------

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/llm-servers"
LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/llm-servers"
BIG_PID_FILE="$STATE_DIR/big.pid"
SMALL_PID_FILE="$STATE_DIR/small.pid"

mkdir -p "$STATE_DIR" "$LOG_DIR"

notify() {
    notify-send -a "LLM local" -t 4000 "$1" "${2:-}"
}

is_running() {
    local pid_file="$1"
    [[ -f "$pid_file" ]] && kill -0 "$(cat "$pid_file")" 2>/dev/null
}

stop_server() {
    local pid_file="$1"
    [[ -f "$pid_file" ]] || return 0
    local pid
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

start_server() {
    local pid_file="$1" model="$2" port="$3" ctx="$4" threads="$5" log="$6"
    shift 6
    setsid llama-server -hf "$model" --port "$port" -c "$ctx" -t "$threads" "$@" \
        >"$log" 2>&1 < /dev/null &
    echo $! >"$pid_file"
}

wait_ready() {
    local port="$1" pid_file="$2" elapsed=0
    while (( elapsed < READY_TIMEOUT )); do
        # Si alguien apagó todo mientras cargaba, salimos sin avisar.
        is_running "$pid_file" || return 2
        if curl -sf "http://127.0.0.1:${port}/health" >/dev/null 2>&1; then
            return 0
        fi
        sleep 2
        elapsed=$(( elapsed + 2 ))
    done
    return 1
}

# ---------- Toggle ----------
if is_running "$BIG_PID_FILE" || is_running "$SMALL_PID_FILE"; then
    stop_server "$BIG_PID_FILE"
    stop_server "$SMALL_PID_FILE"
    notify "LLM local apagado" "Servidores detenidos y RAM liberada."
    exit 0
fi

if ! command -v llama-server >/dev/null 2>&1; then
    notify "LLM local: error" "No se encontró llama-server en el PATH."
    exit 1
fi

notify "LLM local iniciando..." "Cargando modelos (la primera vez descarga)."

start_server "$BIG_PID_FILE" "$BIG_MODEL" "$BIG_PORT" "$BIG_CTX" "$BIG_THREADS" \
    "$LOG_DIR/big.log" --jinja
start_server "$SMALL_PID_FILE" "$SMALL_MODEL" "$SMALL_PORT" "$SMALL_CTX" "$SMALL_THREADS" \
    "$LOG_DIR/small.log"

wait_ready "$SMALL_PORT" "$SMALL_PID_FILE"; small_rc=$?
wait_ready "$BIG_PORT" "$BIG_PID_FILE"; big_rc=$?

if (( small_rc == 2 || big_rc == 2 )); then
    exit 0   # se apagó manualmente durante la carga
elif (( small_rc == 0 && big_rc == 0 )); then
    notify "LLM local listo" "Chat :${BIG_PORT} | Autocomplete :${SMALL_PORT}"
else
    notify "LLM local: sin respuesta" "Revisa los logs en ${LOG_DIR}"
fi

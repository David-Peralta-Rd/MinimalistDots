#!/usr/bin/env bash
# ==============================================================================
# Pomodoro minimalista (todo Quickshell)
#   - El widget y el temporizador viven en quickshell/pomodoro.qml
#   - Las preguntas (concentración, descanso, sesiones) las hace md_menu
#
# Uso:
#   pomodoro.sh toggle     Atajo: si está activo lo apaga; si no, pregunta e inicia
#   pomodoro.sh start      Pregunta los tiempos e inicia
#   pomodoro.sh stop       Apaga todo
#   pomodoro.sh pause      Pausa / reanuda
#   pomodoro.sh restart    Reinicia la fase actual (concentración o descanso)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
MENU="$SCRIPT_DIR/md_menu"
QML="$HOME/.local/bin/MinimalistDots/quickshell/pomodoro.qml"
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/pomodoro-$UID"
PROMPT_FILE="$STATE_DIR/prompt.pid"     # proceso que está mostrando las preguntas

mkdir -p "$STATE_DIR"

notify() { notify-send -a "Pomodoro" "$1" "${2:-}" 2> /dev/null || true; }

is_running() { pgrep -f "qs .*$QML" > /dev/null 2>&1; }

ipc() { qs -p "$QML" ipc call pomodoro "$1" > /dev/null 2>&1 || true; }

# ask <titulo> <opcion1> <opcion2> ...
# Imprime el número elegido o escrito. Falla si se cancela o no es válido.
ask() {
    local title="$1" answer
    shift
    answer="$(printf '%s\n' "$@" | "$MENU" pomodoro --prompt "$title" || true)"

    if [[ "$answer" =~ ^[[:space:]]*([0-9]+) ]]; then
        local n=$((10#${BASH_REMATCH[1]}))
        if [ "$n" -ge 1 ] && [ "$n" -le 999 ]; then
            echo "$n"
            return 0
        fi
    fi
    return 1
}

start() {
    if is_running; then
        notify "Pomodoro" "Ya está activo."
        return 0
    fi

    echo $$ > "$PROMPT_FILE"
    trap 'rm -f "$PROMPT_FILE"' EXIT

    local focus rest sessions
    focus="$(ask "Concentración (min)" "25 min" "15 min" "20 min" "30 min" "45 min" "50 min" "60 min" "90 min")" || return 0
    rest="$(ask "Descanso (min)" "5 min" "3 min" "10 min" "15 min" "20 min" "30 min")" || return 0
    sessions="$(ask "Sesiones" "4 sesiones" "1 sesión" "2 sesiones" "3 sesiones" "5 sesiones" "6 sesiones" "8 sesiones")" || return 0

    rm -f "$PROMPT_FILE"
    MD_POMO_FOCUS="$focus" MD_POMO_BREAK="$rest" MD_POMO_SESSIONS="$sessions" \
        setsid -f qs -p "$QML" > /dev/null 2>&1
}

stop() {
    if is_running; then
        ipc stop
        sleep 0.2
        is_running && pkill -f "qs .*$QML" 2> /dev/null || true
    fi
}

# Mismo atajo: si hay preguntas abiertas las cancela; si está activo lo apaga; si no, lo inicia
toggle() {
    if [ -f "$PROMPT_FILE" ] && kill -0 "$(cat "$PROMPT_FILE")" 2> /dev/null; then
        kill "$(cat "$PROMPT_FILE")" 2> /dev/null || true
        "$MENU" --close
        rm -f "$PROMPT_FILE"
        return 0
    fi

    if is_running; then
        stop
        notify "Pomodoro detenido"
    else
        start
    fi
}

case "${1:-toggle}" in
    toggle)   toggle ;;
    start)    start ;;
    stop)     stop ;;
    pause)    is_running && ipc pause || true ;;
    restart)  is_running && ipc restart || true ;;
    *)
        echo "Uso: $(basename "$0") {toggle|start|stop|pause|restart}" >&2
        exit 1
        ;;
esac

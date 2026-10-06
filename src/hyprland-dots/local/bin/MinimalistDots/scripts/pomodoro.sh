#!/usr/bin/env bash
# ==============================================================================
# Pomodoro minimalista
#   - El reloj circular es un widget de eww  (config/eww/eww.yuck -> "pomodoro")
#   - Las preguntas (concentración, descanso, sesiones) las hace Wofi
#
# Uso:
#   pomodoro.sh toggle     Atajo de teclado: si está activo lo apaga; si no, pregunta e inicia
#   pomodoro.sh start      Pregunta los tiempos e inicia
#   pomodoro.sh stop       Apaga todo
#   pomodoro.sh pause      Pausa / reanuda
#   pomodoro.sh restart    Reinicia la fase actual (concentración o descanso)
# ==============================================================================
set -euo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
WOFI_DIR="$HOME/.local/bin/MinimalistDots/wofi"
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/pomodoro-$UID"
PID_FILE="$STATE_DIR/daemon.pid"        # proceso temporizador (en segundo plano)
PROMPT_FILE="$STATE_DIR/prompt.pid"     # proceso que está mostrando las preguntas
WINDOW="pomodoro"                       # nombre del defwindow en eww.yuck

# Segundos que dura un "minuto". Solo se cambia para probar el script rápido.
UNIT="${POMODORO_UNIT:-60}"

mkdir -p "$STATE_DIR"

notify() { notify-send -a "Pomodoro" "$1" "${2:-}" 2> /dev/null || true; }

is_running() {
    [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2> /dev/null
}


# ==============================================================================
# PREGUNTAS (Wofi)
# ==============================================================================
# ask <titulo> <opcion1> <opcion2> ...
# Imprime el número elegido o escrito. Falla si se cancela o no es válido.
ask() {
    local title="$1" answer
    shift
    answer="$(printf '%s\n' "$@" | wofi --dmenu \
        -c "$WOFI_DIR/configs/config-pomodoro" \
        -s "$WOFI_DIR/themes/style-pomodoro.css" \
        --prompt "$title" || true)"

    if [[ "$answer" =~ ^[[:space:]]*([0-9]+) ]]; then
        local n=$((10#${BASH_REMATCH[1]}))
        if [ "$n" -ge 1 ] && [ "$n" -le 999 ]; then
            echo "$n"
            return 0
        fi
    fi
    return 1
}


# ==============================================================================
# TEMPORIZADOR (proceso en segundo plano)
# ==============================================================================
# Estado (globales, para que los manejadores de señales lo vean)
FOCUS_LEN=0; BREAK_LEN=0; TOTAL=1
SESSION=1; PHASE="focus"; PAUSED=0
REMAINING=0; END_TS=0; NOW=0; LEN=0

set_now()   { printf -v NOW '%(%s)T' -1; }
phase_len() { if [ "$PHASE" = "focus" ]; then LEN="$FOCUS_LEN"; else LEN="$BREAK_LEN"; fi; }

# Envía el estado al widget de eww
render() {
    local pct clock cls icon label
    phase_len
    pct=$((REMAINING * 100 / LEN))
    printf -v clock '%02d:%02d' $((REMAINING / 60)) $((REMAINING % 60))

    if [ "$PAUSED" -eq 1 ]; then
        cls="paused"; icon="▶"; label="Pausa"
    elif [ "$PHASE" = "focus" ]; then
        cls="focus"; icon="❚❚"; label="Concentración"
    else
        cls="break"; icon="❚❚"; label="Descanso"
    fi

    eww update pomo_time="$clock" pomo_pct="$pct" pomo_session="$SESSION/$TOTAL" \
        pomo_label="$label" pomo_class="$cls" pomo_icon="$icon" > /dev/null 2>&1 || true
}

# Pasa a la siguiente fase. Devuelve 1 cuando ya terminaron todas las sesiones.
advance() {
    if [ "$PHASE" = "focus" ]; then
        if [ "$SESSION" -ge "$TOTAL" ]; then
            notify "Pomodoro completado 🎉" "Terminaste las $TOTAL sesiones."
            return 1
        fi
        PHASE="break"
        notify "Descanso" "Sesión $SESSION de $TOTAL terminada."
    else
        SESSION=$((SESSION + 1))
        PHASE="focus"
        notify "Sesión $SESSION de $TOTAL" "A concentrarse."
    fi
    set_now
    phase_len
    REMAINING="$LEN"
    END_TS=$((NOW + REMAINING))
}

on_pause() {
    set_now
    if [ "$PAUSED" -eq 0 ]; then
        PAUSED=1
        REMAINING=$((END_TS - NOW))
    else
        PAUSED=0
        END_TS=$((NOW + REMAINING))
    fi
    render
}

on_restart() {
    set_now
    PAUSED=0
    phase_len
    REMAINING="$LEN"
    END_TS=$((NOW + REMAINING))
    render
}

cleanup() {
    eww close "$WINDOW" > /dev/null 2>&1 || true
    rm -f "$PID_FILE"
}

open_window() {
    eww ping > /dev/null 2>&1 || { eww daemon > /dev/null 2>&1 || true; sleep 1; }
    if ! eww open "$WINDOW" > /dev/null 2>&1; then
        # El daemon puede tener la configuración vieja (sin la ventana "pomodoro")
        eww reload > /dev/null 2>&1 || true
        sleep 0.5
        if ! eww open "$WINDOW" > /dev/null 2>&1; then
            notify "Pomodoro" "No se pudo abrir el widget de eww."
            exit 1
        fi
    fi
}

daemon() {
    FOCUS_LEN=$(($1 * UNIT))
    BREAK_LEN=$(($2 * UNIT))
    TOTAL="$3"

    echo $$ > "$PID_FILE"
    trap cleanup EXIT
    trap 'exit 0' TERM INT
    trap on_pause USR1
    trap on_restart USR2

    open_window

    SESSION=1; PHASE="focus"; PAUSED=0
    set_now
    REMAINING="$FOCUS_LEN"
    END_TS=$((NOW + REMAINING))
    render
    notify "Pomodoro iniciado" "Sesión 1 de $TOTAL"

    local sleep_pid
    while true; do
        # sleep + wait: las señales (pausa/reinicio) se atienden al instante
        sleep 1 &
        sleep_pid=$!
        if ! wait "$sleep_pid"; then
            kill "$sleep_pid" 2> /dev/null || true
            continue
        fi

        if [ "$PAUSED" -eq 1 ]; then
            continue
        fi

        set_now
        REMAINING=$((END_TS - NOW))
        if [ "$REMAINING" -le 0 ]; then
            advance || break
        fi
        render
    done
}


# ==============================================================================
# COMANDOS
# ==============================================================================
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
    setsid -f bash "$SELF" _daemon "$focus" "$rest" "$sessions" > /dev/null 2>&1
}

stop() {
    if is_running; then
        kill "$(cat "$PID_FILE")" 2> /dev/null || true
    fi
    eww close "$WINDOW" > /dev/null 2>&1 || true
    rm -f "$PID_FILE"
}

# Mismo atajo: si hay preguntas abiertas las cancela; si está activo lo apaga; si no, lo inicia
toggle() {
    if [ -f "$PROMPT_FILE" ] && kill -0 "$(cat "$PROMPT_FILE")" 2> /dev/null; then
        kill "$(cat "$PROMPT_FILE")" 2> /dev/null || true
        pkill -x wofi 2> /dev/null || true
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

send_signal() {
    if is_running; then
        kill -"$1" "$(cat "$PID_FILE")" 2> /dev/null || true
    fi
}

case "${1:-toggle}" in
    toggle)   toggle ;;
    start)    start ;;
    stop)     stop ;;
    pause)    send_signal USR1 ;;
    restart)  send_signal USR2 ;;
    _daemon)  shift; daemon "$@" ;;   # uso interno
    *)
        echo "Uso: $(basename "$0") {toggle|start|stop|pause|restart}" >&2
        exit 1
        ;;
esac

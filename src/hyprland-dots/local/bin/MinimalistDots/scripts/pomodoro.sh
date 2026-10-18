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
#   pomodoro.sh sound      Reproduce el sonido de aviso (lo usa el widget; sirve para probarlo)
#   pomodoro.sh test       Prueba rápida: 6 s de concentración y 20 s de descanso (2 sesiones)
#
# Errores del widget (QML): ~/.cache/MinimalistDots/pomodoro/qs.log
#
# Al terminar la concentración el widget se agranda y se centra en pantalla para que
# no se te pase el descanso, y suena el aviso (también al volver a concentración).
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
MENU="$SCRIPT_DIR/md_menu"
QML="$HOME/.local/bin/MinimalistDots/quickshell/pomodoro.qml"
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/pomodoro-$UID"
PROMPT_FILE="$STATE_DIR/prompt.pid"     # proceso que está mostrando las preguntas
SOUND_PID_FILE="$STATE_DIR/sound.pid"   # reproductor activo (para cortarlo al detener)

# ---------- SONIDO DE AVISO (se cambia solo aquí, no hay menú) ----------------
# SOUND_URL    enlace directo a un audio (mp3, ogg, wav...). Se descarga UNA vez con curl a la
#              caché; si no es mp3 se convierte a mp3 con ffmpeg. Si cambias la URL se vuelve
#              a descargar solo.
# SOUND_FILE   ruta a un audio tuyo; si existe, tiene prioridad sobre la URL.
# Dejar ambos vacíos = sin sonido.
SOUND_URL="https://download1475.mediafire.com/p2e1615adi1gruf1I1GxzykKuwgz65H5AwrGxOBuLVJLkOmE3uM8RoK4mAA1mbkK-ItmQ5MghDXEFmpDxfNQ57wbB_RBUmC0x-6cSUl0D8F1w3iz6tWYKNcW9WEAUB7jugoaUIF42hhCQFDN3KUkjqvyWKKXXn5VwmM4iVIwk9-e1w/6chtw5jvqdqjss6/sound_garage_funky_loop.mp3"
SOUND_FILE=""
SOUND_VOLUME=70            # 0-100
SOUND_MAX_SECONDS=10       # el proceso de sonido se cierra solo al acabar o a estos segundos
SOUND_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/MinimalistDots/pomodoro"

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

# ==============================================================================
# SONIDO
# ==============================================================================
sound_log() { printf '%s %s\n' "$(date '+%F %T')" "$*" >> "$SOUND_CACHE/sound.log" 2> /dev/null || true; }

# ¿Es mp3? Por cabecera: "ID3" o sincronía MPEG (FF Ex / FF Fx)
is_mp3() {
    local head
    head="$(head -c 3 "$1" 2> /dev/null | od -An -tx1 | tr -d ' \n')"
    [[ "$head" == 494433* ]] || [[ "$head" =~ ^ff[ef] ]]
}

# Imprime la ruta del audio listo para reproducir (lo descarga/convierte si hace falta).
ensure_sound() {
    mkdir -p "$SOUND_CACHE"

    if [ -n "$SOUND_FILE" ] && [ -f "$SOUND_FILE" ]; then
        echo "$SOUND_FILE"
        return 0
    fi
    [ -n "$SOUND_URL" ] || return 1

    local key out raw tmp ext
    key="$(printf '%s' "$SOUND_URL" | md5sum | cut -c1-8)"
    out="$SOUND_CACHE/alarm-$key.mp3"
    tmp="$SOUND_CACHE/alarm-$key.download"

    if [ -s "$out" ]; then echo "$out"; return 0; fi
    for raw in "$SOUND_CACHE/alarm-$key".raw.*; do
        if [ -s "$raw" ]; then echo "$raw"; return 0; fi
    done

    if ! curl -fL --retry 3 --connect-timeout 15 --max-time 90 -sS \
        -A "MinimalistDots-pomodoro/1.0" -o "$tmp" "$SOUND_URL" 2>> "$SOUND_CACHE/sound.log"; then
        sound_log "no se pudo descargar $SOUND_URL"
        rm -f "$tmp"
        return 1
    fi

    if is_mp3 "$tmp"; then
        mv -f "$tmp" "$out"
    elif command -v ffmpeg > /dev/null 2>&1; then
        # a mp3, recortado: no hace falta guardar más de lo que se va a reproducir
        if ffmpeg -nostdin -loglevel error -y -i "$tmp" -vn -t "$((SOUND_MAX_SECONDS + 2))" \
            -codec:a libmp3lame -q:a 4 "$out" 2>> "$SOUND_CACHE/sound.log"; then
            rm -f "$tmp"
        else
            sound_log "ffmpeg no pudo convertir $SOUND_URL (¿es un audio?)"
            rm -f "$tmp" "$out"
            return 1
        fi
    else
        # sin ffmpeg: se guarda tal cual y lo reproduce mpv/ffplay/vlc si existen
        ext="${SOUND_URL##*.}"; ext="${ext%%\?*}"
        [[ "$ext" =~ ^[A-Za-z0-9]{2,4}$ ]] || ext="audio"
        out="$SOUND_CACHE/alarm-$key.raw.$ext"
        sound_log "el audio no es mp3 y falta ffmpeg para convertirlo; se usa tal cual"
        mv -f "$tmp" "$out"
    fi
    echo "$out"
}

# Rellena el array PLAYER con el comando según lo que haya instalado
PLAYER=()
build_player() {
    local file="$1" vol="$SOUND_VOLUME"
    PLAYER=()
    if [[ "$file" == *.mp3 ]] && command -v mpg123 > /dev/null 2>&1; then
        PLAYER=(mpg123 -q -f "$((32768 * vol / 100))" "$file")      # 32768 = 100 %
    elif command -v mpv > /dev/null 2>&1; then
        PLAYER=(mpv --no-video --really-quiet --no-terminal --volume="$vol" "$file")
    elif command -v ffplay > /dev/null 2>&1; then
        PLAYER=(ffplay -nodisp -autoexit -loglevel quiet -volume "$vol" "$file")
    elif command -v cvlc > /dev/null 2>&1; then
        PLAYER=(cvlc --play-and-exit --quiet "$file")
    else
        return 1
    fi
}

stop_sound() {
    local pid
    pid="$(cat "$SOUND_PID_FILE" 2> /dev/null || true)"
    if [ -n "$pid" ]; then kill "$pid" 2> /dev/null || true; fi
    rm -f "$SOUND_PID_FILE"
}

# Reproduce el aviso y termina cuando acaba el audio (o a los SOUND_MAX_SECONDS).
play_sound() {
    local file pid
    file="$(ensure_sound)" || return 0
    build_player "$file" || { sound_log "no hay reproductor: instala mpg123"; return 0; }

    stop_sound                                  # nunca dos avisos a la vez
    timeout "$SOUND_MAX_SECONDS" "${PLAYER[@]}" > /dev/null 2>&1 &
    pid=$!
    echo "$pid" > "$SOUND_PID_FILE"
    wait "$pid" 2> /dev/null || true
    if [ "$(cat "$SOUND_PID_FILE" 2> /dev/null || true)" = "$pid" ]; then rm -f "$SOUND_PID_FILE"; fi
}


# launch <concentración> <descanso> <sesiones> [segundos por "minuto"]
launch() {
    mkdir -p "$SOUND_CACHE"
    : > "$SOUND_CACHE/qs.log"                   # aquí caen los errores de QML (antes se perdían)
    MD_POMO_FOCUS="$1" MD_POMO_BREAK="$2" MD_POMO_SESSIONS="$3" MD_POMO_UNIT="${4:-60}" \
        MD_POMO_SCRIPT="$SCRIPT_DIR/pomodoro.sh" \
        setsid -f qs -p "$QML" >> "$SOUND_CACHE/qs.log" 2>&1
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
    (ensure_sound > /dev/null 2>&1 &)           # deja el sonido en caché antes del primer aviso
    launch "$focus" "$rest" "$sessions"
}

stop() {
    stop_sound
    if is_running; then
        ipc stop
        sleep 0.2
        is_running && pkill -f "qs .*$QML" 2> /dev/null || true
    fi
}

# Prueba rápida para ver la tarjeta de descanso sin esperar 25 minutos
run_test() {
    stop
    notify "Pomodoro (prueba)" "6 s de concentración y luego 20 s de descanso."
    launch 6 20 2 1
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
    sound)    play_sound ;;
    test)     run_test ;;
    *)
        echo "Uso: $(basename "$0") {toggle|start|stop|pause|restart|sound|test}" >&2
        exit 1
        ;;
esac

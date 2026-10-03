#!/usr/bin/env bash
XDG_VIDEOS_DIR="${XDG_VIDEOS_DIR:-$HOME/multimedia/videos}"
save_dir="${XDG_VIDEOS_DIR}/recordings"
save_file=$(date +'%y%m%d_%Hh%Mm%Ss_recording.mp4')
save_path="$save_dir/$save_file"

RECORD_NOTIFY=${RECORD_NOTIFY:-true}
RECORD_AUDIO=${RECORD_AUDIO:-false}

# Comprobamos la nueva herramienta
if command -v gpu-screen-recorder &>/dev/null; then
    REC_TOOL="gpu-screen-recorder"
else
    REC_TOOL=""
fi

USAGE() {
    cat <<EOHELP
Uso: $(basename "$0") [opción] [flags]

Opciones:
  s, snip        Seleccionar un área o ventana para grabar
  m, monitor     Grabar el monitor o pantalla completa
  t, toggle      Detener cualquier grabación en curso

Flags:
  -a, --audio    Incluir grabación de audio (sistema por defecto)
  --no-notify    Desactivar notificaciones
  -h, --help     Mostrar este mensaje de ayuda
EOHELP
}

send_notification() {
    local title="$1"
    local message="$2"
    local icon="$3"

    if [[ "${RECORD_NOTIFY}" == true ]]; then
        if [[ -n "$icon" ]]; then
            notify-send -a "Screen Recorder" -i "$icon" "$title" "$message"
        else
            notify-send -a "Screen Recorder" "$title" "$message"
        fi
    fi
}

stop_active_recording() {
    local pids
    # Buscamos cualquier proceso que contenga "gpu-screen-recorder" en el comando
    pids=$(pgrep -f "gpu-screen-recorder")

    if [[ -n "$pids" ]]; then
        # Enviamos la señal SIGINT a todos los PIDs encontrados para guardar bien los videos
        kill -INT $pids
        send_notification "Grabación Detenida" "Procesando y guardando el video..." "media-playback-stop"
        exit 0
    fi
}


RECORD_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a | --audio)
            RECORD_AUDIO=true
            shift
            ;;
        --no-notify)
            RECORD_NOTIFY=false
            shift
            ;;
        -h | --help)
            USAGE
            exit 0
            ;;
        *)
            RECORD_ARGS+=("$1")
            shift
            ;;
    esac
done

set -- "${RECORD_ARGS[@]}"

if [[ -z "$REC_TOOL" ]]; then
    send_notification "Error de Grabación" "No se encontró gpu-screen-recorder instalado."
    exit 1
fi

if [[ "${1:-}" == "t" || "${1:-}" == "toggle" ]]; then
    stop_active_recording
    send_notification "Screen Recorder" "No había ninguna grabación en curso."
    exit 0
fi

stop_active_recording
mkdir -p "$save_dir"

start_recording() {
    local mode=$1
    local geometry=""
    local audio_flags=()
    local video_flags=()

    # Configuración de Audio
    if [[ "$RECORD_AUDIO" == true ]]; then
        # "default" captura el audio interno del sistema. Cambiar a "focused" si solo quieres el de la ventana activa.
        audio_flags+=("-a" "default") 
    fi

    # Configuración de Video (Balance de peso óptimo y 60 FPS fijos)
    # Usamos formato mp4 y calidad 'high' (puedes cambiar a 'medium' si quieres archivos aún más pequeños)
    video_flags+=("-c" "mp4" "-q" "high" "-k" "hevc" "-f" "60")


    if [[ "$mode" == "area" ]]; then
        # Formato corregido para gpu-screen-recorder en Wayland (ANCHO x ALTO + X + Y)
        geometry=$(slurp -f "%wx%h+%x+%y")
        if [[ -z "$geometry" ]]; then
            send_notification "Grabación Cancelada" "No se seleccionó ninguna área."
            exit 0
        fi
        video_flags+=("-w" "$geometry")
    else
        # "screen" le dice a la herramienta que grabe todo el monitor
        video_flags+=("-w" "screen")
    fi

    send_notification "Grabación Iniciada" "Presiona el atajo de nuevo para detener." "media-record"

    # Ejecución de GPU Screen Recorder
    gpu-screen-recorder "${video_flags[@]}" "${audio_flags[@]}" -o "$save_path"

    if [[ -f "$save_path" ]]; then
        send_notification "Grabación Guardada" "Guardada en: $save_path" "video-x-generic"
    fi
}

case ${1:-} in
    s | snip)    start_recording "area" ;;
    m | monitor) start_recording "screen" ;;
    *) USAGE ;;
esac

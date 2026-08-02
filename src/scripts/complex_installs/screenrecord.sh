#!/usr/bin/env bash

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}=== Instalador del Grabador de Pantalla para Hyprland ===${NC}\n"

# 1. Instalar dependencias
install_dependencies() {
    echo -e "${YELLOW}[1/3] Verificando e instalando dependencias del sistema...${NC}"

    if command -v pacman &>/dev/null; then
        echo -e "${CYAN}Detectado Arch Linux / Pacman...${NC}"
        sudo pacman -S --needed --noconfirm slurp wf-recorder libnotify ffmpeg
    elif command -v dnf &>/dev/null; then
        echo -e "${CYAN}Detectado Fedora / DNF...${NC}"
        sudo dnf install -y slurp wf-recorder libnotify ffmpeg
    elif command -v apt &>/dev/null; then
        echo -e "${CYAN}Detectado Debian / Ubuntu / APT...${NC}"
        sudo apt update
        sudo apt install -y slurp wf-recorder libnotify-bin ffmpeg
    else
        echo -e "${RED}Gestor de paquetes no detectado. Asegúrate de tener instalados: slurp, wl-screenrec (o wf-recorder) y libnotify.${NC}"
    fi
}

install_dependencies

# 2. Definir destino
INSTALL_DIR="$HOME/.local/bin/minimaldots"
TARGET_FILE="$INSTALL_DIR/screenrecord.sh"

echo -e "\n${YELLOW}[2/3] Instalando el script en: ${TARGET_FILE}${NC}"
mkdir -p "$INSTALL_DIR"

# 3. Copiar el contenido al ejecutable (con la atribución correspondiente)
cat << 'EOF' > "$TARGET_FILE"
#!/usr/bin/env bash
# ==============================================================================
# Script de Grabación de Pantalla para Hyprland
#
# Inspirado en la lógica y experiencia de usuario del ecosistema HyDE / Wayland.
# Adaptado para funcionar de manera independiente con wl-screenrec / wf-recorder.
#
# Créditos y reconocimientos:
#   - Comunidad de Hyprland & Proyecto HyDE (https://github.com/HyDE-Project)
# ==============================================================================

# ==============================================================================
# Screen Recording Script for Hyprland
#
# Inspired by the logic and user experience of the HyDE / Wayland ecosystem.
# Adapted to run independently using wl-screenrec / wf-recorder.
#
# Credits and acknowledgments:
#   - Hyprland Community & HyDE Project (https://github.com/HyDE-Project)
# ==============================================================================

XDG_VIDEOS_DIR="${XDG_VIDEOS_DIR:-$HOME/multimedia/videos}"
save_dir="${XDG_VIDEOS_DIR}/recordings"
save_file=$(date +'%y%m%d_%Hh%Mm%Ss_recording.mp4')
save_path="$save_dir/$save_file"

RECORD_NOTIFY=${RECORD_NOTIFY:-true}
RECORD_AUDIO=${RECORD_AUDIO:-false}

if command -v wl-screenrec &>/dev/null; then
    REC_TOOL="wl-screenrec"
elif command -v wf-recorder &>/dev/null; then
    REC_TOOL="wf-recorder"
else
    REC_TOOL=""
fi

USAGE() {
    cat <<EOHELP
Uso: $(basename "$0") [opción] [flags]

Opciones:
  s, snip         Seleccionar un área o ventana para grabar
  m, monitor      Grabar el monitor o pantalla completa
  t, toggle       Detener cualquier grabación en curso

Flags:
  -a, --audio     Incluir grabación de audio (sistema / mic)
  --no-notify     Desactivar notificaciones
  -h, --help      Mostrar este mensaje de ayuda
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
    pids=$(pgrep -x "wl-screenrec" || pgrep -x "wf-recorder")

    if [[ -n "$pids" ]]; then
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
    send_notification "Error de Grabación" "No se encontró wl-screenrec ni wf-recorder instalados."
    exit 1
fi

if [[ "$1" == "t" || "$1" == "toggle" ]]; then
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

    if [[ "$mode" == "area" ]]; then
        geometry=$(slurp)
        if [[ -z "$geometry" ]]; then
            send_notification "Grabación Cancelada" "No se seleccionó ninguna área."
            exit 0
        fi
    fi

    if [[ "$RECORD_AUDIO" == true ]]; then
        audio_flags+=("--audio")
    fi

    send_notification "Grabación Iniciada" "Presiona el atajo de nuevo para detener." "media-record"

    if [[ "$REC_TOOL" == "wl-screenrec" ]]; then
        if [[ -n "$geometry" ]]; then
            wl-screenrec -g "$geometry" -f "$save_path" "${audio_flags[@]}"
        else
            wl-screenrec -f "$save_path" "${audio_flags[@]}"
        fi
    elif [[ "$REC_TOOL" == "wf-recorder" ]]; then
        if [[ -n "$geometry" ]]; then
            wf-recorder -g "$geometry" -f "$save_path" "${audio_flags[@]}"
        else
            wf-recorder -f "$save_path" "${audio_flags[@]}"
        fi
    fi

    if [[ -f "$save_path" ]]; then
        send_notification "Grabación Guardada" "Guardada en: $save_path" "video-x-generic"
    fi
}

case $1 in
    s | snip)    start_recording "area" ;;
    m | monitor) start_recording "screen" ;;
    *) USAGE ;;
esac
EOF

chmod +x "$TARGET_FILE"

echo -e "${GREEN}[3/3] ¡Instalación de Grabador de Pantalla completada!${NC}\n"

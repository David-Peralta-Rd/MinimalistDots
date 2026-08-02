# ==============================================================================
# Script de Captura de Pantalla para Hyprland
#
# Basado e inspirado en el módulo de screenshots de HyDE (Hyprland Desktop Environment).
# Adaptado para funcionar de manera independiente sin dependencias de HyDE.
#
# Créditos y agradecimientos:
#   - Proyecto HyDE: https://github.com/HyDE-Project
# ==============================================================================

# ==============================================================================
# Screenshot Script for Hyprland
#
# Based on and inspired by the screenshot module from HyDE (Hyprland Desktop Environment).
# Adapted to run independently, without dependencies on HyDE.
#
# Credits and acknowledgments:
#   - HyDE Project: https://github.com/HyDE-Project
# ==============================================================================


#!/usr/bin/env bash

set -e

# Colores para salida de terminal
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}=== Instalador de Script de Captura para Hyprland ===${NC}\n"

# 1. Instalar dependencias según el gestor de paquetes
install_dependencies() {
    echo -e "${YELLOW}[1/3] Verificando e instalando dependencias del sistema...${NC}"

    if command -v pacman &>/dev/null; then
        echo -e "${CYAN}Detectado Arch Linux / Pacman...${NC}"
        sudo pacman -S --needed --noconfirm grim slurp wl-clipboard libnotify tesseract tesseract-data-eng tesseract-data-spa zbar swappy
    elif command -v dnf &>/dev/null; then
        echo -e "${CYAN}Detectado Fedora / DNF...${NC}"
        sudo dnf install -y grim slurp wl-clipboard libnotify tesseract tesseract-langpack-spa zbar swappy
    elif command -v apt &>/dev/null; then
        echo -e "${CYAN}Detectado Debian / Ubuntu / APT...${NC}"
        sudo apt update
        sudo apt install -y grim slurp wl-clipboard libnotify-bin tesseract-ocr tesseract-ocr-spa zbar-tools swappy
    else
        echo -e "${RED}Gestor de paquetes no detectado automáticamente. Asegúrate de tener instalados: grim, slurp, wl-clipboard, libnotify, tesseract, zbar y swappy.${NC}"
    fi

    # Verificar o instalar grimblast en Arch/AUR si no existe
    if ! command -v grimblast &>/dev/null; then
        if command -v yay &>/dev/null; then
            yay -S --needed --noconfirm grimblast-git
        elif command -v paru &>/dev/null; then
            paru -S --needed --noconfirm grimblast-git
        else
            echo -e "${YELLOW}Advertencia: 'grimblast' no se encontró. Puedes instalarlo desde AUR (ej. 'yay -S grimblast-git') o usar grim/slurp directamente.${NC}"
        fi
    fi
}

install_dependencies

# 2. Definir rutas de destino
INSTALL_DIR="$HOME/.local/bin/minimaldots"
TARGET_FILE="$INSTALL_DIR/screenshot.sh"

echo -e "\n${YELLOW}[2/3] Instalando el script en: ${TARGET_FILE}${NC}"
mkdir -p "$INSTALL_DIR"

# 3. Crear el archivo del script de captura
cat << 'EOF' > "$TARGET_FILE"
#!/usr/bin/env bash

# ==========================================
# CONFIGURACIÓN PREDETERMINADA
# ==========================================
XDG_PICTURES_DIR="${XDG_PICTURES_DIR:-$HOME/multimedia/pictures}"
save_dir="${XDG_PICTURES_DIR}/screenshots"
save_file=$(date +'%y%m%d_%Hh%Mm%Ss_screenshot.png')
temp_screenshot="${XDG_RUNTIME_DIR:-/tmp}/hypr_screenshot.png"
confDir="${XDG_CONFIG_HOME:-$HOME/.config}"

SCREENSHOT_NOTIFY=${SCREENSHOT_NOTIFY:-true}
SCREENSHOT_ANNOTATION_ENABLED=${SCREENSHOT_ANNOTATION_ENABLED:-true}
OCR_LANG=${SCREENSHOT_OCR_LANG:-"eng"}

# Detectar herramienta de anotación disponible
if command -v swappy &>/dev/null; then
    annotation_tool="swappy"
elif command -v satty &>/dev/null; then
    annotation_tool="satty"
fi

# ==========================================
# AYUDA / USAGE
# ==========================================
USAGE() {
    cat <<EOHELP
Uso: $(basename "$0") [opción] [flags]

Opciones:
  p, printscreen  Capturar todas las pantallas
  s, snip         Seleccionar área o ventana
  sf, snapfreeze  Seleccionar área con pantalla congelada
  m, monitor      Capturar el monitor enfocado
  sc, scan        Extraer texto (OCR) y copiar al portapapeles
  sq, qr          Escanear código QR y copiar resultado

Flags:
  --no-notify     Desactivar la notificación al guardar
  -h, --help      Mostrar este mensaje de ayuda
EOHELP
}

# ==========================================
# MANEJO DE ARGUMENTOS
# ==========================================
SCREENSHOT_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-notify)
            SCREENSHOT_NOTIFY=false
            shift
            ;;
        -h | --help)
            USAGE
            exit 0
            ;;
        *)
            SCREENSHOT_ARGS+=("$1")
            shift
            ;;
    esac
done

set -- "${SCREENSHOT_ARGS[@]}"

# Preparar directorios
mkdir -p "$save_dir"

# Configurar argumentos para la herramienta de edición
annotation_args=("-o" "$save_dir/$save_file" "-f" "$temp_screenshot")

if [[ $annotation_tool == "swappy" ]]; then
    swpy_dir="$confDir/swappy"
    mkdir -p "$swpy_dir"
    printf "[Default]\nsave_dir=%s\nsave_filename_format=%s\n" "$save_dir" "$save_file" > "$swpy_dir/config"
elif [[ $annotation_tool == "satty" ]]; then
    annotation_args+=("--copy-command" "wl-copy")
fi

# ==========================================
# FUNCIONES AUXILIARES
# ==========================================
send_notification() {
    local title="$1"
    local message="$2"
    local icon="$3"

    if [[ "${SCREENSHOT_NOTIFY}" == true ]]; then
        if [[ -n "$icon" ]]; then
            notify-send -a "Screenshot" -i "$icon" "$title" "$message"
        else
            notify-send -a "Screenshot" "$title" "$message"
        fi
    fi
}

run_annotation_tool() {
    if [[ -z "$annotation_tool" ]]; then
        send_notification "Screenshot" "No hay herramienta de edición instalada (swappy/satty)."
        return 1
    fi

    if [[ $annotation_tool == "satty" ]]; then
        GSK_RENDERER="${GSK_RENDERER:-gl}" "$annotation_tool" "${annotation_args[@]}"
    else
        "$annotation_tool" "${annotation_args[@]}"
    fi
}

# ==========================================
# LÓGICA DE CAPTURA DE PANTALLA
# ==========================================
take_screenshot() {
    local mode=$1
    shift
    local extra_args=("$@")
    local target_file="$temp_screenshot"

    if [[ ${SCREENSHOT_ANNOTATION_ENABLED} == false ]]; then
        target_file="$save_dir/$save_file"
    fi

    if grimblast "${extra_args[@]}" copysave "${mode}" "${target_file}"; then
        if [[ ${SCREENSHOT_ANNOTATION_ENABLED} == false ]]; then
            send_notification "Captura guardada" "Guardada en $save_dir/$save_file" "$save_dir/$save_file"
            return 0
        fi

        if ! run_annotation_tool; then
            send_notification "Error" "No se pudo abrir la herramienta de edición"
            return 1
        fi
    else
        send_notification "Error" "Fallo al tomar la captura de pantalla"
        return 1
    fi
}

# ==========================================
# LÓGICA OCR (EXTRAER TEXTO)
# ==========================================
ocr_screenshot() {
    local mode=$1
    shift
    local extra_args=("$@")

    if grimblast "${extra_args[@]}" copysave "$mode" "$temp_screenshot"; then
        send_notification "OCR" "Procesando texto de la imagen..." "document-scan"

        local text
        text=$(tesseract "$temp_screenshot" stdout -l "$OCR_LANG" 2>/dev/null)

        if [[ -n "$text" ]]; then
            echo -n "$text" | wl-copy
            send_notification "OCR Exitoso" "Texto copiado al portapapeles:\n$text"
        else
            send_notification "OCR Error" "No se pudo detectar texto en la imagen"
            return 1
        fi
    else
        send_notification "OCR Error" "Fallo al tomar la captura"
        return 1
    fi
    exit 0
}

# ==========================================
# LÓGICA QR
# ==========================================
qr_screenshot() {
    local mode=$1
    shift
    local extra_args=("$@")

    if grimblast "${extra_args[@]}" copysave "$mode" "$temp_screenshot"; then
        send_notification "Escaner QR" "Procesando código QR..." "document-scan"

        local qr_result
        qr_result=$(zbarimg --raw -q "$temp_screenshot" 2>/dev/null)

        if [[ -n "$qr_result" ]]; then
            echo -n "$qr_result" | wl-copy
            send_notification "QR Detectado" "Contenido copiado al portapapeles:\n$qr_result"
        else
            send_notification "QR Error" "No se encontró ningún código QR"
            return 1
        fi
    else
        send_notification "QR Error" "Fallo al tomar la captura"
        return 1
    fi
    exit 0
}

# ==========================================
# EJECUCIÓN PRINCIPAL
# ==========================================
case $1 in
    p  | printscreen) take_screenshot "screen" ;;
    s  | snip)        take_screenshot "area" ;;
    sf | snapfreeze)  take_screenshot "area" "--freeze" ;;
    m  | monitor)     take_screenshot "output" ;;
    sc | scan)        ocr_screenshot "area" "--freeze" ;;
    sq | qr)          qr_screenshot "area" "--freeze" ;;
    *) USAGE ;;
esac

# Limpieza final
[ -f "$temp_screenshot" ] && rm -f "$temp_screenshot"

if [ -f "$save_dir/$save_file" ] && [[ "${SCREENSHOT_NOTIFY}" == true ]]; then
    send_notification "Captura guardada" "Guardada en $save_dir" "$save_dir/$save_file"
fi
EOF

# Otorgar permisos de ejecución
chmod +x "$TARGET_FILE"

echo -e "${GREEN}[3/3] ¡Instalación completada exitosamente!${NC}\n"

#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Si el subscript se ejecuta solo (sin pasar por setup.sh), carga el idioma guardado
if [ -z "${TXT_WELCOME:-}" ]; then
    # Subimos un nivel con ".." para salir de "scripts/" y entrar a "src/"
    LANG_LOADER="$SRC_DIR/../../lang/load_lang.sh"
    if [ -f "$LANG_LOADER" ]; then
        source "$LANG_LOADER"
    else
        echo "Aviso: No se pudo encontrar el archivo de idioma en $LANG_LOADER"
    fi
fi


INSTALL_DIR="$HOME/.local/bin/minimalist_dots/scripts"
TARGET_FILE="$INSTALL_DIR/screenshot.sh"
mkdir -p "$INSTALL_DIR"

cat << 'EOF' > "$TARGET_FILE"
#!/usr/bin/env bash

XDG_PICTURES_DIR="${XDG_PICTURES_DIR:-$HOME/multimedia/pictures}"
save_dir="${XDG_PICTURES_DIR}/screenshots"
save_file=$(date +'%y%m%d_%Hh%Mm%Ss_screenshot.png')
temp_screenshot="${XDG_RUNTIME_DIR:-/tmp}/hypr_screenshot.png"
confDir="${XDG_CONFIG_HOME:-$HOME/.config}"

SCREENSHOT_NOTIFY=${SCREENSHOT_NOTIFY:-true}
SCREENSHOT_ANNOTATION_ENABLED=${SCREENSHOT_ANNOTATION_ENABLED:-true}
OCR_LANG=${SCREENSHOT_OCR_LANG:-"eng"}

if command -v swappy &>/dev/null; then
    annotation_tool="swappy"
elif command -v satty &>/dev/null; then
    annotation_tool="satty"
fi

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

mkdir -p "$save_dir"
annotation_args=("-o" "$save_dir/$save_file" "-f" "$temp_screenshot")

if [[ ${annotation_tool:-} == "swappy" ]]; then
    swpy_dir="$confDir/swappy"
    mkdir -p "$swpy_dir"
    printf "[Default]\nsave_dir=%s\nsave_filename_format=%s\n" "$save_dir" "$save_file" > "$swpy_dir/config"
elif [[ ${annotation_tool:-} == "satty" ]]; then
    annotation_args+=("--copy-command" "wl-copy")
fi

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
    if [[ -z "${annotation_tool:-}" ]]; then
        send_notification "Screenshot" "No hay herramienta de edición instalada (swappy/satty)."
        return 1
    fi

    if [[ $annotation_tool == "satty" ]]; then
        GSK_RENDERER="${GSK_RENDERER:-gl}" "$annotation_tool" "${annotation_args[@]}"
    else
        "$annotation_tool" "${annotation_args[@]}"
    fi
}

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

case ${1:-} in
    p  | printscreen) take_screenshot "screen" ;;
    s  | snip)        take_screenshot "area" ;;
    sf | snapfreeze)  take_screenshot "area" "--freeze" ;;
    m  | monitor)     take_screenshot "output" ;;
    sc | scan)        ocr_screenshot "area" "--freeze" ;;
    sq | qr)          qr_screenshot "area" "--freeze" ;;
    *) USAGE ;;
esac

[ -f "$temp_screenshot" ] && rm -f "$temp_screenshot"

if [ -f "$save_dir/$save_file" ] && [[ "${SCREENSHOT_NOTIFY}" == true ]]; then
    send_notification "Captura guardada" "Guardada en $save_dir" "$save_dir/$save_file"
fi
EOF

chmod +x "$TARGET_FILE"
echo "==> Script de capturas instalado exitosamente en $TARGET_FILE"

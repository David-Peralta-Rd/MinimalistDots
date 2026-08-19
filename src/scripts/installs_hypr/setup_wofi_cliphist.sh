#!/usr/bin/env bash
set -euo pipefail

# 1. Rutas y carga de idiomas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LANG_FILE="${1:-es.cfg}"
PATH_TRADUCCION="$SCRIPT_DIR/src/lang/$LANG_FILE"

if [[ -f "$PATH_TRADUCCION" ]]; then
    source "$PATH_TRADUCCION"
fi

# 2. Cargar paleta global de colores
COLORS_FILE="$SCRIPT_DIR/src/scripts/colors.sh"
if [[ -f "$COLORS_FILE" ]]; then
    source "$COLORS_FILE"
else
    # Fallback por seguridad
    C_BG="#1e222a"
    C_SURFACE="#282c34"
    C_BORDER_INACTIVE="#4b5263"
    C_TEXT="#abb2bf"
    C_ACCENT_BLUE="#7aa2f7"
fi

echo "=========================================================="
echo "${TXT_WOFI_CLIP_INSTALLING:-Generando estilo de Wofi para Portapapeles...}"
echo "=========================================================="

WOFI_DIR="$HOME/.config/wofi"
WOFI_THEME="$HOME/.config/wofi/themes"
WOFI_CONFIGS="$HOME/.config/wofi/configs"
mkdir -p "$WOFI_DIR"
mkdir -p "$WOFI_THEME"
mkdir -p "$WOFI_CONFIGS"

# Convertidor HEX a CSS RGBA
hex_to_rgba() {
    local hex="${1#\#}"
    local alpha="$2"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo "rgba($r, $g, $b, $alpha)"
}

BG_RGBA=$(hex_to_rgba "$C_BG" 0.90)
SURFACE_70_RGBA=$(hex_to_rgba "$C_SURFACE" 0.70)
SURFACE_90_RGBA=$(hex_to_rgba "$C_SURFACE" 0.90)

# 3. Generar ~/.config/wofi/config-clipboard
cat << EOF > "$WOFI_DIR/configs/config-clipboard"
# Configuración específica para Gestor de Portapapeles (cliphist)
show=dmenu
allow_images=false
width=700
height=420
lines=12
location=center
hide_scroll=true
matching=fuzzy
prompt=📋 Portapapeles
EOF

# 4. Generar ~/.config/wofi/style-clipboard.css
cat << EOF > "$WOFI_DIR/themes/style-clipboard.css"
/* Estilo dedicado para Portapapeles */

window {
    margin: 0px;
    background-color: ${BG_RGBA};
    border: 2px solid ${C_ACCENT_BLUE}; /* Acento azul para diferenciar del lanzador */
    border-radius: 10px;
    font-family: 'JetBrainsMono Nerd Font', 'monospace';
    font-size: 13px;
}

#input {
    margin: 10px 10px 4px 10px;
    border: 1px solid ${C_BORDER_INACTIVE};
    border-radius: 6px;
    background-color: ${SURFACE_70_RGBA};
    color: ${C_TEXT};
    padding: 6px 10px;
}

#inner-box {
    margin: 4px 10px 10px 10px;
    border: none;
    background-color: transparent;
}

#entry {
    padding: 4px 6px;
    background-color: transparent;
    border-radius: 4px;
    border: none;
}

#entry:selected {
    background-color: ${SURFACE_90_RGBA};
    transition: background-color 0.1s ease-in-out;
}

#text {
    color: ${C_TEXT};
    background-color: transparent;
}

#text:selected {
    color: ${C_ACCENT_BLUE};
    font-weight: bold;
}

#outer-box { margin: 0px; border: none; background-color: transparent; }
#scroll { margin: 0px; border: none; background-color: transparent; }
EOF

echo "${TXT_WOFI_CLIP_OK:-Estilo de Portapapeles creado con éxito.}"
echo ""

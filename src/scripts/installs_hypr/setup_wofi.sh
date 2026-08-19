#!/usr/bin/env bash
set -euo pipefail

# 1. Definición de rutas y carga de idioma
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
    # Fallback si no existe colors.sh
    C_BG="#1e222a"
    C_SURFACE="#282c34"
    C_BORDER_INACTIVE="#4b5263"
    C_BORDER_ACTIVE="#7ec7a2"
    C_TEXT="#abb2bf"
fi

echo "=========================================================="
echo "${TXT_WOFI_INSTALLING:-Generando estilos de Wofi...}"
echo "=========================================================="

WOFI_DIR="$HOME/.config/wofi"
mkdir -p "$WOFI_DIR"

# 3. Función auxiliar para convertir HEX a CSS rgba(r, g, b, alpha)
hex_to_rgba() {
    local hex="${1#\#}"
    local alpha="$2"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo "rgba($r, $g, b, $alpha)"
}

# Pre-calcular colores con transparencia en CSS
BG_RGBA=$(hex_to_rgba "$C_BG" 0.85)
SURFACE_70_RGBA=$(hex_to_rgba "$C_SURFACE" 0.70)
SURFACE_90_RGBA=$(hex_to_rgba "$C_SURFACE" 0.90)

# 4. Generar ~/.config/wofi/config
cat << EOF > "$WOFI_DIR/config"
# ~/.config/wofi/config (Generado automáticamente)
show=drun
allow_images=true
image_size=20
width=500
lines=10
location=top
yoffset=20
hide_scroll=true
print_command=true
EOF

# 5. Generar ~/.config/wofi/style.css
cat << EOF > "$WOFI_DIR/style.css"
/* ~/.config/wofi/style.css (Estilo Base) */

/* Ventana principal */
window {
    margin: 0px;
    background-color: ${BG_RGBA};
    border: 2px solid ${C_BORDER_ACTIVE};
    border-radius: 12px;
    font-family: 'Inter', 'JetBrains Mono Nerd Font', 'monospace';
    font-size: 14px;
}

/* Caja de búsqueda */
#input {
    margin: 12px 12px 6px 12px;
    border: 1px solid ${C_BORDER_INACTIVE};
    border-radius: 8px;
    background-color: ${SURFACE_70_RGBA};
    color: ${C_TEXT};
    padding: 8px;
}

/* Contenedor de la lista */
#inner-box {
    margin: 6px 12px 12px 12px;
    border: none;
    background-color: transparent;
}

/* Cada fila de programa */
#entry {
    padding: 6px 8px;
    background-color: transparent;
    border-radius: 6px;
    border: none;
}

/* Elemento seleccionado con cambio suave */
#entry:selected {
    background-color: ${SURFACE_90_RGBA};
    transition: background-color 0.1s ease-in-out;
}

/* Iconos de las apps */
#img {
    margin-right: 10px;
}

/* Texto de las apps */
#text {
    color: ${C_TEXT};
    background-color: transparent;
}

#text:selected {
    color: ${C_BORDER_ACTIVE};
    font-weight: bold;
}

/* Limpieza de contenedores ocultos */
#outer-box { margin: 0px; border: none; background-color: transparent; }
#scroll { margin: 0px; border: none; background-color: transparent; }
EOF

echo "${TXT_WOFI_OK:-Configuración de Wofi completada.}"
echo ""

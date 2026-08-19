#!/usr/bin/env bash
set -euo pipefail

# 1. Rutas y carga de idiomas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LANG_FILE="${1:-es.cfg}"
PATH_TRADUCCION="$SCRIPT_DIR/lang/$LANG_FILE"

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
    C_ACCENT_GREEN="#7ec7a2"
    C_SUBTEXT="#5c6370"
fi

echo "=========================================================="
echo "${TXT_BINDS_INSTALLING:-Instalando visualizador de atajos...}"
echo "=========================================================="

WOFI_DIR="$HOME/.config/wofi"
WOFI_THEME="$HOME/.config/wofi/themes"
WOFI_CONFIGS="$HOME/.config/wofi/configs"
mkdir -p "$WOFI_DIR"
mkdir -p "$WOFI_THEME"
mkdir -p "$WOFI_CONFIGS"

BIN_DIR="$HOME/.local/bin/minimaldots"

mkdir -p "$WOFI_DIR" "$BIN_DIR"

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

# ---------------------------------------------------------
# 3. Generar ~/.config/wofi/config-binds
# ---------------------------------------------------------
cat << EOF > "$WOFI_DIR/configs/config-binds"
# Configuración específica para el menú de Atajos de Teclado
show=dmenu
allow_images=false
width=650
height=480
lines=14
location=center
hide_scroll=true
matching=fuzzy
prompt=⌨️ Atajos de Teclado
EOF

# ---------------------------------------------------------
# 4. Generar ~/.config/wofi/style-binds.css
# ---------------------------------------------------------
cat << EOF > "$WOFI_DIR/themes/style-binds.css"
/* Estilo dedicado para el visualizador de atajos de teclado */

window {
    margin: 0px;
    background-color: ${BG_RGBA};
    border: 2px solid ${C_ACCENT_GREEN}; /* Acento verde menta */
    border-radius: 12px;
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
    color: ${C_ACCENT_GREEN};
    font-weight: bold;
}

#outer-box { margin: 0px; border: none; background-color: transparent; }
#scroll { margin: 0px; border: none; background-color: transparent; }
EOF

# ---------------------------------------------------------
# 5. Generar ~/.local/bin/minimaldots/show_binds
# ---------------------------------------------------------
cat << 'EOF' > "$BIN_DIR/show_binds"
#!/usr/bin/env bash
set -euo pipefail

JSON_FILE="$HOME/.cache/hypr/keybinds.json"
WOFI_CONFIG="$HOME/.config/wofi/config-binds"
WOFI_STYLE="$HOME/.config/wofi/style-binds.css"

# Verificar dependencias
if ! command -v jq &>/dev/null; then
    notify-send -a "Atajos" -i "dialog-error" "Error" "jq no está instalado."
    exit 1
fi

if [[ ! -f "$JSON_FILE" ]]; then
    notify-send -a "Atajos" -i "dialog-warning" "Atajos no encontrados" "No se detectó $JSON_FILE"
    exit 1
fi

# Procesar JSON y formatear por categorías/casillas
formatted_list=$(jq -r '
    group_by(.category) | .[] |
    "󰌌  [" + .[0].category + "]",
    (.[] | "   " + (if .mod == "" then "" else .mod + " + " end) + .key + "  󰁔  " + .description),
    ""
' "$JSON_FILE")

# Lanzar Wofi con el menú formateado
echo "$formatted_list" | wofi -c "$WOFI_CONFIG" -s "$WOFI_STYLE" --dmenu | true
EOF

chmod +x "$BIN_DIR/show_binds"

echo "${TXT_BINDS_OK:-show_binds instalado con éxito.}"
echo ""

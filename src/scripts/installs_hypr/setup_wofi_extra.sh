#!/usr/bin/env bash
set -euo pipefail

# Genera los dos menús "extra" de Wofi que NO tienen equivalente en un
# servicio Lua (a diferencia del wofi de aplicaciones, que ya regenera
# hyprland/services/wofi_theme.lua en cada arranque de Hyprland):
#   1. El selector del portapapeles (cliphist)
#   2. El visor de atajos de teclado (keybinds.json -> wofi)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LANG_FILE="${1:-es.cfg}"
PATH_TRADUCCION="$SCRIPT_DIR/lang/$LANG_FILE"

if [[ -f "$PATH_TRADUCCION" ]]; then
    source "$PATH_TRADUCCION"
fi

# Cargar la paleta global de colores (archivo generado por colors.sh,
# NUNCA el script generador).
PALETTE_FILE="$SCRIPT_DIR/colors/palette.sh"
if [[ -f "$PALETTE_FILE" ]]; then
    source "$PALETTE_FILE"
else
    # Fallback de seguridad si por algún motivo no existe la paleta
    C_BG="#1e222a"
    C_SURFACE="#282c34"
    C_BORDER_INACTIVE="#4b5263"
    C_ACCENT_BLUE="#7aa2f7"
    C_ACCENT_GREEN="#7ec7a2"
    C_TEXT="#abb2bf"
fi

echo "=========================================================="
echo "${TXT_WOFI_EXTRA_INSTALLING:-Generando menús extra de Wofi (portapapeles y atajos)...}"
echo "=========================================================="

WOFI_DIR="$HOME/.config/wofi"
WOFI_THEMES="$WOFI_DIR/themes"
WOFI_CONFIGS="$WOFI_DIR/configs"
BIN_DIR="$HOME/.local/bin/minimaldots"
mkdir -p "$WOFI_THEMES" "$WOFI_CONFIGS" "$BIN_DIR"

# Convertidor HEX -> CSS rgba(r, g, b, alpha)
hex_to_rgba() {
    local hex="${1#\#}"
    local alpha="$2"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo "rgba($r, $g, $b, $alpha)"
}

BG_90_RGBA=$(hex_to_rgba "$C_BG" 0.90)
SURFACE_70_RGBA=$(hex_to_rgba "$C_SURFACE" 0.70)
SURFACE_90_RGBA=$(hex_to_rgba "$C_SURFACE" 0.90)

# ==========================================================
# 1. PORTAPAPELES (cliphist)
# ==========================================================
cat << EOF > "$WOFI_CONFIGS/config-clipboard"
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

cat << EOF > "$WOFI_THEMES/style-clipboard.css"
/* Estilo dedicado para Portapapeles */
window {
    margin: 0px;
    background-color: ${BG_90_RGBA};
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
#inner-box { margin: 4px 10px 10px 10px; border: none; background-color: transparent; }
#entry { padding: 4px 6px; background-color: transparent; border-radius: 4px; border: none; }
#entry:selected { background-color: ${SURFACE_90_RGBA}; transition: background-color 0.1s ease-in-out; }
#text { color: ${C_TEXT}; background-color: transparent; }
#text:selected { color: ${C_ACCENT_BLUE}; font-weight: bold; }
#outer-box { margin: 0px; border: none; background-color: transparent; }
#scroll { margin: 0px; border: none; background-color: transparent; }
EOF

# ==========================================================
# 2. VISOR DE ATAJOS DE TECLADO (lee ~/.cache/hypr/keybinds.json,
#    escrito por hyprland/lib/keybinder.lua -> export_json())
# ==========================================================
cat << EOF > "$WOFI_CONFIGS/config-binds"
# Configuración específica para el menú de Atajos de Teclado
show=dmenu
allow_images=false
width=650
height=480
lines=14
location=center
hide_scroll=true
matching=fuzzy
prompt=⌨️  Atajos de Teclado
EOF

cat << EOF > "$WOFI_THEMES/style-binds.css"
/* Estilo dedicado para el visualizador de atajos de teclado */
window {
    margin: 0px;
    background-color: ${BG_90_RGBA};
    border: 2px solid ${C_ACCENT_GREEN};
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
#inner-box { margin: 4px 10px 10px 10px; border: none; background-color: transparent; }
#entry { padding: 4px 6px; background-color: transparent; border-radius: 4px; border: none; }
#entry:selected { background-color: ${SURFACE_90_RGBA}; transition: background-color 0.1s ease-in-out; }
#text { color: ${C_TEXT}; background-color: transparent; }
#text:selected { color: ${C_ACCENT_GREEN}; font-weight: bold; }
#outer-box { margin: 0px; border: none; background-color: transparent; }
#scroll { margin: 0px; border: none; background-color: transparent; }
EOF

# El binario "show_binds" agrupa por categoría usando jq y lanza Wofi
# con el estilo generado arriba. Consume el JSON que exporta el
# Keybinder de Lua (categorías incluidas).
cat << 'EOF' > "$BIN_DIR/show_binds"
#!/usr/bin/env bash
set -euo pipefail

JSON_FILE="$HOME/.cache/hypr/keybinds.json"
WOFI_CONFIG="$HOME/.config/wofi/configs/config-binds"
WOFI_STYLE="$HOME/.config/wofi/themes/style-binds.css"

if ! command -v jq &>/dev/null; then
    notify-send -a "Atajos" -i "dialog-error" "Error" "jq no está instalado."
    exit 1
fi

if [[ ! -f "$JSON_FILE" ]]; then
    notify-send -a "Atajos" -i "dialog-warning" "Atajos no encontrados" "No se detectó $JSON_FILE"
    exit 1
fi

formatted_list=$(jq -r '
    group_by(.category) | .[] |
    "󰌌  [" + .[0].category + "]",
    (.[] | "   " + (if .mod == "" then "" else .mod + " + " end) + .key + "  󰁔  " + .description),
    ""
' "$JSON_FILE")

echo "$formatted_list" | wofi -c "$WOFI_CONFIG" -s "$WOFI_STYLE" --dmenu | true
EOF

chmod +x "$BIN_DIR/show_binds"

echo "${TXT_WOFI_EXTRA_OK:-Menús extra de Wofi generados correctamente.}"
echo ""

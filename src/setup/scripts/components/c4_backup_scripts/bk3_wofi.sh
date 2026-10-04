#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../utils/u3_env.sh"


# ==== WOFI INSTALACION ==== #
# Genera los menús "extra" de Wofi que NO tienen equivalente en un
# servicio Lua (a diferencia del wofi de aplicaciones, que ya regenera
# hyprland/services/wofi_theme.lua en cada arranque de Hyprland):
#   1. El selector del portapapeles (cliphist)
#   2. El visor de atajos de teclado (keybinds.json -> wofi)
#   3. El OSD de volumen
#
# Todo se instala en $MD_WOFI_DIR (~/.local/bin/MinimalistDots/wofi):
#   configs/config-*      themes/style-*.css

# Tamaño del OSD de volumen (solo muestra "ícono + número"; si ves el texto cortado, súbele el ancho)
OSD_WIDTH=80
OSD_HEIGHT=34

mkdir -p "$MD_WOFI_CONFIGS" "$MD_WOFI_THEMES" "$MD_SCRIPTS_DIR"

# Convertidor HEX -> CSS rgba(r, g, b, alpha)
hex_to_rgba() {
    local hex="${1#\#}"
    local alpha="$2"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo "rgba($r, $g, $b, $alpha)"
}

BG_90_RGBA="$(hex_to_rgba "$C_BG" 0.90)"
SURFACE_70_RGBA="$(hex_to_rgba "$C_SURFACE" 0.70)"
SURFACE_90_RGBA="$(hex_to_rgba "$C_SURFACE" 0.90)"


# write_menu_config <archivo> <titulo> <prompt> <ancho> <alto> <lineas>
write_menu_config() {
    local file="$1" title="$2" prompt="$3" width="$4" height="$5" lines="$6"
    cat > "$file" <<EOF
# Configuración específica para $title
show=dmenu
allow_images=false
width=$width
height=$height
lines=$lines
location=center
hide_scroll=true
matching=fuzzy
prompt=$prompt
EOF
}

# write_menu_css <archivo> <titulo> <color-acento> <radio-borde>
write_menu_css() {
    local file="$1" title="$2" accent="$3" radius="$4"
    cat > "$file" <<EOF
/* Estilo dedicado para $title */
window {
    margin: 0px;
    background-color: ${BG_90_RGBA};
    border: 2px solid ${accent};
    border-radius: ${radius}px;
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
#text:selected { color: ${accent}; font-weight: bold; }
#outer-box { margin: 0px; border: none; background-color: transparent; }
#scroll { margin: 0px; border: none; background-color: transparent; }
EOF
}


# ==========================================================
# 1. PORTAPAPELES (cliphist) -- acento azul para diferenciarlo del lanzador
# ==========================================================
write_menu_config "$MD_WOFI_CONFIGS/config-clipboard" "Gestor de Portapapeles (cliphist)" \
    "📋 Portapapeles" 700 420 12
write_menu_css "$MD_WOFI_THEMES/style-clipboard.css" "Portapapeles" "$C_ACCENT_BLUE" 10


# ==========================================================
# 2. VISOR DE ATAJOS DE TECLADO (lee ~/.cache/hypr/keybinds.json,
#    escrito por hyprland/lib/keybinder.lua -> export_json())
# ==========================================================
write_menu_config "$MD_WOFI_CONFIGS/config-binds" "el menú de Atajos de Teclado" \
    "⌨️  Atajos de Teclado" 650 480 14
write_menu_css "$MD_WOFI_THEMES/style-binds.css" "el visualizador de atajos de teclado" "$C_ACCENT_GREEN" 12


# ==========================================================
# 3. OSD DE VOLUMEN (Wofi HUD)
# ==========================================================
cat > "$MD_WOFI_CONFIGS/config-volume" <<EOF
show=dmenu
allow_images=false
width=$OSD_WIDTH
height=$OSD_HEIGHT
lines=1
location=top
yoffset=15
hide_search=true
hide_scroll=true
no_actions=true
filter_title=volume-osd
EOF

cat > "$MD_WOFI_THEMES/style-volume.css" <<EOF
/* Estilo Minimalista OSD de Volumen */
window {
    margin: 0px;
    background-color: ${BG_90_RGBA};
    border: 1px solid ${C_BORDER_INACTIVE};
    border-radius: 8px;
    font-family: 'JetBrainsMono Nerd Font', 'monospace';
    font-size: 13px;
}

#input {
    display: none;
    visibility: hidden;
}

#inner-box, #outer-box, #scroll {
    margin: 0px;
    padding: 0px;
    border: none;
    background-color: transparent;
}

#entry {
    padding: 6px 10px;
    margin: 0px;
    background-color: transparent;
    border: none;
}

#entry:selected {
    background-color: transparent;
}

#text {
    color: ${C_TEXT};
    background-color: transparent;
    font-weight: bold;
}

/* Neutralizar el resaltado rosa/foco predeterminado de GTK */
#text:selected {
    color: ${C_TEXT};
    background-color: transparent;
}
EOF


# ==========================================================
# 4. SCRIPT "show_binds"
# ==========================================================
# Agrupa por categoría usando jq y lanza Wofi con el estilo generado arriba.
# Consume el JSON que exporta el Keybinder de Lua (categorías incluidas).
# __MD_WOFI_DIR__ se reemplaza abajo por la ruta real (MD_WOFI_DIR).
cat > "$MD_SCRIPTS_DIR/show_binds" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

JSON_FILE="$HOME/.cache/hypr/keybinds.json"
WOFI_CONFIG="__MD_WOFI_DIR__/configs/config-binds"
WOFI_STYLE="__MD_WOFI_DIR__/themes/style-binds.css"

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

echo "$formatted_list" | wofi -c "$WOFI_CONFIG" -s "$WOFI_STYLE" --dmenu || true
EOF

sed -i "s|__MD_WOFI_DIR__|${MD_WOFI_DIR}|g" "$MD_SCRIPTS_DIR/show_binds"
chmod +x "$MD_SCRIPTS_DIR/show_binds"

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LANG_FILE="${1:-es.cfg}"
PATH_TRADUCCION="$SCRIPT_DIR/lang/$LANG_FILE"

if [[ -f "$PATH_TRADUCCION" ]]; then
    source "$PATH_TRADUCCION"
fi

# ------------------------------------------------------------------
# Cargar la paleta global (fuente única de verdad de todos los colores)
# Generada previamente por src/scripts/colors.sh -> src/colors/palette.sh
# ------------------------------------------------------------------
PALETTE_FILE="$SCRIPT_DIR/colors/palette.sh"
if [[ -f "$PALETTE_FILE" ]]; then
    source "$PALETTE_FILE"
else
    echo "Error: no se encontró la paleta en $PALETTE_FILE" >&2
    echo "Ejecuta primero src/scripts/colors.sh antes de este script." >&2
    exit 1
fi

echo "=========================================================="
echo "${TXT_COLORS_INSTALLING:-Generando módulo de colores...}"
echo "=========================================================="

HYPR_DIR="$HOME/.config/hypr/hyprland"
mkdir -p "$HYPR_DIR"

# ------------------------------------------------------------------
# Genera hyprland/colors.lua a partir de la paleta bash.
# Esta es la ÚNICA fuente de colores que usan los módulos Lua
# (general.lua, y todos los services/*.lua: waybar, wofi, swaync, etc).
# Cambiar los colores = editar src/colors/palette.sh y reinstalar.
# ------------------------------------------------------------------
cat << EOF > "$HYPR_DIR/colors.lua"
-- ~/.config/hypr/hyprland/colors.lua
-- Autogenerado por setup_colors.sh a partir de src/colors/palette.sh
-- NO EDITES ESTE ARCHIVO A MANO: tus cambios se perderán en la
-- próxima instalación. Para cambiar la paleta, edita:
--   src/scripts/colors.sh (o src/colors/palette.sh si ya existe)

local function rgba(raw_hex, alpha)
    alpha = alpha or "ee"
    return "rgba(" .. raw_hex .. alpha .. ")"
end

return {
    background      = { hex = "${C_BG}",             hypr = rgba("${RAW_BG}") },
    surface         = { hex = "${C_SURFACE}",         hypr = rgba("${RAW_SURFACE}") },
    selection       = { hex = "${C_SELECTION}",       hypr = rgba("${RAW_SELECTION}") },

    border_inactive = { hex = "${C_BORDER_INACTIVE}", hypr = rgba("${RAW_GRAY}", "aa") },
    border_active   = { hex = "${C_BORDER_ACTIVE}",   hypr = rgba("${RAW_GREEN}") },

    text            = { hex = "${C_TEXT}",            hypr = rgba("${RAW_TEXT}") },
    subtext         = { hex = "${C_SUBTEXT}",         hypr = rgba("${RAW_SUBTEXT}") },

    accent_blue     = { hex = "${C_ACCENT_BLUE}",     hypr = rgba("${RAW_BLUE}") },
    accent_green    = { hex = "${C_ACCENT_GREEN}",    hypr = rgba("${RAW_GREEN}") },
    accent_red      = { hex = "${C_ACCENT_RED}",      hypr = rgba("${RAW_RED}") },
    accent_yellow   = { hex = "${C_ACCENT_YELLOW}",   hypr = rgba("${RAW_YELLOW}") },
    accent_magenta  = { hex = "${C_ACCENT_MAGENTA}",  hypr = rgba("${RAW_MAGENTA}") },
    accent_cyan     = { hex = "${C_ACCENT_CYAN}",     hypr = rgba("${RAW_CYAN}") },
}
EOF

echo "${TXT_COLORS_OK:-Módulo de colores configurado correctamente.}"
echo ""

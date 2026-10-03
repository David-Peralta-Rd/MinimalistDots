#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../utils/u3_env.sh"

# c3 pasa HYPR_DIR; si el script se ejecuta solo, usa ~/.config/hypr
HYPR_DIR="${HYPR_DIR:-$MD_HYPR_DIR}"
TARGET="$HYPR_DIR/hyprland/colors.lua"
mkdir -p "$(dirname "$TARGET")"

cat > "$TARGET" <<EOF
-- ~/.config/hypr/hyprland/colors.lua
-- Autogenerado a partir de src/setup/scripts/utils/u2_palette.sh
-- NO EDITES ESTE ARCHIVO A MANO: tus cambios se perderán en la
-- próxima instalación. Para cambiar la paleta, edita:
--   src/setup/scripts/utils/u2_palette.sh

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

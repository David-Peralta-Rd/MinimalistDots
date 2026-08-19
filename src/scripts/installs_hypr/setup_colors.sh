#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LANG_FILE="${1:-es.cfg}"
PATH_TRADUCCION="$SCRIPT_DIR/lang/$LANG_FILE"

if [[ -f "$PATH_TRADUCCION" ]]; then
    source "$PATH_TRADUCCION"
fi

echo "=========================================================="
echo "${TXT_COLORS_INSTALLING:-Generando módulo de colores...}"
echo "=========================================================="

HYPR_DIR="$HOME/.config/hypr/hyprland"
mkdir -p "$HYPR_DIR"

cat << 'EOF' > "$HYPR_DIR/colors.lua"
-- Módulo de paleta de colores (Gris Frío & Colores Muted)
-- Autogenerado por el instalador.

local colors = {
    background      = { hex = "#1e222a", rgb = "1e222a", rgba = "rgba(30, 34, 42, 1.0)" },
    surface         = { hex = "#282c34", rgb = "282c34", rgba = "rgba(40, 44, 52, 1.0)" },
    selection       = { hex = "#3e4451", rgb = "3e4451", rgba = "rgba(62, 68, 81, 1.0)" },

    border_inactive = { hex = "#4b5263", rgb = "4b5263", rgba = "rgba(75, 82, 99, 1.0)" },
    border_active   = { hex = "#7ec7a2", rgb = "7ec7a2", rgba = "rgba(126, 199, 162, 1.0)" },

    text            = { hex = "#abb2bf", rgb = "abb2bf", rgba = "rgba(171, 178, 191, 1.0)" },
    subtext         = { hex = "#5c6370", rgb = "5c6370", rgba = "rgba(92, 99, 112, 1.0)" },

    accent_blue     = { hex = "#7aa2f7", rgb = "7aa2f7", rgba = "rgba(122, 162, 247, 1.0)" },
    accent_green    = { hex = "#7ec7a2", rgb = "7ec7a2", rgba = "rgba(126, 199, 162, 1.0)" },
    accent_red      = { hex = "#e06c75", rgb = "e06c75", rgba = "rgba(224, 108, 117, 1.0)" },
}

return colors
EOF

echo "${TXT_COLORS_OK:-Módulo de colores configurado correctamente.}"
echo ""

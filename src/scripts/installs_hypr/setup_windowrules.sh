#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LANG_FILE="${1:-es.cfg}"
PATH_TRADUCCION="$SCRIPT_DIR/lang/$LANG_FILE"

if [[ -f "$PATH_TRADUCCION" ]]; then
    source "$PATH_TRADUCCION"
fi

echo "=========================================================="
echo "${TXT_WINDOWRULES_INSTALLING:-Generando reglas de ventana...}"
echo "=========================================================="

HYPR_DIR="$HOME/.config/hypr/hyprland"
mkdir -p "$HYPR_DIR"

cat << 'EOF' > "$HYPR_DIR/windowrules.lua"
local Rules = require("hyprland.lib.rules")

Rules.forClass(".*"):noBlur()
Rules.forClass("^(pavucontrol)$"):float()
Rules.forClass("^(blueman%-manager)$"):float()

Rules.forClass("hyprland-run"):custom({
    name  = "move-hyprland-run",
    move  = "20 monitor_h-120",
    float = true,
})

-- Reglas para imv y mpv (imágenes y videos)
Rules.forClass("imv"):custom({ float = true, size = "70% 70%", center = true })
Rules.forClass("mpv"):custom({ float = true, size = "60% 60%", center = true })
EOF

echo "${TXT_WINDOWRULES_OK:-Reglas de ventana generadas correctamente.}"
echo ""

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LANG_FILE="${1:-es.cfg}"
PATH_TRADUCCION="$SCRIPT_DIR/lang/$LANG_FILE"

if [[ -f "$PATH_TRADUCCION" ]]; then
    source "$PATH_TRADUCCION"
fi

echo "=========================================================="
echo "${TXT_MONITORS_INSTALLING:-Generando configuración de monitores...}"
echo "=========================================================="

HYPR_DIR="$HOME/.config/hypr/hyprland"
mkdir -p "$HYPR_DIR"

cat << 'EOF' > "$HYPR_DIR/monitors.lua"
------------------
---- MONITORS ----
------------------

-- Monitor por defecto: autodetecta resolución preferida y lo ubica en 0x0.
-- Para setups personalizados (multi-monitor, escalado, etc.) usa el override:
-- ~/.config/hypr/custom_minimalist/monitors.lua
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "0x0",
    scale    = "1",
})
EOF

echo "${TXT_MONITORS_OK:-Configuración de monitores generada correctamente.}"
echo ""

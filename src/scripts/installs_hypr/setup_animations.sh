#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LANG_FILE="${1:-es.cfg}"
PATH_TRADUCCION="$SCRIPT_DIR/lang/$LANG_FILE"

if [[ -f "$PATH_TRADUCCION" ]]; then
    source "$PATH_TRADUCCION"
fi

echo "=========================================================="
echo "${TXT_ANIMATIONS_INSTALLING:-Generando animaciones...}"
echo "=========================================================="

HYPR_DIR="$HOME/.config/hypr/hyprland"
mkdir -p "$HYPR_DIR"

cat << 'EOF' > "$HYPR_DIR/animations.lua"
-- ~/.config/hypr/hyprland/animations.lua

hl.curve("quick",  { type = "bezier", points = { {0.15, 0}, {0.1, 1} } })
hl.curve("linear", { type = "bezier", points = { {0, 0},    {1, 1}  } })

local function setAnimations(list)
    for _, a in ipairs(list) do
        hl.animation(a)
    end
end

setAnimations({
    -- Ventanas
    { leaf = "global",     enabled = true, speed = 1.5, bezier = "quick" },
    { leaf = "windows",    enabled = true, speed = 1.5, bezier = "quick" },
    { leaf = "windowsIn",  enabled = true, speed = 1.2, bezier = "quick",  style = "popin 95%" },
    { leaf = "windowsOut", enabled = true, speed = 1.0, bezier = "linear", style = "popin 95%" },
    { leaf = "border",     enabled = true, speed = 1.5, bezier = "quick" },

    -- Fades (heredan a fadeIn/fadeOut si no se definen; aquí los definimos explícito)
    { leaf = "fadeIn",     enabled = true, speed = 1.0, bezier = "linear" },
    { leaf = "fadeOut",    enabled = true, speed = 1.0, bezier = "linear" },

    -- Layers: popups, menús, notificaciones
    { leaf = "layers",     enabled = true, speed = 1.2, bezier = "quick" },
    { leaf = "layersIn",   enabled = true, speed = 1.0, bezier = "quick",  style = "fade" },
    { leaf = "layersOut",  enabled = true, speed = 1.0, bezier = "linear", style = "fade" },

    -- Workspaces
    { leaf = "workspaces",    enabled = true, speed = 1.0, bezier = "linear", style = "fade" },
    { leaf = "workspacesIn",  enabled = true, speed = 1.0, bezier = "linear", style = "fade" },
    { leaf = "workspacesOut", enabled = true, speed = 1.0, bezier = "linear", style = "fade" },

    -- Zoom del overview / pinch gesture
    { leaf = "zoomFactor", enabled = true, speed = 1.5, bezier = "quick" },
})
EOF

echo "${TXT_ANIMATIONS_OK:-Animaciones generadas correctamente.}"
echo ""

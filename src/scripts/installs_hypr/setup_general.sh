#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LANG_FILE="${1:-es.cfg}"
PATH_TRADUCCION="$SCRIPT_DIR/lang/$LANG_FILE"

if [[ -f "$PATH_TRADUCCION" ]]; then
    source "$PATH_TRADUCCION"
fi

echo "=========================================================="
echo "${TXT_GENERAL_INSTALLING:-Generando configuración general (gaps, bordes, input)...}"
echo "=========================================================="

HYPR_DIR="$HOME/.config/hypr/hyprland"
mkdir -p "$HYPR_DIR"

# Nota: general.lua no necesita variables bash inyectadas, porque lee
# los colores directamente desde el módulo compartido hyprland.colors
# (generado por setup_colors.sh) en tiempo de carga de Hyprland.
cat << 'EOF' > "$HYPR_DIR/general.lua"
-- ~/.config/hypr/hyprland/general.lua
local colors = require("hyprland.colors")

hl.config({
    general = {
        gaps_in     = 2,
        gaps_out    = 6,
        border_size = 1,
        col = {
            active_border   = colors.border_active.hypr,
            inactive_border = colors.border_inactive.hypr,
        },
        resize_on_border = true,   -- útil para trabajo rápido con mouse
        allow_tearing    = false,
        layout           = "dwindle",
    },
    decoration = {
        rounding       = 3,        -- casi sin curvas, minimalista
        rounding_power = 2,
        active_opacity   = 1.0,
        inactive_opacity = 0.97,   -- diferencia sutil, ayuda a ubicar la ventana activa sin distraer
        shadow = {
            enabled = false,       -- fuera: menos carga visual y de GPU
        },
        blur = {
            enabled = false,       -- fuera: mismo criterio, prioriza velocidad sobre efectos
        },
    },
    dwindle = {
        preserve_split = true,
    },
    misc = {
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
    },
})

-- Configuración de teclado / touchpad
hl.config({
    input = {
        kb_layout = "us",
        numlock_by_default = true,
        repeat_delay = 170,
        repeat_rate  = 50,

        follow_mouse            = 1,
        off_window_axis_events  = 2,

        touchpad = {
            natural_scroll        = true,
            disable_while_typing  = true,
            clickfinger_behavior  = true,
            scroll_factor         = 0.7,
        },

        sensitivity   = -0.8,
        accel_profile = "flat",
    },
})
EOF

echo "${TXT_GENERAL_OK:-Configuración general generada correctamente.}"
echo ""

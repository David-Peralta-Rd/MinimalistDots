#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LANG_FILE="${1:-es.cfg}"
PATH_TRADUCCION="$SCRIPT_DIR/lang/$LANG_FILE"

if [[ -f "$PATH_TRADUCCION" ]]; then
    source "$PATH_TRADUCCION"
fi

# Cargar la paleta global (para hyprlock.conf, que es .conf plano y no
# puede leer hyprland/colors.lua como hacen los módulos Lua).
PALETTE_FILE="$SCRIPT_DIR/colors/palette.sh"
if [[ -f "$PALETTE_FILE" ]]; then
    source "$PALETTE_FILE"
else
    echo "Error: no se encontró la paleta en $PALETTE_FILE" >&2
    exit 1
fi

hex_to_rgb() {
    local hex="${1#\#}"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo "$r, $g, $b"
}

BG_RGB="$(hex_to_rgb "$C_BG")"
TEXT_RGB="$(hex_to_rgb "$C_TEXT")"
BORDER_INACTIVE_RGB="$(hex_to_rgb "$C_BORDER_INACTIVE")"
BORDER_ACTIVE_RGB="$(hex_to_rgb "$C_BORDER_ACTIVE")"
ACCENT_RED_RGB="$(hex_to_rgb "$C_ACCENT_RED")"
SURFACE_RGB="$(hex_to_rgb "$C_SURFACE")"

echo "=========================================================="
echo "${TXT_HYPR_ROOT_INSTALLING:-Configurando archivos principales en ~/.config/hypr/...}"
echo "=========================================================="

HYPR_ROOT="$HOME/.config/hypr"
mkdir -p "$HYPR_ROOT"

# 1. hyprland.lua (punto de entrada principal, no depende de colores)
cat << 'EOF' > "$HYPR_ROOT/hyprland.lua"
--------------------------------------------------------------------------------------
-- NO MODIFIQUES ESTA CONFIGURACIÓN BASE.                                          --
-- PARA PERSONALIZACIONES, UTILIZA: ~/.config/hypr/custom_minimalist/               --
--------------------------------------------------------------------------------------

-- Carga de librerías base (Keybinder, Rules, Services, helpers globales)
require("hyprland.lib")

-- Carga de servicios (waybar, hypridle, swaync, etc.)
require("hyprland.services")

-- Carga de animaciones
require("hyprland.animations")

-- Entorno y variables de sistema
require("hyprland.env")
require_if_exists("custom_minimalist.env", HOME .. "/.config/hypr/custom_minimalist/env.lua")

-- Configuración de monitores
require("hyprland.monitors")
require_if_exists("custom_minimalist.monitors", HOME .. "/.config/hypr/custom_minimalist/monitors.lua")

-- Reglas de ventanas
require("hyprland.windowrules")
require_if_exists("custom_minimalist.windowrules", HOME .. "/.config/hypr/custom_minimalist/windowrules.lua")

-- Configuración general de UI/UX (gaps, bordes, input)
require("hyprland.general")
require_if_exists("custom_minimalist.general", HOME .. "/.config/hypr/custom_minimalist/general.lua")

-- Atajos de teclado
require("hyprland.keybinds")
require_if_exists("custom_minimalist.keybinds", HOME .. "/.config/hypr/custom_minimalist/keybinds.lua")
EOF

# 2. hypridle.conf (no depende de colores)
cat << 'EOF' > "$HYPR_ROOT/hypridle.conf"
general {
    lock_cmd = pidof hyprlock || hyprlock          # Evita abrir múltiples instancias
    before_sleep_cmd = loginctl lock-session      # Bloquea la sesión antes de suspender
    after_sleep_cmd = hyprctl dispatch dpms on    # Enciende la pantalla al despertar
}

# Bloquear pantalla tras 20 minutos (1200 segundos)
listener {
    timeout = 1200
    on-timeout = loginctl lock-session
}

# Apagar pantalla a los 21 minutos (1260 segundos)
listener {
    timeout = 1260
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}
EOF

# 3. hyprlock.conf (colores inyectados desde la paleta global)
cat << EOF > "$HYPR_ROOT/hyprlock.conf"
# CONFIGURACIÓN GENERAL
general {
    disable_loading_bar = true
    hide_cursor = true
    grace = 0
    no_fade_in = false
}

# FONDO ADAPTATIVO
background {
    monitor =
    path = screenshot            # Captura dinámicamente el fondo de pantalla actual

    # Filtros de desenfoque
    blur_passes = 4
    blur_size = 7
    noise = 0.015
    contrast = 0.8916
    brightness = 0.70

    # Capa translúcida usando el color de fondo de la paleta (${C_BG})
    color = rgba(${BG_RGB}, 0.8)
}

# RELOJ DIGITAL
label {
    monitor =
    text = cmd[update:1000] echo "\$(date +"%H:%M")"
    color = rgba(${TEXT_RGB}, 1.0)       # Texto general (${C_TEXT})
    font_size = 80
    font_family = JetBrains Mono Nerd Font Bold
    position = 0, 180
    halign = center
    valign = center
}

# SALUDO MINIMALISTA
label {
    monitor =
    text = Hola, \$USER
    color = rgba(${TEXT_RGB}, 0.8)      # Texto con ligera transparencia
    font_size = 14
    font_family = JetBrains Mono Nerd Font Regular
    position = 0, -40
    halign = center
    valign = center
}

# CAMPO DE ENTRADA DE CONTRASEÑA
input-field {
    monitor =
    size = 250, 45
    outline_thickness = 2
    dots_size = 0.22
    dots_spacing = 0.35
    dots_center = true

    # Paleta Muted/Ergonómica
    outer_color = rgba(${BORDER_INACTIVE_RGB}, 0.7)   # border_inactive (${C_BORDER_INACTIVE})
    check_color = rgba(${BORDER_ACTIVE_RGB}, 1.0)     # border_active (${C_BORDER_ACTIVE})
    fail_color = rgba(${ACCENT_RED_RGB}, 1.0)         # accent_red (${C_ACCENT_RED})
    inner_color = rgba(${SURFACE_RGB}, 1.0)           # surface (${C_SURFACE})
    font_color = rgba(${TEXT_RGB}, 1.0)               # text (${C_TEXT})

    fade_on_empty = true
    fade_timeout = 1500
    placeholder_text = <i>Ingresa contraseña...</i>
    hide_input = false

    position = 0, -110
    halign = center
    valign = center
}
EOF

# 4. hyprpaper.conf (no depende de colores)
cat << 'EOF' > "$HYPR_ROOT/hyprpaper.conf"
# Desactivar mensaje de splash de hyprland
splash = false
EOF

echo "${TXT_HYPR_ROOT_OK:-Archivos base configurados correctamente.}"
echo ""

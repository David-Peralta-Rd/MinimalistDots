#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LANG_FILE="${1:-es.cfg}"
PATH_TRADUCCION="$SCRIPT_DIR/lang/$LANG_FILE"

if [[ -f "$PATH_TRADUCCION" ]]; then
    source "$PATH_TRADUCCION"
fi

echo "=========================================================="
echo "${TXT_HYPR_ROOT_INSTALLING:-Configurando archivos principales en ~/.config/hypr/...}"
echo "=========================================================="

HYPR_ROOT="$HOME/.config/hypr"
mkdir -p "$HYPR_ROOT"

# 1. hyprland.lua
cat << 'EOF' > "$HYPR_ROOT/hyprland.lua"
--------------------------------------------------------------------------------------
-- NO MODIFIQUES ESTA CONFIGURACIÓN BASE.                                          --
-- PARA PERSONALIZACIONES, UTILIZA: ~/.config/hypr/custom_minimalist/               --
--------------------------------------------------------------------------------------

-- Carga de librerías base
require("hyprland.lib")

-- Carga de servicios (waybar, hypridle, dunst, etc.)
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

-- Configuración general de UI/UX
require("hyprland.general")
require_if_exists("custom_minimalist.general", HOME .. "/.config/hypr/custom_minimalist/general.lua")

-- Atajos de teclado
require("hyprland.keybinds")
require_if_exists("custom_minimalist.keybinds", HOME .. "/.config/hypr/custom_minimalist/keybinds.lua")
EOF

# 2. hypridle.conf
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

# 3. hyprlock.conf (Adaptado a tu nueva paleta ergonómica)
cat << 'EOF' > "$HYPR_ROOT/hyprlock.conf"
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

    # Capa translúcida usando tu fondo #1e222a (80% opacidad)
    color = rgba(30, 34, 42, 0.8)
}

# RELOJ DIGITAL
label {
    monitor =
    text = cmd[update:1000] echo "$(date +"%H:%M")"
    color = rgba(171, 178, 191, 1.0)       # Texto general (#abb2bf)
    font_size = 80
    font_family = JetBrains Mono Nerd Font Bold
    position = 0, 180
    halign = center
    valign = center
}

# SALUDO MINIMALISTA
label {
    monitor =
    text = Hola, $USER
    color = rgba(171, 178, 191, 0.8)      # Texto con ligera transparencia
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
    outer_color = rgba(75, 82, 99, 0.7)    # border_inactive (#4b5263)
    check_color = rgba(126, 199, 162, 1.0) # border_active / menta (#7ec7a2)
    fail_color = rgba(224, 108, 117, 1.0)  # accent_red / coral (#e06c75)
    inner_color = rgba(40, 44, 52, 1.0)    # surface (#282c34)
    font_color = rgba(171, 178, 191, 1.0)  # text (#abb2bf)

    fade_on_empty = true
    fade_timeout = 1500
    placeholder_text = <i>Ingresa contraseña...</i>
    hide_input = false

    position = 0, -110
    halign = center
    valign = center
}
EOF

# 4. hyprpaper.conf
cat << 'EOF' > "$HYPR_ROOT/hyprpaper.conf"
# Desactivar mensaje de splash de hyprland
splash = false
EOF

echo "${TXT_HYPR_ROOT_OK:-Archivos base configurados correctamente.}"
echo ""

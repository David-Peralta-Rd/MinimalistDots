#!/usr/bin/env bash
set -euo pipefail

ARCHIVO_LANG="${1:-en.cfg}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LANG_DIR="$PROJECT_ROOT/src/lang"

PATH_TRADUCCION="$LANG_DIR/$ARCHIVO_LANG"
if [ -f "$PATH_TRADUCCION" ]; then
    source "$PATH_TRADUCCION"
else
    echo "Error: no se pudo encontrar el archivo de idioma en $PATH_TRADUCCION" >&2
    exit 1
fi

HYPR_DIR="$HOME/.config/hypr"
BACKUP_ROOT="$HOME/.config/backups_dots/hypr-backups"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

SOURCE_DIR="$PROJECT_ROOT/src/.config/hypr/hyprland"
DEST_DIR="$HYPR_DIR/hyprland"

if [ ! -d "$SOURCE_DIR" ]; then
    echo "$TXT_SOURCE_NOT_FOUND $SOURCE_DIR" >&2
    exit 1
fi

echo "=========================================================="
echo "$TXT_CONFIRM_WARNING1 $HYPR_DIR"
echo "$TXT_CONFIRM_WARNING2 $BACKUP_DIR"
echo "=========================================================="
read -rp "$TXT_CONFIRM_PROMPT " confirm
if [ "$confirm" != "$TXT_CONFIRM_WORD" ]; then
    echo "$TXT_CANCELLED"
    exit 0
fi

echo "$TXT_BACKUP_DOING $HYPR_DIR -> $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
cp -a "$HYPR_DIR/." "$BACKUP_DIR/"
echo "$TXT_BACKUP_DONE"

echo "$TXT_CLEANING"
rm -rf "$HYPR_DIR"
mkdir -p "$HYPR_DIR"
echo "$TXT_CLEANING_DONE"

echo "$TXT_COPYING $SOURCE_DIR -> $DEST_DIR"
mkdir -p "$DEST_DIR"
rsync -a "$SOURCE_DIR/" "$DEST_DIR/"
echo "$TXT_COPYING_DONE"

TARGET="$HYPR_DIR/hyprland.lua"
TARGET_HYPRIDLE="$HYPR_DIR/hypridle.conf"
TARGET_HYPRLOCK="$HYPR_DIR/hyprlock.conf"

echo "$TXT_WRITING_CONFIG $TARGET"

tee "$TARGET" > /dev/null <<'EOF'
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- NO MODIFIQUES ESTA CONFIGURACIÓN; SI DESEAS HACER CAMBIOS,                       --
-- VE A LA SIGUIENTE CARPETA Y REALIZA TUS CONFIGURACIONES PERSONALES:              --
-- ~/.config/hypr/custom_minimalist/                                                --
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- DO NOT TOUCH THIS CONFIGURATION; IF YOU WANT TO MODIFY ANYTHING,                 --
-- GO TO THE FOLDER AND MAKE YOUR PERSONAL CONFIGURATIONS:                          --
-- ~/.config/hypr/custom_minimalist/                                                --
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Loading lib
require("hyprland.lib")
-- Loading services
require("hyprland.services")
-- Loading Animation Fast
require("hyprland.animations")
-- Loading env MinimalDtos
require("hyprland.env")
require_if_exists("custom_minimalist.env", HOME .. "/.config/hypr/custom_minimalist/env.lua")
-- Configuration hyprland (monitores)
require("hyprland.monitors")
require_if_exists("custom_minimalist.monitors", HOME .. "/.config/hypr/custom_minimalist/monitors.lua")
-- Configuration windowrules
require("hyprland.windowrules")
require_if_exists("custom_minimalist.windowrules", HOME .. "/.config/hypr/custom_minimalist/windowrules.lua")
-- Configuration general
require("hyprland.general")
require_if_exists("custom_minimalist.general", HOME .. "/.config/hypr/custom_minimalist/general.lua")
-- Atajos de teclado
require("hyprland.keybinds")
require_if_exists("custom_minimalist.keybinds", HOME .. "/.config/hypr/custom_minimalist/keybinds.lua")
EOF


# INSTALACION DE HYPRIDLE
tee "$TARGET_HYPRIDLE" > /dev/null <<'EOF'
general {
    lock_cmd = pidof hyprlock || hyprlock          # Evita abrir múltiples instancias de hyprlock
    before_sleep_cmd = loginctl lock-session      # Bloquea la sesión automáticamente antes de suspender
    after_sleep_cmd = hyprctl dispatch dpms on    # Enciende la pantalla al despertar
}

# Bloquear pantalla tras 20 minutos (1200 segundos)
listener {
    timeout = 1200
    on-timeout = loginctl lock-session
}

listener {
    timeout = 1260
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}
EOF


# INSTALACION DE HYPRLOCK
tee "$TARGET_HYPRLOCK" > /dev/null <<'EOF'
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
    path = screenshot            # Captura dinámicamente tu fondo de pantalla actual

    # Filtros de desenfoque profundo
    blur_passes = 4              # Suavizado de alta calidad
    blur_size = 7                # Radio del difuminado
    noise = 0.015                # Grano fino minimalista
    contrast = 0.8916            # Ajuste de contraste para el fondo
    brightness = 0.70            # Oscurece la captura para que no moleste a la vista

    # Capa translúcida con tu color base #1e1e2e (80% de opacidad)
    color = rgba(1e1e2ecc)
}

# RELOJ DIGITAL ELEGANTE
label {
    monitor =
    text = cmd[update:1000] echo "$(date +"%H:%M")"
    color = rgba(cdd6f4ff)        # Color 'text' (#cdd6f4)
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
    color = rgba(cdd6f4cc)        # Color 'text' con leve transparencia
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

    # Aplicación estricta de tus colores
    outer_color = rgba(585b70aa)  # Color 'border_inactive' con transparencia
    check_color = rgba(89b4faff)  # Color 'border_active' al procesar
    fail_color = rgba(f38ba8ff)   # Rojo Catppuccin para errores de contraseña
    inner_color = rgba(313244ff)  # Color 'surface' (#313244)
    font_color = rgba(cdd6f4ff)   # Color 'text' (#cdd6f4)

    fade_on_empty = true          # Esconde la caja si no estás escribiendo
    fade_timeout = 1500           # Tiempo antes de desvanecerse (1.5s)
    placeholder_text = <i>Ingresa contraseña / Enter password...</i>
    hide_input = false

    position = 0, -110
    halign = center
    valign = center
}
EOF



echo "$TXT_CONFIG_INSTALLED"

if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    echo "$TXT_RELOADING"
    hyprctl reload
    sleep 1

    ERRORS="$(hyprctl configerrors 2>/dev/null || true)"
    if [ -n "$ERRORS" ] && [ "$ERRORS" != "no errors" ]; then
        echo "=========================================================="
        echo "$TXT_RELOAD_ERRORS"
        echo "$ERRORS"
        echo "$TXT_PREVIOUS_CONFIG_SAFE $BACKUP_DIR"
        echo "=========================================================="
        exit 1
    fi

    echo "$TXT_RELOAD_OK"
else
    echo "$TXT_NO_SESSION"
    echo "$TXT_INSTALLED_WILL_LOAD"
fi

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

# Bloquear pantalla tras 10 minutos (600 segundos)
listener {
    timeout = 600
    on-timeout = loginctl lock-session
}

listener {
    timeout = 660
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
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

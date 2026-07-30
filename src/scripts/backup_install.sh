#!/usr/bin/env bash
set -euo pipefail

# SI NO DETECTA EL IDIOMA, SE CONFIGURA EN INGLES POR DEFECTO
ARCHIVO_LANG="${1:-en.cfg}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LANG_DIR="$PROJECT_ROOT/src/lang"

PATH_TRADUCCION="$LANG_DIR/$ARCHIVO_LANG"
if [ -f "$PATH_TRADUCCION" ]; then
    source "$PATH_TRADUCCION"
fi

HYPR_DIR="$HOME/.config/hypr"
BACKUP_ROOT="$HOME/.config/hypr-backups"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

# Direccion estable
SOURCE_DIR="$PROJECT_ROOT/src/.config/hypr/hyprland"
DEST_DIR="$HYPR_DIR/hyprland"

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: no se encontró SOURCE_DIR en '$SOURCE_DIR'" >&2
    echo "Error: SOURCE_DIR not found in '$SOURCE_DIR'" >&2
    exit 1
fi

echo "=========================================================="
echo "Esto BORRARÁ POR COMPLETO $HYPR_DIR antes de instalar."
echo "Se guardará un backup en $BACKUP_DIR primero."
echo "=========================================================="
echo "=========================================================="
echo "This will COMPLETELY DELETE $HYPR_DIR before installing."
echo "A backup will be saved to $BACKUP_DIR first."
echo "=========================================================="

read -rp "¿Continuar? Escribe 'si' para confirmar / Continue? Type 'yes' to confirm: " confirm
if [ "$confirm" != "si", "yes" ]; then
    echo "Cancelado. No se hizo ningún cambio."
    echo "Cancelled. No changes were made."
    exit 0
fi

echo "Haciendo backup de $HYPR_DIR -> $BACKUP_DIR"
echo "Backing up $HYPR_DIR -> $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
cp -a "$HYPR_DIR/." "$BACKUP_DIR/"
echo "Backup completado / "Backup completed.""

echo "Borrando $HYPR_DIR por completo..."
echo "Deleting $HYPR_DIR completely..."
rm -rf "$HYPR_DIR"
mkdir -p "$HYPR_DIR"
echo "Carpeta limpia / "Folder cleaned.""

echo "Copiando dotfiles de $SOURCE_DIR -> $DEST_DIR"
echo "Copying dotfiles from $SOURCE_DIR -> $DEST_DIR"
mkdir -p "$DEST_DIR"
rsync -a "$SOURCE_DIR/" "$DEST_DIR/"
echo "Dotfiles copiados / Dotfiles copied."

TARGET="$HYPR_DIR/hyprland.lua"
echo "Escribiendo nuevo $TARGET"
echo "Writing new $TARGET"

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

echo "Configuración instalada."

if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    echo "Recargando Hyprland (hyprctl reload)..."
    hyprctl reload
    sleep 1

    ERRORS="$(hyprctl configerrors 2>/dev/null || true)"
    if [ -n "$ERRORS" ] && [ "$ERRORS" != "no errors" ]; then
        echo "=========================================================="
        echo "⚠ Hyprland reportó errores al cargar la nueva config:"
        echo "$ERRORS"
        echo "Tu configuración anterior sigue intacta en: $BACKUP_DIR"
        echo "=========================================================="
        exit 1
    fi

    echo "Recarga exitosa, sin errores reportados."
else
    echo "No se detectó una sesión de Hyprland activa (HYPRLAND_INSTANCE_SIGNATURE vacío)."
    echo "Inicia sesión en Hyprland; la config ya está instalada y se cargará sola."
fi

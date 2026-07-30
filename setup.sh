#!/usr/bin/env bash
set -euo pipefail

# --- 1. CONFIGURACIÓN DE RUTAS ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LANG_DIR="$SCRIPT_DIR/src/lang"

# --- 2. SELECCIÓN DE IDIOMA ---
echo "Selecciona tu idioma / Select your language:"
echo "1) Español (ES)"
echo "2) English (EN)"
read -rp "Opción / Option (1-2): " OPCION_IDIOMA

case "$OPCION_IDIOMA" in
    1) ARCHIVO_LANG="es.cfg" ;;
    2) ARCHIVO_LANG="en.cfg" ;;
    *)
        ARCHIVO_LANG="en.cfg"
        MOSTRAR_AVISO_OPCION_INVALIDA=1
        ;;
esac

# --- 3. CARGAR EL ARCHIVO DE TRADUCCIÓN (.cfg) ---
PATH_TRADUCCION="$LANG_DIR/$ARCHIVO_LANG"

if [ -f "$PATH_TRADUCCION" ]; then
    source "$PATH_TRADUCCION"
else
    echo "Error: No se pudo encontrar el archivo de idioma en $PATH_TRADUCCION"
    exit 1
fi

# Empezamos la instalación de los Minimal Clean Dotfiles.
clear
echo "=========================================================="
echo "$TXT_WELCOME"
echo "=========================================================="
echo ""

if [ "${MOSTRAR_AVISO_OPCION_INVALIDA:-0}" = "1" ]; then
    echo "$TXT_INVALID_OPTION"
    echo ""
fi

sleep 1

# --- 4. BOOTSTRAP DEL SISTEMA (pacman -Syu, paru, sudoers) ---
echo "=========================================================="
echo "$TXT_UPDATING_SYSTEM"
echo "=========================================================="
bash "$SCRIPT_DIR/src/scripts/bootstrap_system.sh" "$ARCHIVO_LANG"
echo ""

# --- 5. INSTALACIÓN DE PAQUETES (categorías definidas en packages.sh) ---
echo "=========================================================="
echo "$TXT_INSTALLING_PACKAGES"
echo "=========================================================="
bash "$SCRIPT_DIR/src/scripts/install_packages.sh" "$ARCHIVO_LANG"
echo ""

# --- 6. CONFIGURACIONES ADICIONALES (foot, y lo que se agregue después) ---
echo "=========================================================="
echo "$TXT_CONFIGS_HEADER"
echo "=========================================================="
bash "$SCRIPT_DIR/src/scripts/install_configs.sh" "$ARCHIVO_LANG"
echo ""

# --- 7. BACKUP + INSTALACIÓN DE LA CONFIG DE HYPRLAND ---
echo "=========================================================="
echo "$TXT_BACKUP"
echo "=========================================================="
echo "=========================================================="
echo "$TXT_COPY_DOTFILES"
echo "=========================================================="
bash "$SCRIPT_DIR/src/scripts/backup_install.sh" "$ARCHIVO_LANG"
echo ""

echo "=========================================================="
echo "$TXT_FINISHED"
echo "=========================================================="
sleep 8

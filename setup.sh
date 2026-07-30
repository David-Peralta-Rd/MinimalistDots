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

if [ "$OPCION_IDIOMA" = "1" ]; then
    ARCHIVO_LANG="es.cfg"
else
    ARCHIVO_LANG="en.cfg"
fi

# --- 3. CARGAR EL ARCHIVO DE TRADUCCIÓN (.cfg) ---
PATH_TRADUCCION="$LANG_DIR/$ARCHIVO_LANG"

if [ -f "$PATH_TRADUCCION" ]; then
    source "$PATH_TRADUCCION"
else
    echo "Error: No se pudo encontrar el archivo de idioma en $PATH_TRADUCCION"
    echo "Error: Could not find the language file at $PATH_TRADUCCION"
    exit 1
fi

# Empezamos la instalación de los Minimal Clean Dotfiles.
clear
echo "=========================================================="
echo "$TXT_WELCOME"
echo "=========================================================="
echo ""
sleep 1
echo "=========================================================="
echo "$TXT_BACKUP"
echo "=========================================================="
echo "=========================================================="
echo "$TXT_COPY_DOTFILES"
echo "=========================================================="

# EJECUTANDO SCRIPT DE BACKUP Y INSTALACION
# Se pasa ARCHIVO_LANG como argumento: las variables cargadas con "source"
# viven solo en este shell, no se heredan a un proceso "bash" hijo.
bash "$SCRIPT_DIR/src/scripts/backup_install.sh" "$ARCHIVO_LANG"

echo ""
sleep 8

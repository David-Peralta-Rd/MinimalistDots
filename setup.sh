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

# Si la opción no fue válida, avisamos DESPUÉS de cargar el .cfg,
# para que el aviso mismo ya esté en el idioma correcto (inglés, en este caso).
if [ "${MOSTRAR_AVISO_OPCION_INVALIDA:-0}" = "1" ]; then
    echo "$TXT_INVALID_OPTION"
    echo ""
fi

sleep 1
echo "=========================================================="
echo "$TXT_BACKUP"
echo "=========================================================="
echo "=========================================================="
echo "$TXT_COPY_DOTFILES"
echo "=========================================================="

# EJECUTANDO SCRIPT DE BACKUP Y INSTALACION
bash "$SCRIPT_DIR/src/scripts/backup_install.sh" "$ARCHIVO_LANG"

echo ""
echo "=========================================================="
echo "$TXT_FINISHED"
echo "=========================================================="
sleep 8

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
    echo "Error: No se pudo encontrar el archivo de idioma en $PATH_TRADUCCION" >&2
    exit 1
fi

# Inicio de la instalación
clear
echo "=========================================================="
echo "${TXT_WELCOME:-Welcome / Bienvenido}"
echo "=========================================================="
echo ""

if [ "${MOSTRAR_AVISO_OPCION_INVALIDA:-0}" = "1" ]; then
    echo "${TXT_INVALID_OPTION:-Option invalid, using English by default.}"
    echo ""
fi

sleep 1

# --- 4. BACKUP Y LIMPIEZA PREVIA ---
echo "=========================================================="
echo "${TXT_BACKUP_DOING:-Iniciando proceso de respaldo y preparación...}"
echo "=========================================================="
bash "$SCRIPT_DIR/src/scripts/backup_and_clean.sh" "$ARCHIVO_LANG"
echo ""

# --- 5. GENERACIÓN DEL MÓDULO DE COLORES ---
echo "=========================================================="
echo "${TXT_COLORS_INSTALLING:-Generando paleta de colores...}"
echo "=========================================================="
bash "$SCRIPT_DIR/src/scripts/colors.sh" "$ARCHIVO_LANG"
echo ""

# --- 6. INSTALANDO PAQUETES Y ARCHIVOS DE HYPRLAND ---
echo "=========================================================="
echo "${TXT_INSTALLING_HYPR:-Instalando componentes de Hyprland...}"
echo "=========================================================="
bash "$SCRIPT_DIR/src/scripts/install_hypr.sh" "$ARCHIVO_LANG"
echo ""

# --- 7. INSTALANDO APLICACIONES Y MÓDULOS COMPLEJOS ---
echo "=========================================================="
echo "${TXT_INSTALLING_COMPLEX:-Instalando aplicaciones y utilidades adicionales...}"
echo "=========================================================="
bash "$SCRIPT_DIR/src/scripts/install_complex.sh" "$ARCHIVO_LANG"
echo ""

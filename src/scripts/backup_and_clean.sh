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

echo "=========================================================="
echo "${TXT_CONFIRM_WARNING1:-Atención: Se limpiará la configuración actual de Hyprland en:} $HYPR_DIR"
echo "${TXT_CONFIRM_WARNING2:-Se creará una copia de respaldo en:} $BACKUP_DIR"
echo "=========================================================="

read -rp "${TXT_CONFIRM_PROMPT:-¿Deseas continuar? (s/n): }" confirm
if [ "$confirm" != "${TXT_CONFIRM_WORD:-s}" ]; then
    echo "${TXT_CANCELLED:-Operación cancelada por el usuario.}"
    exit 0
fi

# 1. Realizar Backup (solo si la carpeta de Hyprland existe y no está vacía)
if [ -d "$HYPR_DIR" ] && [ "$(ls -A "$HYPR_DIR")" ]; then
    echo "${TXT_BACKUP_DOING:-Creando copia de respaldo...} $HYPR_DIR -> $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    cp -a "$HYPR_DIR/." "$BACKUP_DIR/"
    echo "${TXT_BACKUP_DONE:-Respaldo completado con éxito.}"
else
    echo "No se encontró configuración previa en $HYPR_DIR, omitiendo respaldo."
fi

# 2. Limpiar directorio ~/.config/hypr
echo "${TXT_CLEANING:-Limpiando directorio objetivo...}"
rm -rf "$HYPR_DIR"
mkdir -p "$HYPR_DIR"
echo "${TXT_CLEANING_DONE:-Directorio listo para recibir la nueva configuración.}"
echo ""

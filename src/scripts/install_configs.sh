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

SOURCE_CONFIGS_DIR="$PROJECT_ROOT/src/.config"
DEST_CONFIGS_DIR="$HOME/.config"
BACKUP_ROOT="$HOME/.config/backups_dots/config-backups/$(date +%Y%m%d_%H%M%S)"

# "hypr" tiene su propio flujo completo en backup_install.sh -- se excluye
# aquí para no duplicar backups ni chocar con esa lógica.
EXCLUDED=("hypr")

if [ ! -d "$SOURCE_CONFIGS_DIR" ]; then
    echo "$TXT_CONFIGS_NOT_FOUND $SOURCE_CONFIGS_DIR" >&2
    exit 1
fi

# Descubre subcarpetas dentro de src/.config/, excluyendo las de $EXCLUDED
shopt -s nullglob
ALL_DIRS=("$SOURCE_CONFIGS_DIR"/*/)
shopt -u nullglob

APPS=()
for dir in "${ALL_DIRS[@]}"; do
    name="$(basename "$dir")"
    skip=0
    for ex in "${EXCLUDED[@]}"; do
        [ "$name" = "$ex" ] && skip=1 && break
    done
    [ "$skip" -eq 0 ] && APPS+=("$name")
done

if [ ${#APPS[@]} -eq 0 ]; then
    echo "$TXT_CONFIGS_NOT_FOUND $SOURCE_CONFIGS_DIR"
    exit 0
fi

echo "=========================================================="
echo "$TXT_CONFIGS_HEADER (${#APPS[@]}: ${APPS[*]})"
echo "=========================================================="
read -rp "$TXT_CONFIGS_CONFIRM ($TXT_CONFIRM_WORD/n): " confirm
if [ "$confirm" != "$TXT_CONFIRM_WORD" ]; then
    echo "$TXT_CANCELLED"
    exit 0
fi

for app in "${APPS[@]}"; do
    SRC="$SOURCE_CONFIGS_DIR/$app"
    DEST="$DEST_CONFIGS_DIR/$app"

    if [ -d "$DEST" ]; then
        echo "$TXT_CONFIG_BACKUP $app -> $BACKUP_ROOT/$app"
        mkdir -p "$BACKUP_ROOT"
        cp -a "$DEST" "$BACKUP_ROOT/$app"

        echo "$TXT_CONFIG_REMOVING $DEST"
        rm -rf "$DEST"
    else
        echo "$TXT_CONFIG_NEW $app"
    fi

    echo "$TXT_CONFIG_COPYING $SRC -> $DEST"
    mkdir -p "$DEST"
    rsync -a "$SRC/" "$DEST/"
done

echo "$TXT_CONFIGS_DONE"

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

# Nota: los paquetes de packages.sh ya se instalan en install_hypr.sh,
# por eso aquí solo se ejecutan los módulos de complex_install/ (no se repite paru).

# 1. Ejecutar instalaciones complejas / módulos personalizados
COMPLEX_DIR="$SCRIPT_DIR/complex_install"
if [ -d "$COMPLEX_DIR" ]; then
    shopt -s nullglob
    COMPLEX_SCRIPTS=("$COMPLEX_DIR"/*.sh)
    shopt -u nullglob

    for script in "${COMPLEX_SCRIPTS[@]}"; do
        NAME="$(basename "$script" .sh)"
        echo "=========================================================="
        echo "${TXT_COMPLEX_RUNNING:-Ejecutando módulo:} $NAME"
        echo "=========================================================="
        bash "$script" "$ARCHIVO_LANG"
    done
fi

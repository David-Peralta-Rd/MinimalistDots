#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Si el subscript se ejecuta solo (sin pasar por setup.sh), carga el idioma guardado
if [ -z "${TXT_WELCOME:-}" ]; then
    source "$SRC_DIR/load_lang.sh"
fi







# 1. Ejecutar instalaciones complejas / módulos personalizados
COMPLEX_DIR="$SRC_DIR/complex_install"
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

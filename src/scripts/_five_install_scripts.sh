#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Si el subscript se ejecuta solo (sin pasar por setup.sh), carga el idioma guardado
if [ -z "${TXT_WELCOME:-}" ]; then
    # Subimos un nivel con ".." para salir de "scripts/" y entrar a "src/"
    LANG_LOADER="$SRC_DIR/../lang/load_lang.sh"
    if [ -f "$LANG_LOADER" ]; then
        source "$LANG_LOADER"
    else
        echo "Aviso: No se pudo encontrar el archivo de idioma en $LANG_LOADER"
    fi
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

        # <-- AQUÍ ESTABA EL DETALLE: Ejecutamos el script de forma nativa
        bash "$script"

        # O si prefieres que compartan las mismas variables de entorno del script principal:
        # source "$script"
    done
fi

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../utils/u3_env.sh"

# Instala catálogos sin borrar idiomas adicionales y siembra la elección inicial.
if [ ! -d "$MD_LANGUAGE_SRC" ]; then
    echo "$T_CONFIGURACION_NO_ENCONTRADA $MD_LANGUAGE_SRC" >&2
    exit 1
fi

mkdir -p "$MD_LANGUAGE_DIR"
shopt -s nullglob
catalogs=("$MD_LANGUAGE_SRC"/*.cfg)
shopt -u nullglob
if [ "${#catalogs[@]}" -eq 0 ]; then
    echo "$T_CONFIGURACION_NO_ENCONTRADA $MD_LANGUAGE_SRC" >&2
    exit 1
fi
cp -f "${catalogs[@]}" "$MD_LANGUAGE_DIR/"

locale="es"
if [[ "${SELECTED_LANG:-}" =~ ^lg([1-9][0-9]*)_([A-Za-z]+(?:_[A-Za-z]+)*)_([A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})?)\.cfg$ ]]; then
    locale="${BASH_REMATCH[3],,}"
fi

"$MD_SCRIPTS_DIR/language_selector.sh" --seed "$locale"
echo "$T_IDIOMA_ENTORNO_INSTALADO $MD_LANGUAGE_DIR"

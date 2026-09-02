#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LANG_DIR="$SRC_DIR/src/lang"

# Carga la configuración de idioma
source "$SRC_DIR/load_lang.sh"

# Cargando instalacion por pasos:
bash "$SRC_DIR/src/scripts/steps.sh"

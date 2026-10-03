#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DIR="$ROOT_DIR/src/setup"

# Cada instalación nueva vuelve a preguntar el idioma
# (si no, una elección vieja en /tmp se reutilizaría hasta reiniciar el equipo)
rm -f /tmp/.current_lang

# Carga la configuración de idioma
source "$SETUP_DIR/lang/load_lang.sh"

# Cargando instalacion por pasos:
bash "$SETUP_DIR/scripts/steps.sh"

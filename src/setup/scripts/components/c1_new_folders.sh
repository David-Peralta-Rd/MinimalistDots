#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/u3_env.sh"


# ============================== #
# ==== CREACION DE CARPETAS ==== #
# ============================== #
# LISTA DE DIRECTORIOS (todas las rutas salen de utils/u3_env.sh)
DIRECTORIES=(
    "$MD_HYPR_DIR/hyprland"
    "$MD_SCRIPTS_DIR"
    "$MD_SERVICES_DIR"
    "$MD_WOFI_CONFIGS"
    "$MD_WOFI_THEMES"
    "$MD_WOFI_LAUNCHER_DIR"
    "$HOME/.cache/hypr"
)

# CREAMOS CARPETAS USANDO UN BUCLE
for dir in "${DIRECTORIES[@]}"; do
    echo "$T_NOMBRE_DE_CARPETA '${dir#"$HOME"/}'"
    mkdir -p "$dir"
done

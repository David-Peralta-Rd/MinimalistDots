#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LANG_DIR="$(cd "$SCRIPT_DIR/../../lang" && pwd)"

# CARGAR EL IDIOMA SI EL SCRIPT SE EJECUTA DIRECTAMENTE
if [ -z "${T_BIENVENIDO:-}" ]; then
    source "$LANG_DIR/load_lang.sh"
fi

# ============================== #
# ==== CREACION DE CARPETAS ==== #
# ============================== #
# LISTA DE DIRECTORIES
DIRECTORIES=(
    ".config/kitty"
    ".config/hypr/hyprland"
    ".local/bin/MinimalistDots/scripts"
    ".local/bin/MinimalistDots/services"
)

# CREAMOS CARPETAS USANDO UN BUCLE
for sub_dir in "${DIRECTORIES[@]}"; do
    # $HOME se expande automáticamente a /home/tu_usuario
    echo "$T_NOMBRE_DE_CARPETA '$sub_dir'"
    mkdir -p "$HOME/$sub_dir"
done

#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Si el subscript se ejecuta solo (sin pasar por setup.sh), carga el idioma guardado
if [ -z "${TXT_WELCOME:-}" ]; then
    source "$SRC_DIR/load_lang.sh"
fi

# ============================== #
# ==== CREACION DE CARPETAS ==== #
# ============================== #

# LISTA DE DIRECTORIES
DIRECTORIES=(
    ".config/hypr"
    ".config/hypr/custom"
    ".config/alacritty"
    ".config/hypr/hyprland"
    ".local/bin/minimalist_dots"
    ".local/bin/minimalist_dots/scripts"
    ".local/bin/minimalist_dots/services"
)

# 2. Recorre la lista y crea las carpetas en el HOME del usuario actual
echo "${TXT_NEW_DIRS:-New folders / Nuevas carpetas}"
for sub_dir in "${DIRECTORIES[@]}"; do
    # $HOME se expande automáticamente a /home/tu_usuario
    mkdir -p "$HOME/$sub_dir"
done

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

source "$SCRIPT_DIR/packages.sh"

if [ ${#ALL_PKGS[@]} -eq 0 ]; then
    echo "$TXT_NO_PACKAGES"
    exit 0
fi

echo "=========================================================="
echo "$TXT_INSTALLING_PACKAGES ${#ALL_PKGS[@]}"
echo "=========================================================="
paru -S --needed --noconfirm "${ALL_PKGS[@]}"
echo "$TXT_PACKAGES_DONE"

# --- Instalaciones complejas: cosas que necesitan más que "paru -S" ---
COMPLEX_DIR="$SCRIPT_DIR/complex_installs"
if [ -d "$COMPLEX_DIR" ]; then
    shopt -s nullglob
    COMPLEX_SCRIPTS=("$COMPLEX_DIR"/*.sh)
    shopt -u nullglob

    for script in "${COMPLEX_SCRIPTS[@]}"; do
        NAME="$(basename "$script" .sh)"
        echo "=========================================================="
        echo "$TXT_COMPLEX_RUNNING $NAME"
        echo "=========================================================="
        bash "$script"
    done
fi

echo "$TXT_ENABLING_SDDM"
sudo systemctl enable sddm

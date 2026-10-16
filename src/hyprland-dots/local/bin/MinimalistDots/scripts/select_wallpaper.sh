#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR="$HOME/multimedia/pictures/wallpapers"
STATE_FILE="$HOME/.cache/hypr/current_wallpaper"
MD_MENU="$(dirname "$(readlink -f "$0")")/md_menu"

mkdir -p "$WALLPAPER_DIR" "$(dirname "$STATE_FILE")"

# Cada línea: "nombre<TAB>ruta" -> md_menu muestra la miniatura y devuelve solo el nombre
SELECTED_NAME="$(
    find "$WALLPAPER_DIR" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -printf '%f\t%p\n' |
    sort |
    "$MD_MENU" wallpaper --prompt "Fondo de pantalla" || true
)"

[ -z "$SELECTED_NAME" ] && exit 0

FULL_PATH="$WALLPAPER_DIR/$SELECTED_NAME"
hyprctl hyprpaper wallpaper ",$FULL_PATH,fill"
echo "$FULL_PATH" > "$STATE_FILE"

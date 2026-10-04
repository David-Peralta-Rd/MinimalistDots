#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR="$HOME/multimedia/pictures/wallpapers"
STATE_FILE="$HOME/.cache/hypr/current_wallpaper"

mkdir -p "$WALLPAPER_DIR" "$(dirname "$STATE_FILE")"

# Modo de selección: --random para inicio automático, vacío para Wofi manual
MODE="${1:-manual}"

if [ "$MODE" = "--random" ]; then
    # Obtener lista de imágenes e identificar una al azar usando shuf
    FULL_PATH="$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | shuf -n 1)"
else
    # Selección interactiva con Wofi
    SELECTED_NAME="$(
        find "$WALLPAPER_DIR" -maxdepth 1 -type f \
            \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -printf '%f\n' |
        while read -r name; do
            printf "%s\x00icon\x1f%s/%s\n" "$name" "$WALLPAPER_DIR" "$name"
        done |
        wofi --show dmenu --prompt "Fondo de pantalla" --allow-images
    )"

    [ -z "${SELECTED_NAME:-}" ] && exit 0
    FULL_PATH="$WALLPAPER_DIR/$SELECTED_NAME"
fi

# Validar que exista un archivo seleccionado antes de aplicar
if [ -n "${FULL_PATH:-}" ] && [ -f "$FULL_PATH" ]; then
    hyprctl hyprpaper unload all
    hyprctl hyprpaper preload "$FULL_PATH"
    hyprctl hyprpaper wallpaper ",$FULL_PATH,fill"
    echo "$FULL_PATH" > "$STATE_FILE"
fi

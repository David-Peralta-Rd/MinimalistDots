#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR="$HOME/pictures/wallpapers"
STATE_FILE="$HOME/.cache/hypr/current_wallpaper"

mkdir -p "$WALLPAPER_DIR" "$(dirname "$STATE_FILE")"

SELECTED_NAME="$(
    find "$WALLPAPER_DIR" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -printf '%f\n' |
    while read -r name; do
        printf '%s\0icon\x1f%s\n' "$name" "$WALLPAPER_DIR/$name"
    done |
    wofi --show dmenu --prompt "Fondo de pantalla"
)"

[ -z "$SELECTED_NAME" ] && exit 0

FULL_PATH="$WALLPAPER_DIR/$SELECTED_NAME"
hyprctl hyprpaper wallpaper ",$FULL_PATH,fill"
echo "$FULL_PATH" > "$STATE_FILE"

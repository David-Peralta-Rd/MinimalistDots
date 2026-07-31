#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
STATE_FILE="$HOME/.cache/hypr/current_wallpaper"

mkdir -p "$WALLPAPER_DIR" "$(dirname "$STATE_FILE")"

SELECTED="$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) \
    -printf '%f\n' | hyprlauncher --dmenu)"

# Si el usuario cierra el picker sin elegir nada, no hacemos nada
[ -z "$SELECTED" ] && exit 0

FULL_PATH="$WALLPAPER_DIR/$SELECTED"
hyprctl hyprpaper wallpaper ",$FULL_PATH,fill"
echo "$FULL_PATH" > "$STATE_FILE"

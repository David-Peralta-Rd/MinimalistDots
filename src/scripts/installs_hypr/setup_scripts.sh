#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LANG_FILE="${1:-es.cfg}"
PATH_TRADUCCION="$SCRIPT_DIR/lang/$LANG_FILE"

if [[ -f "$PATH_TRADUCCION" ]]; then
    source "$PATH_TRADUCCION"
fi

echo "=========================================================="
echo "${TXT_SCRIPTS_INSTALLING:-Instalando scripts auxiliares de Hyprland...}"
echo "=========================================================="

SCRIPTS_DIR="$HOME/.config/hypr/hyprland/scripts"
mkdir -p "$SCRIPTS_DIR"

# vars.lua apunta a este script (vars.select_wallpaper), lo generamos aquí.
cat << 'EOF' > "$SCRIPTS_DIR/select_wallpaper.sh"
#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR="$HOME/multimedia/pictures/wallpapers"
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
EOF

chmod +x "$SCRIPTS_DIR/select_wallpaper.sh"

echo "${TXT_SCRIPTS_OK:-Scripts auxiliares instalados correctamente.}"
echo ""

#!/usr/bin/env bash
set -euo pipefail

# 1. Rutas y carga de idioma
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LANG_FILE="${1:-es.cfg}"
PATH_TRADUCCION="$SCRIPT_DIR/lang/$LANG_FILE"

if [[ -f "$PATH_TRADUCCION" ]]; then
    source "$PATH_TRADUCCION"
fi

echo "=========================================================="
echo "${TXT_VARS_INSTALLING:-Generando variables de aplicaciones...}"
echo "=========================================================="

HYPR_VARS_DIR="$HOME/.config/hypr/hyprland"
mkdir -p "$HYPR_VARS_DIR"

# 2. Generar ~/.config/hypr/hyprland/vars.lua
cat << EOF > "$HYPR_VARS_DIR/vars.lua"
---------------------
---- MY PROGRAMS ----
---------------------

local HOME = os.getenv("HOME")

return {
    -- Fast Execution
    terminal        = "footclient",
    fileManager     = "dolphin",
    menu            = "wofi",
    browser         = "brave",
    mainMod         = "SUPER",
    editor          = "code",

    -- Complex Execution
    cliphist        = "cliphist list | wofi -c " .. HOME .. "/.config/wofi/configs/config-clipboard -s " .. HOME .. "/.config/wofi/themes/style-clipboard.css --dmenu | cliphist decode | wl-copy",
    screenshot      = HOME .. "/.local/bin/minimaldots/screenshot.sh",
    select_wallpaper = HOME .. "/.config/hypr/hyprland/scripts/select_wallpaper.sh",
    show_binds      = HOME .. "/.local/bin/minimaldots/show_binds",
    hyprlock        = "loginctl lock-session",
    screenrecord    = HOME .. "/.local/bin/minimaldots/screenrecord.sh",
    process_manager = HOME .. "/.local/bin/minimaldots/process_manager.sh"
}
EOF

echo "${TXT_VARS_OK:-Archivo vars.lua creado con éxito.}"
echo ""

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../utils/u3_env.sh"

# c3 pasa HYPR_DIR; si el script se ejecuta solo, usa ~/.config/hypr
HYPR_DIR="${HYPR_DIR:-$MD_HYPR_DIR}"
TARGET="$HYPR_DIR/hyprlock.conf"
mkdir -p "$(dirname "$TARGET")"

cat > "$TARGET" <<'EOF'
general {
    disable_loading_bar = true
    hide_cursor = true
    grace = 0
    no_fade_in = false
}
background {
    monitor =
    path = screenshot
    blur_passes = 4
    blur_size = 7
    noise = 0.015
    contrast = 0.8916
    brightness = 0.70
    color = rgba(1e1e2ecc)
}
label {
    monitor =
    text = cmd[update:1000] echo "$(date +"%H:%M")"
    color = rgba(cdd6f4ff)
    font_size = 80
    font_family = JetBrains Mono Nerd Font Bold
    position = 0, 180
    halign = center
    valign = center
}
label {
    monitor =
    text = Hola, $USER
    color = rgba(cdd6f4cc)
    font_size = 14
    font_family = JetBrains Mono Nerd Font Regular
    position = 0, -40
    halign = center
    valign = center
}
input-field {
    monitor =
    size = 250, 45
    outline_thickness = 2
    dots_size = 0.22
    dots_spacing = 0.35
    dots_center = true
    outer_color = rgba(585b70aa)
    check_color = rgba(89b4faff)
    fail_color = rgba(f38ba8ff)
    inner_color = rgba(313244ff)
    font_color = rgba(cdd6f4ff)
    fade_on_empty = true
    fade_timeout = 1500
    placeholder_text = <i>Ingresa contraseña / Enter password...</i>
    hide_input = false
    position = 0, -110
    halign = center
    valign = center
}
EOF

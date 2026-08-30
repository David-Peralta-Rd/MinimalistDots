#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Si el subscript se ejecuta solo (sin pasar por setup.sh), carga el idioma guardado
if [ -z "${TXT_WELCOME:-}" ]; then
    source "$SRC_DIR/load_lang.sh"
fi


# Paleta global de colores
PALETTE_FILE="$PROJECT_ROOT/src/colors/palette.sh"
if [ -f "$PALETTE_FILE" ]; then
    source "$PALETTE_FILE"
else
    RAW_BG="1e222a"
    RAW_TEXT="abb2bf"
fi


IMV_DIR="$HOME/.config/imv"
MPV_DIR="$HOME/.config/mpv"
mkdir -p "$IMV_DIR" "$MPV_DIR"

echo "==> Aplicando configuración base para imv y mpv..."
cat > "$IMV_DIR/config" << EOF
[options]
background = ${RAW_BG}
overlay_font = JetBrains Mono:9
scaling_mode = shrink
EOF

cat > "$MPV_DIR/mpv.conf" << EOF
border=no
force-window=yes
save-position-on-quit=yes
osd-color=#${RAW_TEXT}
osd-border-color=#${RAW_BG}
osd-font-size=14
EOF

echo "==> Aplicando Tema Oscuro GTK e Iconos para Thunar..."
# Si ejecutas en un entorno XFCE, se aplica mediante xfconf-query
if command -v xfconf-query &>/dev/null; then
    xfconf-query -c xsettings -p /Net/ThemeName -s "Arc-Dark" 2>/dev/null || true
    xfconf-query -c xsettings -p /Net/IconThemeName -s "Papirus-Dark" 2>/dev/null || true
    xfconf-query -c xsettings -p /Gtk/PreferDarkTheme -s 1 2>/dev/null || true
fi

# Forzar tema oscuro en entornos GTK genéricos (WMs como i3, bspwm, Hyprland, etc.)
GTK3_DIR="$HOME/.config/gtk-3.0"
mkdir -p "$GTK3_DIR"
cat > "$GTK3_DIR/settings.ini" << EOF
[Settings]
gtk-theme-name=Arc-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-application-prefer-dark-theme=1
EOF

echo "==> Asociando imv y mpv como visores predeterminados (XDG)..."
xdg-mime default imv.desktop image/jpeg image/png image/gif image/webp image/bmp
xdg-mime default mpv.desktop video/mp4 video/x-matroska video/webm video/avi video/quicktime

echo "==> Reiniciando Tumbler (demonio de miniaturas de Thunar)..."
killall tumblerd 2>/dev/null || true

echo "==> Configuración de Thunar completada."

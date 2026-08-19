#!/usr/bin/env bash
set -euo pipefail

ARCHIVO_LANG="${1:-en.cfg}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LANG_DIR="$PROJECT_ROOT/src/lang"

[ -f "$LANG_DIR/$ARCHIVO_LANG" ] && source "$LANG_DIR/$ARCHIVO_LANG"

echo "==> Instalando Dolphin, tema oscuro Breeze y plugins de previsualización..."
paru -S --needed --noconfirm \
    dolphin breeze breeze-icons ffmpegthumbs \
    kdegraphics-thumbnailers kimageformats resvg \
    archiver ark imv mpv

IMV_DIR="$HOME/.config/imv"
MPV_DIR="$HOME/.config/mpv"
mkdir -p "$IMV_DIR" "$MPV_DIR"

echo "==> Aplicando configuración base para imv y mpv..."
cat > "$IMV_DIR/config" << 'EOF'
[options]
background = 1e1e2e
overlay_font = JetBrains Mono:9
scaling_mode = shrink
EOF

cat > "$MPV_DIR/mpv.conf" << 'EOF'
border=no
force-window=yes
save-position-on-quit=yes
osd-color=#cdd6f4
osd-border-color=#1e1e2e
osd-font-size=14
EOF

echo "==> Aplicando Tema Oscuro en KDE/Qt..."
kwriteconfig6 --file kdeglobals --group General --key ColorScheme "BreezeDark" 2>/dev/null || true
kwriteconfig6 --file kdeglobals --group Icons --key Theme "breeze-dark" 2>/dev/null || true
kwriteconfig6 --file kdeglobals --group "KDE" --key "widgetStyle" "Breeze" 2>/dev/null || true

echo "==> Asociando imv y mpv como visores predeterminados (XDG)..."
xdg-mime default imv.desktop image/jpeg image/png image/gif image/webp image/bmp
xdg-mime default mpv.desktop video/mp4 video/x-matroska video/webm video/avi video/quicktime

echo "==> Habilitando miniaturas en Dolphin..."
kwriteconfig6 --file dolphinrc --group PreviewSettings --key Plugins "ffmpegthumbs,imagethumbs,jpegthumbs,svgthumbnail,pdfthumbnail,directorythumbnail" 2>/dev/null || true

echo "==> Configuración de Dolphin completada."

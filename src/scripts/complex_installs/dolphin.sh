#!/usr/bin/env bash
set -euo pipefail

echo "==> Instalando Dolphin y plugins de miniaturas/previews"
paru -S --needed --noconfirm \
    dolphin \
    ffmpegthumbs \
    kdegraphics-thumbnailers \
    kdrosholes-thumbnailers \
    kimageformats \
    resvg \
    archiver \
    ark \
    imv \
    mpv

IMV_DIR="$HOME/.config/imv"
MPV_DIR="$HOME/.config/mpv"
mkdir -p "$IMV_DIR" "$MPV_DIR"

echo "==> Configurando imv y mpv"
cat > "$IMV_DIR/config" << 'EOF'
[options]
background = 1e1e2e
overlay_font = JetBrains Mono:16
scaling_mode = shrink
EOF

cat > "$MPV_DIR/mpv.conf" << 'EOF'
border=no
force-window=yes
save-position-on-quit=yes
osd-color=#cdd6f4
osd-border-color=#1e1e2e
osd-font-size=28
EOF

echo "==> Asociando imv (imágenes) y mpv (videos) a nivel de sistema (XDG)"
xdg-mime default imv.desktop image/jpeg image/png image/gif image/webp image/bmp
xdg-mime default mpv.desktop video/mp4 video/x-matroska video/webm video/avi video/quicktime

echo "==> Habilitando miniaturas por defecto en Dolphin"
kwriteconfig5 --file dolphinrc --group PreviewSettings --key Plugins "ffmpegthumbs,imagethumbs,jpegthumbs,svgthumbnail,pdfthumbnail,directorythumbnail" 2>/dev/null || \
kwriteconfig6 --file dolphinrc --group PreviewSettings --key Plugins "ffmpegthumbs,imagethumbs,jpegthumbs,svgthumbnail,pdfthumbnail,directorythumbnail" 2>/dev/null || true

echo "Dolphin, imv y mpv configurados con éxito."

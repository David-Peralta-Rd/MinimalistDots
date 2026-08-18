#!/usr/bin/env bash
set -euo pipefail

echo "==> Instalando Dolphin, tema oscuro Breeze y plugins de previews"
paru -S --needed --noconfirm \
    dolphin \
    breeze \
    breeze-icons \
    ffmpegthumbs \
    kdegraphics-thumbnailers \
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

echo "==> Aplicando Tema Oscuro para Dolphin (KDE/Qt)"
# Aplica el esquema de color oscuro y el tema de iconos Breeze Dark en kdeglobals
kwriteconfig6 --file kdeglobals --group General --key ColorScheme "BreezeDark" 2>/dev/null || \
kwriteconfig5 --file kdeglobals --group General --key ColorScheme "BreezeDark" 2>/dev/null || true

kwriteconfig6 --file kdeglobals --group Icons --key Theme "breeze-dark" 2>/dev/null || \
kwriteconfig5 --file kdeglobals --group Icons --key Theme "breeze-dark" 2>/dev/null || true

# Forzar a aplicaciones Qt a preferir tema oscuro a nivel de entorno
kwriteconfig6 --file kdeglobals --group "KDE" --key "widgetStyle" "Breeze" 2>/dev/null || \
kwriteconfig5 --file kdeglobals --group "KDE" --key "widgetStyle" "Breeze" 2>/dev/null || true

echo "==> Asociando imv (imágenes) y mpv (videos) a nivel de sistema (XDG)"
xdg-mime default imv.desktop image/jpeg image/png image/gif image/webp image/bmp
xdg-mime default mpv.desktop video/mp4 video/x-matroska video/webm video/avi video/quicktime

echo "==> Habilitando miniaturas por defecto en Dolphin"
kwriteconfig6 --file dolphinrc --group PreviewSettings --key Plugins "ffmpegthumbs,imagethumbs,jpegthumbs,svgthumbnail,pdfthumbnail,directorythumbnail" 2>/dev/null || \
kwriteconfig5 --file dolphinrc --group PreviewSettings --key Plugins "ffmpegthumbs,imagethumbs,jpegthumbs,svgthumbnail,pdfthumbnail,directorythumbnail" 2>/dev/null || true

echo "Dolphin, imv y mpv configurados con tema oscuro con éxito."

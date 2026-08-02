#!/usr/bin/env bash
set -euo pipefail

echo "==> Instalando yazi y dependencias de preview"
paru -S --needed --noconfirm \
    yazi \
    ffmpegthumbnailer \
    poppler \
    fd \
    ripgrep \
    fzf \
    zoxide \
    jq \
    ouch \
    udisks2 \
    imv \
    mpv

YAZI_DIR="$HOME/.config/yazi"
IMV_DIR="$HOME/.config/imv"
MPV_DIR="$HOME/.config/mpv"
mkdir -p "$YAZI_DIR" "$IMV_DIR" "$MPV_DIR"

echo "==> Instalando plugin oficial de montaje de discos (udisksctl)"
ya pkg add yazi-rs/plugins:mount || true

echo "==> Escribiendo keymap.toml (WASD + Suprimir + plugin de montaje)"
cat > "$YAZI_DIR/keymap.toml" << 'EOF'
# :schema https://yazi-rs.github.io/schemas/keymap.json

[mgr]
prepend_keymap = [
    # --- Controles clásicos WASD (se suman a hjkl y flechas, no las reemplaza) ---
    { on = "w", run = "arrow prev", desc = "Archivo anterior (arriba)" },
    { on = "s", run = "arrow next", desc = "Archivo siguiente (abajo)" },
    { on = "a", run = "leave", desc = "Carpeta padre (atrás)" },
    { on = "d", run = "enter", desc = "Entrar a carpeta / abrir archivo" },

    # --- Eliminar con la tecla Suprimir ---
    { on = "<Delete>", run = "remove", desc = "Enviar a la papelera" },
    { on = "<S-Delete>", run = "remove --permanently", desc = "Eliminar permanentemente" },

    # --- Montaje de USB/discos ---
    { on = "M", run = "plugin mount", desc = "Menú de montaje de discos" },
]
EOF

echo "==> Escribiendo yazi.toml (abrir imágenes con imv, videos con mpv)"
cat > "$YAZI_DIR/yazi.toml" << 'EOF'
# :schema https://yazi-rs.github.io/schemas/yazi.json

[opener]
image = [
    { run = 'imv "$@"', desc = "imv", orphan = true, for = "unix" },
]
play = [
    { run = 'mpv --force-window "$@"', desc = "mpv", orphan = true, for = "unix" },
]

[open]
prepend_rules = [
    { mime = "image/*", use = "image" },
    { mime = "video/*", use = "play" },
]
EOF

echo "==> Escribiendo config de imv (colores + modo de escalado)"
cat > "$IMV_DIR/config" << 'EOF'
[options]
background = 1e1e2e
overlay_font = JetBrains Mono:16
scaling_mode = shrink
EOF

echo "==> Escribiendo mpv.conf (sin bordes + colores del OSD)"
cat > "$MPV_DIR/mpv.conf" << 'EOF'
border=no
force-window=yes
save-position-on-quit=yes
osd-color=#cdd6f4
osd-border-color=#1e1e2e
osd-font-size=28
EOF

echo "Yazi, imv y mpv configurados."

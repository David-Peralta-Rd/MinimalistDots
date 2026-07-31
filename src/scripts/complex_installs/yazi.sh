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
    udisks2

YAZI_DIR="$HOME/.config/yazi"
mkdir -p "$YAZI_DIR"

echo "==> Instalando plugin oficial de montaje de discos (udisksctl)"
ya pkg add yazi-rs/plugins:mount || true

echo "==> Escribiendo keymap.toml (WASD + Suprimir + plugin de montaje)"
cat > "$YAZI_DIR/keymap.toml" << 'EOF'
#"schema" = "https://yazi-rs.github.io/schemas/keymap.json"

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

echo "Yazi configurado."

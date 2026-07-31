#!/usr/bin/env bash
set -euo pipefail

ARCHIVO_LANG="${1:-en.cfg}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LANG_DIR="$PROJECT_ROOT/src/lang"
HYPRPAPER_DIR="/home/$USER/.config/hyprpaper"

PATH_TRADUCCION="$LANG_DIR/$ARCHIVO_LANG"
if [ -f "$PATH_TRADUCCION" ]; then
    source "$PATH_TRADUCCION"
else
    echo "Error: no se pudo encontrar el archivo de idioma en $PATH_TRADUCCION" >&2
    exit 1
fi

# --- 1. Evitar "partial upgrade": sincroniza Y actualiza juntos ---
echo "$TXT_UPDATING_SYSTEM"
sudo pacman -Syu --noconfirm

# --- 2. paru viene empaquetado en los repos de CachyOS, se instala directo ---
if ! command -v paru >/dev/null 2>&1; then
    echo "$TXT_INSTALLING_PARU"
    sudo pacman -S --needed --noconfirm paru
else
    echo "$TXT_PARU_ALREADY"
fi

# --- 3. Configuración de paru (idempotente: no duplica si ya existe) ---
if ! grep -qxF "BottomUp" /etc/paru.conf 2>/dev/null; then
    echo "BottomUp" | sudo tee -a /etc/paru.conf >/dev/null
fi

# --- 4. sudoers vía archivo en sudoers.d, NO editando /etc/sudoers directo ---
SUDOERS_DROPIN="/etc/sudoers.d/99-minimalclean"
if [ ! -f "$SUDOERS_DROPIN" ]; then
    echo "$TXT_CREATING_SUDOERS $SUDOERS_DROPIN"
    TMP_SUDOERS="$(mktemp)"
    printf '# Personalizado por Minimal Clean Dots\nDefaults env_reset,tty_tickets,timestamp_timeout=-1\n' > "$TMP_SUDOERS"

    if sudo visudo -c -f "$TMP_SUDOERS"; then
        sudo install -m 0440 "$TMP_SUDOERS" "$SUDOERS_DROPIN"
        echo "$TXT_SUDOERS_OK"
    else
        echo "$TXT_SUDOERS_INVALID" >&2
        rm -f "$TMP_SUDOERS"
        exit 1
    fi
    rm -f "$TMP_SUDOERS"
fi

echo "$TXT_BOOTSTRAP_DONE"

# --- 5. Desactivamos los mensajes de hyprpaper
mkdir -p $HYPRPAPER_DIR
cat > "$HYPRPAPER_DIR/hyprpaper.conf" << 'EOF'
# Desactivar mensaje de hyprland
splash = falses
EOF

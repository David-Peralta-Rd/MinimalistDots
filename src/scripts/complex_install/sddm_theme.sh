#!/usr/bin/env bash
set -euo pipefail

ARCHIVO_LANG="${1:-en.cfg}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LANG_DIR="$PROJECT_ROOT/src/lang"

[ -f "$LANG_DIR/$ARCHIVO_LANG" ] && source "$LANG_DIR/$ARCHIVO_LANG"

FLAVOR="mocha"
ACCENT="blue"
THEME_NAME="catppuccin-${FLAVOR}-${ACCENT}"
ASSET_NAME="${THEME_NAME}-sddm.zip"

THEMES_DIR="/usr/share/sddm/themes"
CONF_DIR="/etc/sddm.conf.d"
CONF_FILE="$CONF_DIR/catppuccin.conf"

echo "==> Instalando dependencias del tema de SDDM..."
paru -S --needed --noconfirm qt6-svg qt6-declarative jq unzip curl

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "==> Consultando la versión más reciente del tema..."
RELEASE_JSON="$(curl -fsSL https://api.github.com/repos/catppuccin/sddm/releases/latest)"
ASSET_URL="$(jq -r --arg name "$ASSET_NAME" '.assets[] | select(.name == $name) | .browser_download_url' <<< "$RELEASE_JSON")"

if [ -z "$ASSET_URL" ] || [ "$ASSET_URL" = "null" ]; then
    echo "Error: no se encontró el asset '$ASSET_NAME' en GitHub." >&2
    exit 1
fi

echo "==> Descargando e instalando $THEME_NAME..."
curl -fsSL -o "$TMP_DIR/theme.zip" "$ASSET_URL"
unzip -oq "$TMP_DIR/theme.zip" -d "$TMP_DIR/extracted"

sudo mkdir -p "$THEMES_DIR" "$CONF_DIR"
sudo rm -rf "${THEMES_DIR:?}/${THEME_NAME}"
sudo cp -r "$TMP_DIR/extracted/$THEME_NAME" "$THEMES_DIR/"

sudo tee "$CONF_FILE" > /dev/null << EOF
[Theme]
Current=$THEME_NAME
EOF

sudo systemctl enable sddm
echo "==> Tema de SDDM configurado correctamente."

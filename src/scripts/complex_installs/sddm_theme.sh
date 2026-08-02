#!/usr/bin/env bash
# =========================================================
# SDDM - Tema minimalista (Catppuccin Mocha, accent blue)
# =========================================================
# Instala el tema oficial de catppuccin/sddm, usando el mismo
# flavor/accent que ya usa el resto del rice (colors.lua,
# style.css de wofi, etc): Mocha + azul (#89b4fa).
# https://github.com/catppuccin/sddm
# =========================================================
set -euo pipefail

FLAVOR="mocha"
ACCENT="blue"
THEME_NAME="catppuccin-${FLAVOR}-${ACCENT}"
ASSET_NAME="${THEME_NAME}-sddm.zip"

THEMES_DIR="/usr/share/sddm/themes"
CONF_DIR="/etc/sddm.conf.d"
CONF_FILE="$CONF_DIR/catppuccin.conf"

echo "==> Instalando dependencias del tema de SDDM"
paru -S --needed --noconfirm \
    qt6-svg \
    qt6-declarative \
    jq \
    unzip \
    curl

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "==> Buscando el último release de catppuccin/sddm"
RELEASE_JSON="$(curl -fsSL https://api.github.com/repos/catppuccin/sddm/releases/latest)"
ASSET_URL="$(jq -r --arg name "$ASSET_NAME" '.assets[] | select(.name == $name) | .browser_download_url' <<< "$RELEASE_JSON")"

if [ -z "$ASSET_URL" ] || [ "$ASSET_URL" = "null" ]; then
    echo "Error: no se encontró el asset '$ASSET_NAME' en el último release de catppuccin/sddm." >&2
    echo "Revisá manualmente: https://github.com/catppuccin/sddm/releases" >&2
    exit 1
fi

echo "==> Descargando $THEME_NAME"
curl -fsSL -o "$TMP_DIR/theme.zip" "$ASSET_URL"

echo "==> Extrayendo tema"
unzip -oq "$TMP_DIR/theme.zip" -d "$TMP_DIR/extracted"

if [ ! -d "$TMP_DIR/extracted/$THEME_NAME" ]; then
    echo "Error: el zip descargado no contiene la carpeta esperada '$THEME_NAME'." >&2
    exit 1
fi

echo "==> Instalando en $THEMES_DIR (requiere sudo)"
sudo mkdir -p "$THEMES_DIR"
sudo rm -rf "${THEMES_DIR:?}/${THEME_NAME}"
sudo cp -r "$TMP_DIR/extracted/$THEME_NAME" "$THEMES_DIR/"

echo "==> Configurando SDDM para usar $THEME_NAME"
sudo mkdir -p "$CONF_DIR"
sudo tee "$CONF_FILE" > /dev/null << EOF
[Theme]
Current=$THEME_NAME
EOF

echo
echo "========================================"
echo "Tema de SDDM instalado: $THEME_NAME"
echo "========================================"
echo
echo "Config escrita en: $CONF_FILE"
echo "Se aplica en el próximo reinicio de SDDM (o de la PC)."
echo
echo "Para previsualizarlo ahora, sin cerrar tu sesión:"
echo "  sddm-greeter-qt6 --test-mode --theme $THEMES_DIR/$THEME_NAME"
echo
echo "Para personalizar fuente, tamaño, fondo, reloj, etc:"
echo "  $THEMES_DIR/$THEME_NAME/theme.conf"

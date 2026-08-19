#!/usr/bin/env bash
set -euo pipefail

# --- CARGA DE IDIOMA ---
ARCHIVO_LANG="${1:-en.cfg}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LANG_DIR="$PROJECT_ROOT/src/lang"

[ -f "$LANG_DIR/$ARCHIVO_LANG" ] && source "$LANG_DIR/$ARCHIVO_LANG"

PALETTE_DIR="$PROJECT_ROOT/src/colors"
PALETTE_FILE="$PALETTE_DIR/palette.sh"
mkdir -p "$PALETTE_DIR"

echo "==> Generando paleta de colores unificada (Gris Frío & Muted)..."

cat << 'EOF' > "$PALETTE_FILE"
#!/usr/bin/env bash
# ==============================================================================
# Paleta Suave y Ergonómica (Gris Frío & Colores Muted)
# ==============================================================================

# --- Variables Con '#' (Para Rofi, Hyprland, CSS, etc.) ---
export C_BG="#1e222a"             # Fondo principal
export C_SURFACE="#282c34"        # Tarjetas, barras e inputs
export C_SELECTION="#3e4451"      # Elemento seleccionado
export C_BORDER_INACTIVE="#4b5263" # Borde inactivo
export C_BORDER_ACTIVE="#7ec7a2"   # Verde menta activo

export C_TEXT="#abb2bf"           # Texto principal
export C_SUBTEXT="#5c6370"        # Texto secundario / Muted

export C_ACCENT_BLUE="#7aa2f7"    # Azul pastel
export C_ACCENT_GREEN="#7ec7a2"   # Menta
export C_ACCENT_RED="#e06c75"     # Coral suave
export C_ACCENT_YELLOW="#d19a66"  # Ámbar suave
export C_ACCENT_MAGENTA="#c678dd" # Púrpura/Magenta
export C_ACCENT_CYAN="#56b6c2"    # Cian suave
export C_GRAY="#5c6370"           # Gris brillante
export C_LIGHT_GRAY="#abb2bf"     # Blanco brillante

# --- Variables Sin '#' (Para Foot, Kitty, Alacritty, etc.) ---
export RAW_BG="1e222a"
export RAW_SURFACE="282c34"
export RAW_SELECTION="3e4451"
export RAW_TEXT="abb2bf"
export RAW_SUBTEXT="5c6370"

export RAW_RED="e06c75"
export RAW_GREEN="7ec7a2"
export RAW_YELLOW="d19a66"
export RAW_BLUE="7aa2f7"
export RAW_MAGENTA="c678dd"
export RAW_CYAN="56b6c2"
export RAW_GRAY="5c6370"
export RAW_LIGHT_GRAY="abb2bf"
EOF

chmod +x "$PALETTE_FILE"
echo "==> Paleta de colores guardada en $PALETTE_FILE"

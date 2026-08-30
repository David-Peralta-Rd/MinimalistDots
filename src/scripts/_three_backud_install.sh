#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Si el subscript se ejecuta solo (sin pasar por setup.sh), carga el idioma guardado
if [ -z "${TXT_WELCOME:-}" ]; then
    source "$SRC_DIR/load_lang.sh"
fi




# EMPEZAMOS EL BACKUP
PROJECT_ROOT="$(cd "$SRC_DIR/../.." && pwd)"
HYPR_DIR="$HOME/.config/hypr"
BACKUP_ROOT="$HOME/.config/backups_dots/hypr-backups"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

SOURCE_DIR="$PROJECT_ROOT/src/config/hypr/hyprland"
DEST_DIR="$HYPR_DIR/hyprland"

if [ ! -d "$SOURCE_DIR" ]; then
    echo "$TXT_SOURCE_NOT_FOUND $SOURCE_DIR" >&2
    exit 1
fi

echo "=========================================================="
echo "$TXT_CONFIRM_WARNING1 $HYPR_DIR"
echo "$TXT_CONFIRM_WARNING2 $BACKUP_DIR"
echo "=========================================================="
read -rp "$TXT_CONFIRM_PROMPT " confirm
if [ "$confirm" != "$TXT_CONFIRM_WORD" ]; then
    echo "$TXT_CANCELLED"
    exit 0
fi

echo "$TXT_BACKUP_DOING $HYPR_DIR -> $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
cp -a "$HYPR_DIR/." "$BACKUP_DIR/"
echo "$TXT_BACKUP_DONE"

echo "$TXT_CLEANING"
rm -rf "$HYPR_DIR"
mkdir -p "$HYPR_DIR"
echo "$TXT_CLEANING_DONE"

echo "$TXT_COPYING $SOURCE_DIR -> $DEST_DIR"
mkdir -p "$DEST_DIR"
rsync -a "$SOURCE_DIR/" "$DEST_DIR/"
echo "$TXT_COPYING_DONE"







# ========================================================================== #
# ==== EMPEZAMOS LA INSTALACION DE LOS DIFERENTES APARTADOS DE HYPRLAND ==== #
# ========================================================================== #
# INSTALAMOS COLORES
PALETTE_DIR="$PROJECT_ROOT/src/scripts/colors"
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







# ------------------------------------------------------------------
# Cargar la paleta global (fuente única de verdad de todos los colores)
# Generada previamente por src/scripts/colors.sh -> src/colors/palette.sh
# ------------------------------------------------------------------
echo "=========================================================="
echo "${TXT_COLORS_INSTALLING:-Generando módulo de colores...}"
echo "=========================================================="
# Cargar la paleta global (para hyprlock.conf, que es .conf plano y no
PALETTE_FILE="$SRC_DIR/colors/palette.sh"
if [[ -f "$PALETTE_FILE" ]]; then
    source "$PALETTE_FILE"
else
    echo "Error: no se encontró la paleta en $PALETTE_FILE" >&2
    exit 1
fi

hex_to_rgb() {
    local hex="${1#\#}"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo "$r, $g, $b"
}

HYPR_DIR="$HOME/.config/hypr/hyprland"
mkdir -p "$HYPR_DIR"

# ------------------------------------------------------------------
# Genera hyprland/colors.lua a partir de la paleta bash.
# Esta es la ÚNICA fuente de colores que usan los módulos Lua
# (general.lua, y todos los services/*.lua: waybar, wofi, swaync, etc).
# Cambiar los colores = editar src/colors/palette.sh y reinstalar.
# ------------------------------------------------------------------
cat << EOF > "$HYPR_DIR/colors.lua"
-- ~/.config/hypr/hyprland/colors.lua
-- Autogenerado por setup_colors.sh a partir de src/colors/palette.sh
-- NO EDITES ESTE ARCHIVO A MANO: tus cambios se perderán en la
-- próxima instalación. Para cambiar la paleta, edita:
--   src/scripts/colors.sh (o src/colors/palette.sh si ya existe)

local function rgba(raw_hex, alpha)
    alpha = alpha or "ee"
    return "rgba(" .. raw_hex .. alpha .. ")"
end

return {
    background      = { hex = "${C_BG}",             hypr = rgba("${RAW_BG}") },
    surface         = { hex = "${C_SURFACE}",         hypr = rgba("${RAW_SURFACE}") },
    selection       = { hex = "${C_SELECTION}",       hypr = rgba("${RAW_SELECTION}") },

    border_inactive = { hex = "${C_BORDER_INACTIVE}", hypr = rgba("${RAW_GRAY}", "aa") },
    border_active   = { hex = "${C_BORDER_ACTIVE}",   hypr = rgba("${RAW_GREEN}") },

    text            = { hex = "${C_TEXT}",            hypr = rgba("${RAW_TEXT}") },
    subtext         = { hex = "${C_SUBTEXT}",         hypr = rgba("${RAW_SUBTEXT}") },

    accent_blue     = { hex = "${C_ACCENT_BLUE}",     hypr = rgba("${RAW_BLUE}") },
    accent_green    = { hex = "${C_ACCENT_GREEN}",    hypr = rgba("${RAW_GREEN}") },
    accent_red      = { hex = "${C_ACCENT_RED}",      hypr = rgba("${RAW_RED}") },
    accent_yellow   = { hex = "${C_ACCENT_YELLOW}",   hypr = rgba("${RAW_YELLOW}") },
    accent_magenta  = { hex = "${C_ACCENT_MAGENTA}",  hypr = rgba("${RAW_MAGENTA}") },
    accent_cyan     = { hex = "${C_ACCENT_CYAN}",     hypr = rgba("${RAW_CYAN}") },
}
EOF

echo "${TXT_COLORS_OK:-Módulo de colores configurado correctamente.}"
echo ""







# =========================================================== #
# ====  "hyprland.lua", "hypridle.conf", "hyprlock.conf" ==== #
# =========================================================== #
# Cargar la paleta global (para hyprlock.conf, que es .conf plano y no
PALETTE_FILE="$SRC_DIR/colors/palette.sh"
if [[ -f "$PALETTE_FILE" ]]; then
    source "$PALETTE_FILE"
else
    echo "Error: no se encontró la paleta en $PALETTE_FILE" >&2
    exit 1
fi

hex_to_rgb() {
    local hex="${1#\#}"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo "$r, $g, $b"
}

BG_RGB="$(hex_to_rgb "$C_BG")"
TEXT_RGB="$(hex_to_rgb "$C_TEXT")"
BORDER_INACTIVE_RGB="$(hex_to_rgb "$C_BORDER_INACTIVE")"
BORDER_ACTIVE_RGB="$(hex_to_rgb "$C_BORDER_ACTIVE")"
ACCENT_RED_RGB="$(hex_to_rgb "$C_ACCENT_RED")"
SURFACE_RGB="$(hex_to_rgb "$C_SURFACE")"

echo "=========================================================="
echo "${TXT_HYPR_ROOT_INSTALLING:-Configurando archivos principales en ~/.config/hypr/...}"
echo "=========================================================="

HYPR_ROOT="$HOME/.config/hypr"
mkdir -p "$HYPR_ROOT"

# 1. hyprland.lua (punto de entrada principal, no depende de colores)
cat << 'EOF' > "$HYPR_ROOT/hyprland.lua"
--------------------------------------------------------------------------------------
-- NO MODIFIQUES ESTA CONFIGURACIÓN BASE.                                          --
-- PARA PERSONALIZACIONES, UTILIZA: ~/.config/hypr/custom/               --
--------------------------------------------------------------------------------------

-- Carga de librerías base (Keybinder, Rules, Services, helpers globales)
require("hyprland.lib")

-- Carga de servicios (waybar, hypridle, swaync, etc.)
require("hyprland.services")

-- Carga de animaciones
require("hyprland.animations")

-- Entorno y variables de sistema
require("hyprland.env")
require_if_exists("custom.env", HOME .. "/.config/hypr/custom/env.lua")

-- Configuración de monitores
require("hyprland.monitors")
require_if_exists("custom.monitors", HOME .. "/.config/hypr/custom/monitors.lua")

-- Reglas de ventanas
require("hyprland.windowrules")
require_if_exists("custom.windowrules", HOME .. "/.config/hypr/custom/windowrules.lua")

-- Configuración general de UI/UX (gaps, bordes, input)
require("hyprland.general")
require_if_exists("custom.general", HOME .. "/.config/hypr/custom/general.lua")

-- Atajos de teclado
require("hyprland.keybinds")
require_if_exists("custom.keybinds", HOME .. "/.config/hypr/custom/keybinds.lua")
EOF

# 2. hypridle.conf (no depende de colores)
cat << 'EOF' > "$HYPR_ROOT/hypridle.conf"
general {
    lock_cmd = pidof hyprlock || hyprlock          # Evita abrir múltiples instancias
    before_sleep_cmd = loginctl lock-session      # Bloquea la sesión antes de suspender
    after_sleep_cmd = hyprctl dispatch dpms on    # Enciende la pantalla al despertar
}

# Bloquear pantalla tras 20 minutos (1200 segundos)
listener {
    timeout = 1200
    on-timeout = loginctl lock-session
}

# Apagar pantalla a los 21 minutos (1260 segundos)
listener {
    timeout = 1260
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}
EOF

# 3. hyprlock.conf (colores inyectados desde la paleta global)
cat << EOF > "$HYPR_ROOT/hyprlock.conf"
# CONFIGURACIÓN GENERAL
general {
    disable_loading_bar = true
    hide_cursor = true
    grace = 0
    no_fade_in = false
}

# FONDO ADAPTATIVO
background {
    monitor =
    path = screenshot            # Captura dinámicamente el fondo de pantalla actual

    # Filtros de desenfoque
    blur_passes = 4
    blur_size = 7
    noise = 0.015
    contrast = 0.8916
    brightness = 0.70

    # Capa translúcida usando el color de fondo de la paleta (${C_BG})
    color = rgba(${BG_RGB}, 0.8)
}

# RELOJ DIGITAL
label {
    monitor =
    text = cmd[update:1000] echo "\$(date +"%H:%M")"
    color = rgba(${TEXT_RGB}, 1.0)       # Texto general (${C_TEXT})
    font_size = 80
    font_family = JetBrains Mono Nerd Font Bold
    position = 0, 180
    halign = center
    valign = center
}

# SALUDO MINIMALISTA
label {
    monitor =
    text = Hola, \$USER
    color = rgba(${TEXT_RGB}, 0.8)      # Texto con ligera transparencia
    font_size = 14
    font_family = JetBrains Mono Nerd Font Regular
    position = 0, -40
    halign = center
    valign = center
}

# CAMPO DE ENTRADA DE CONTRASEÑA
input-field {
    monitor =
    size = 250, 45
    outline_thickness = 2
    dots_size = 0.22
    dots_spacing = 0.35
    dots_center = true

    # Paleta Muted/Ergonómica
    outer_color = rgba(${BORDER_INACTIVE_RGB}, 0.7)   # border_inactive (${C_BORDER_INACTIVE})
    check_color = rgba(${BORDER_ACTIVE_RGB}, 1.0)     # border_active (${C_BORDER_ACTIVE})
    fail_color = rgba(${ACCENT_RED_RGB}, 1.0)         # accent_red (${C_ACCENT_RED})
    inner_color = rgba(${SURFACE_RGB}, 1.0)           # surface (${C_SURFACE})
    font_color = rgba(${TEXT_RGB}, 1.0)               # text (${C_TEXT})

    fade_on_empty = true
    fade_timeout = 1500
    placeholder_text = <i>Ingresa contraseña...</i>
    hide_input = false

    position = 0, -110
    halign = center
    valign = center
}
EOF

# 4. hyprpaper.conf (no depende de colores)
cat << 'EOF' > "$HYPR_ROOT/hyprpaper.conf"
# Desactivar mensaje de splash de hyprland
splash = false
EOF

echo "${TXT_HYPR_ROOT_OK:-Archivos base configurados correctamente.}"
echo ""







echo "$TXT_CONFIG_INSTALLED"

if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    echo "$TXT_RELOADING"
    hyprctl reload
    sleep 1

    ERRORS="$(hyprctl configerrors 2>/dev/null || true)"
    if [ -n "$ERRORS" ] && [ "$ERRORS" != "no errors" ]; then
        echo "=========================================================="
        echo "$TXT_RELOAD_ERRORS"
        echo "$ERRORS"
        echo "$TXT_PREVIOUS_CONFIG_SAFE $BACKUP_DIR"
        echo "=========================================================="
        exit 1
    fi

    echo "$TXT_RELOAD_OK"
else
    echo "$TXT_NO_SESSION"
    echo "$TXT_INSTALLED_WILL_LOAD"
fi

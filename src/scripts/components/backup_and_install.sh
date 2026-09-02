#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LANG_DIR="$(cd "$SCRIPT_DIR/../../lang" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# CARGAR EL IDIOMA SI EL SCRIPT SE EJECUTA DIRECTAMENTE
if [ -z "${T_BIENVENIDO:-}" ]; then
    source "$LANG_DIR/load_lang.sh"
fi


# ========================================================== #
# ==== CONFIGURACIÓN CENTRALIZADA DE BACKUPS Y RUTAS ======= #
# ========================================================== #
SOURCE_CONFIGS_DIR="$PROJECT_ROOT/src/.config"
DEST_CONFIGS_DIR="$HOME/.config"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_ROOT="$HOME/.config/backups_dots"

if [ ! -d "$SOURCE_CONFIGS_DIR" ]; then
    echo "$T_CONFIGURACION_NO_ENCONTRADA $SOURCE_CONFIGS_DIR" >&2
    exit 1
fi

# Descubrir todas las subcarpetas dentro de src/.config/ de forma dinámica
shopt -s nullglob
ALL_DIRS=("$SOURCE_CONFIGS_DIR"/*/)
shopt -u nullglob

APPS=()
for dir in "${ALL_DIRS[@]}"; do
    APPS+=("$(basename "$dir")")
done

if [ ${#APPS[@]} -eq 0 ]; then
    echo "$T_CONFIGURACION_NO_ENCONTRADA $SOURCE_CONFIGS_DIR"
    exit 0
fi

# ========================================================== #
# ==== CONFIRMACIÓN ÚNICA PARA TODO EL PROCESO ============== #
# ========================================================== #
echo "=========================================================="
echo "📦 $T_CONFIGURACIONES_DE_ENCABEZADO (${#APPS[@]}: ${APPS[*]})"
echo "=========================================================="
read -rp "$T_CONFIRMACION_DE_CONFIGS ($T_LETRA_DE_CONFIRMACION/n): " confirm
if [ "$confirm" != "$T_LETRA_DE_CONFIRMACION" ]; then
    echo "$T_CANCELADO"
    exit 0
fi

# ========================================================== #
# ==== BUCLE GENERAL DE BACKUP Y APLICACIÓN DE CONFIGS ===== #
# ========================================================== #
for app in "${APPS[@]}"; do
    SRC="$SOURCE_CONFIGS_DIR/$app"
    DEST="$DEST_CONFIGS_DIR/$app"
    APP_BACKUP_ROOT="$BACKUP_ROOT/$app-backups/$TIMESTAMP"

    # 1. Realizar Backup si el destino ya existe
    if [ -d "$DEST" ]; then
        echo "$T_BACKUP_SI_EXISTE $app -> $APP_BACKUP_ROOT"
        mkdir -p "$APP_BACKUP_ROOT"
        cp -a "$DEST/." "$APP_BACKUP_ROOT/"

        echo "$T_LIMPIANDO_DESTINO $DEST"
        rm -rf "$DEST"
    else
        echo "$T_PAQUETE_DETECTADO $app"
    fi

    # 2. Copiar archivos nuevos desde el proyecto
    echo "$T_COPIANDO_PAQUETE $SRC -> $DEST"
    mkdir -p "$DEST"
    rsync -a "$SRC/" "$DEST/"

    # ====================================================== #
    # ==== LÓGICA ESPECÍFICA PARA HYPRLAND (SI APLICA) ===== #
    # ====================================================== #
    if [ "$app" = "hypr" ]; then
        echo "$T_CONFIGURANDO_ARCHIVOS_ESPECIFICOS"

        TARGET="$DEST/hyprland.lua"
        TARGET_HYPRIDLE="$DEST/hypridle.conf"
        TARGET_HYPRLOCK="$DEST/hyprlock.conf"
        TARGET_HYPRPAPER="$DEST/hyprpaper.conf"
        TARGET_HYPRLAND_COLORS="$DEST/hyprland/colors.lua"

        # Escribir hyprland.lua
        tee "$TARGET" > /dev/null <<'EOF'
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

        # Escribir hypridle.conf
        tee "$TARGET_HYPRIDLE" > /dev/null <<'EOF'
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

        # Escribir hyprlock.conf
        tee "$TARGET_HYPRLOCK" > /dev/null <<'EOF'
general {
    disable_loading_bar = true
    hide_cursor = true
    grace = 0
    no_fade_in = false
}
background {
    monitor =
    path = screenshot
    blur_passes = 4
    blur_size = 7
    noise = 0.015
    contrast = 0.8916
    brightness = 0.70
    color = rgba(1e1e2ecc)
}
label {
    monitor =
    text = cmd[update:1000] echo "$(date +"%H:%M")"
    color = rgba(cdd6f4ff)
    font_size = 80
    font_family = JetBrains Mono Nerd Font Bold
    position = 0, 180
    halign = center
    valign = center
}
label {
    monitor =
    text = Hola, $USER
    color = rgba(cdd6f4cc)
    font_size = 14
    font_family = JetBrains Mono Nerd Font Regular
    position = 0, -40
    halign = center
    valign = center
}
input-field {
    monitor =
    size = 250, 45
    outline_thickness = 2
    dots_size = 0.22
    dots_spacing = 0.35
    dots_center = true
    outer_color = rgba(585b70aa)
    check_color = rgba(89b4faff)
    fail_color = rgba(f38ba8ff)
    inner_color = rgba(313244ff)
    font_color = rgba(cdd6f4ff)
    fade_on_empty = true
    fade_timeout = 1500
    placeholder_text = <i>Ingresa contraseña / Enter password...</i>
    hide_input = false
    position = 0, -110
    halign = center
    valign = center
}
EOF

        # Escribir hyprpaper.conf
        tee "$TARGET_HYPRPAPER" > /dev/null <<'EOF'
splash = false
EOF

        # Escribir colors.lua
        tee "$TARGET_HYPRLAND_COLORS" > /dev/null <<EOF
-- ~/.config/hypr/hyprland/colors.lua
-- Autogenerado a partir de src/scripts/utils/palette.sh
-- NO EDITES ESTE ARCHIVO A MANO: tus cambios se perderán en la
-- próxima instalación. Para cambiar la paleta, edita:
--   src/scripts/utils/palette.sh

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


    fi
done

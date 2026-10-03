#!/usr/bin/env bash
# ==============================================================================
# u3_env.sh -- Entorno común de todos los scripts del instalador
#
#   source "<...>/utils/u3_env.sh"
#
# Hace tres cosas (una sola vez por ejecución, aunque se cargue varias veces):
#   1. Define TODAS las rutas del proyecto y del sistema (variables MD_*)
#   2. Carga el idioma elegido (variables T_*)
#   3. Carga la paleta de colores (variables C_* y RAW_*)
#
# Si una ruta cambia, se cambia AQUÍ y en ningún otro lado.
# Gracias a esto, cualquier componente puede ejecutarse solo:
#   bash src/setup/scripts/components/c4_backup_scripts/bk3_wofi.sh
# ==============================================================================

if [ -n "${MD_ENV_LOADED:-}" ]; then
    return 0
fi

_MD_UTILS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Rutas dentro del proyecto ------------------------------------------------
MD_UTILS_DIR="$_MD_UTILS"
MD_SETUP_DIR="$(cd "$_MD_UTILS/../.." && pwd)"                            # src/setup
MD_SRC_DIR="$(cd "$MD_SETUP_DIR/.." && pwd)"                              # src
MD_COMPONENTS_DIR="$MD_SETUP_DIR/scripts/components"
MD_DOTS_CONFIG="$MD_SRC_DIR/hyprland-dots/config"                         # -> ~/.config
MD_DOTS_BIN="$MD_SRC_DIR/hyprland-dots/local/bin/MinimalistDots"          # -> ~/.local/bin/MinimalistDots

# --- Rutas en el sistema del usuario ------------------------------------------
MD_HYPR_DIR="$HOME/.config/hypr"
MD_BACKUP_ROOT="$HOME/.config/backups_dots"
MD_BIN_DIR="$HOME/.local/bin/MinimalistDots"
MD_SCRIPTS_DIR="$MD_BIN_DIR/scripts"
MD_SERVICES_DIR="$MD_BIN_DIR/services"

# Menús extra de Wofi (portapapeles, atajos, volumen)
MD_WOFI_DIR="$MD_BIN_DIR/wofi"
MD_WOFI_CONFIGS="$MD_WOFI_DIR/configs"
MD_WOFI_THEMES="$MD_WOFI_DIR/themes"

# Lanzador de aplicaciones de Wofi: lo regenera wofi_theme.lua en cada arranque de Hyprland
MD_WOFI_LAUNCHER_DIR="$HOME/.config/wofi"

export MD_UTILS_DIR MD_SETUP_DIR MD_SRC_DIR MD_COMPONENTS_DIR MD_DOTS_CONFIG MD_DOTS_BIN \
       MD_HYPR_DIR MD_BACKUP_ROOT MD_BIN_DIR MD_SCRIPTS_DIR MD_SERVICES_DIR \
       MD_WOFI_DIR MD_WOFI_CONFIGS MD_WOFI_THEMES MD_WOFI_LAUNCHER_DIR

# --- Idioma -------------------------------------------------------------------
if [ -z "${T_BIENVENIDO:-}" ]; then
    source "$MD_SETUP_DIR/lang/load_lang.sh"
fi

# --- Paleta -------------------------------------------------------------------
if [ -z "${C_BG:-}" ]; then
    source "$MD_UTILS_DIR/u2_palette.sh"
fi

export MD_ENV_LOADED=1
unset _MD_UTILS

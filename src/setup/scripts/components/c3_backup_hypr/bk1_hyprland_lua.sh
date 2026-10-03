#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../utils/u3_env.sh"

# c3 pasa HYPR_DIR; si el script se ejecuta solo, usa ~/.config/hypr
HYPR_DIR="${HYPR_DIR:-$MD_HYPR_DIR}"
TARGET="$HYPR_DIR/hyprland.lua"
mkdir -p "$(dirname "$TARGET")"

cat > "$TARGET" <<'EOF'
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

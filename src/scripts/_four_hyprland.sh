#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Si el subscript se ejecuta solo (sin pasar por setup.sh), carga el idioma guardado
if [ -z "${TXT_WELCOME:-}" ]; then
    source "$SRC_DIR/load_lang.sh"
fi




# ============================================ #
# ==== EMPEZAMOS LA INSTALACION DE SCRIPS ==== #
# ============================================ #
# ".local/bin/minimalist_dots/scripts"
echo "=========================================================="
echo "${TXT_SCRIPTS_INSTALLING:-Instalando scripts auxiliares de Hyprland...}"
echo "=========================================================="

SCRIPTS_DIR="$HOME/.local/bin/minimalist_dots/scripts"
mkdir -p "$SCRIPTS_DIR"

# vars.lua apunta a este script (vars.select_wallpaper), lo generamos aquí.
cat << 'EOF' > "$SCRIPTS_DIR/select_wallpaper.sh"
#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR="$HOME/multimedia/pictures/wallpapers"
STATE_FILE="$HOME/.cache/hypr/current_wallpaper"

mkdir -p "$WALLPAPER_DIR" "$(dirname "$STATE_FILE")"

SELECTED_NAME="$(
    find "$WALLPAPER_DIR" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -printf '%f\n' |
    while read -r name; do
        printf '%s\0icon\x1f%s\n' "$name" "$WALLPAPER_DIR/$name"
    done |
    wofi --show dmenu --prompt "Fondo de pantalla"
)"

[ -z "$SELECTED_NAME" ] && exit 0

FULL_PATH="$WALLPAPER_DIR/$SELECTED_NAME"
hyprctl hyprpaper wallpaper ",$FULL_PATH,fill"
echo "$FULL_PATH" > "$STATE_FILE"
EOF

chmod +x "$SCRIPTS_DIR/select_wallpaper.sh"

echo "${TXT_SCRIPTS_OK:-Scripts auxiliares instalados correctamente.}"
echo ""







# ====================================== #
# ==== INSTALACION DE LOS SERVICIOS ==== #
# ====================================== #
echo "=========================================================="
echo "${TXT_SERVICES_INSTALLING:-Generando servicios...}"
echo "=========================================================="

SERVICES_DIR="$HOME/.local/bin/minimalist_dots/services"
mkdir -p "$SERVICES_DIR"

# 1. clipboard.lua
cat << 'EOF' > "$SERVICES_DIR/clipboard.lua"
local home = os.getenv("HOME")
package.path = package.path .. ";" .. home .. "/.config/hypr/hyprland/lib/?.lua"

local Service = require("services")

return Service.define("clipboard", function()
    hl.on("hyprland.start", function()
        hl.exec_cmd("wl-paste --type text --watch cliphist store")
        hl.exec_cmd("wl-paste --type image --watch cliphist store")
    end)
end)
EOF


# 2. create_custom_config.lua
cat << 'EOF' > "$SERVICES_DIR/create_custom_config.lua"
local home = os.getenv("HOME")
package.path = package.path .. ";" .. home .. "/.config/hypr/hyprland/lib/?.lua"

local Service = require("services")

local CUSTOM_DIR   = HOME .. "/.config/hypr/custom"
local SERVICES_DIR = CUSTOM_DIR .. "/services"

local overrides = { "animations", "colors", "env", "general", "keybinds", "monitors", "vars", "windowrules" }

local function ensure_override_file(name)
    local path = CUSTOM_DIR .. "/" .. name .. ".lua"
    if not is_file_exists(path) then
        local f = io.open(path, "w")
        if f then
            f:write("-- override de '" .. name .. "', seguro de editar\nreturn {}\n")
            f:close()
        end
    end
end

local function regenerate_services_init()
    local lines = {
        "-- Autogenerado por create_custom_config. No editar a mano.",
        "-- Para agregar un servicio nuevo: crea un .lua en esta carpeta.",
        "",
    }

    local pipe = io.popen('ls "' .. SERVICES_DIR .. '" 2>/dev/null')
    if pipe then
        for filename in pipe:lines() do
            if filename:match("%.lua$") and filename ~= "init.lua" then
                local modname = filename:gsub("%.lua$", "")
                lines[#lines + 1] = 'require("custom.services.' .. modname .. '")'
            end
        end
        pipe:close()
    end

    local f = io.open(SERVICES_DIR .. "/init.lua", "w")
    if f then
        f:write(table.concat(lines, "\n") .. "\n")
        f:close()
    end
end

return Service.define("create_custom_config", function()
    hl.on("hyprland.start", function()
        os.execute('mkdir -p "' .. CUSTOM_DIR .. '"')
        os.execute('mkdir -p "' .. SERVICES_DIR .. '"')

        for _, name in ipairs(overrides) do
            ensure_override_file(name)
        end

        regenerate_services_init()
    end)
end)
EOF


# 3. dbus_env.lua
cat << 'EOF' > "$SERVICES_DIR/dbus_env.lua"
local home = os.getenv("HOME")
package.path = package.path .. ";" .. home .. "/.config/hypr/hyprland/lib/?.lua"

local Service = require("services")

return Service.define("dbus_env", function()
    hl.on("hyprland.start", function()
        hl.exec_cmd("dbus-update-activation-environment --all")
        hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    end)
end)
EOF

# 4. export_keybinds.lua
cat << 'EOF' > "$SERVICES_DIR/export_keybinds.lua"
local home = os.getenv("HOME")
package.path = package.path .. ";" .. home .. "/.config/hypr/hyprland/lib/?.lua"

local Service = require("services")
local Keybinder = require("keybinder")

return Service.define("export_keybinds", function()
    hl.on("hyprland.start", function()
        Keybinder.export_json()
    end)
end)
EOF

# 5. hypridle.lua
cat << 'EOF' > "$SERVICES_DIR/hypridle.lua"
local home = os.getenv("HOME")
package.path = package.path .. ";" .. home .. "/.config/hypr/hyprland/lib/?.lua"

local Service = require("services")

return Service.define("hypridle", function()
    hl.on("hyprland.start", function()
        hl.exec_cmd("hypridle")
    end)
end)
EOF


# 6. notifications.lua
cat << 'EOF' > "$SERVICES_DIR/notifications.lua"
local home = os.getenv("HOME")
package.path = package.path .. ";" .. home .. "/.config/hypr/hyprland/lib/?.lua"
package.path = package.path .. ";" .. home .. "/.config/hypr/hyprland/?.lua"

local Service = require("services")
local colors  = require("colors")

local CONFIG_DIR = os.getenv("HOME") .. "/.config/swaync"

local function write_style_css()
    local css = string.format([[
* { font-family: sans-serif; font-size: 13px; }
.notification-background { background: %s; border: 1px solid %s; border-radius: 6px; }
.notification-background:hover { border-color: %s; transition: border-color 120ms ease-out; }
.notification-content { color: %s; padding: 10px; }
.close-button { background: transparent; color: %s; border-radius: 4px; }
.close-button:hover { background: %s; }
.control-center { background: %s; border: 1px solid %s; border-radius: 8px; }
]],
    colors.surface.hex, colors.border_inactive.hex, colors.border_active.hex,
    colors.text.hex, colors.text.hex, colors.border_inactive.hex,
    colors.background.hex, colors.border_inactive.hex)

    local f = io.open(CONFIG_DIR .. "/style.css", "w")
    if f then f:write(css) f:close() end
end

local function write_config_json()
    local json = [[
{
    "positionX": "right",
    "positionY": "top",
    "control-center-width": 380,
    "notification-window-width": 380,
    "timeout": 4,
    "timeout-low": 3,
    "timeout-critical": 0,
    "notification-icon-size": 32
}
]]
    local f = io.open(CONFIG_DIR .. "/config.json", "w")
    if f then f:write(json) f:close() end
end

return Service.define("notifications", function()
    hl.on("hyprland.start", function()
        os.execute("mkdir -p " .. CONFIG_DIR)
        write_style_css()
        write_config_json()
        hl.exec_cmd("swaync")
    end)
end)
EOF


# 7. polkit.lua
cat << 'EOF' > "$SERVICES_DIR/polkit.lua"
local home = os.getenv("HOME")
package.path = package.path .. ";" .. home .. "/.config/hypr/hyprland/lib/?.lua"

local Service = require("services")

return Service.define("polkit", function()
    hl.on("hyprland.start", function()
        hl.exec_cmd("systemctl --user start hyprpolkitagent")
    end)
end)
EOF


# 8. wallpaper.lua
cat << 'EOF' > "$SERVICES_DIR/wallpaper.lua"
local home = os.getenv("HOME")
package.path = package.path .. ";" .. home .. "/.config/hypr/hyprland/lib/?.lua"

local Service = require("services")
local WALLPAPER_DIR = os.getenv("HOME") .. "/multimedia/pictures/wallpapers"
local STATE_FILE = os.getenv("HOME") .. "/.cache/hypr/current_wallpaper"

local function read_last_wallpaper()
    local f = io.open(STATE_FILE, "r")
    if not f then return nil end
    local path = f:read("*l")
    f:close()
    return path
end

return Service.define("wallpaper", function()
    hl.on("hyprland.start", function()
        os.execute("mkdir -p " .. WALLPAPER_DIR)
        os.execute("mkdir -p " .. os.getenv("HOME") .. "/.cache/hypr")

        hl.exec_cmd("hyprpaper")

        local last = read_last_wallpaper()
        if last and is_file_exists(last) then
            hl.exec_cmd(string.format('sleep 1 && hyprctl hyprpaper wallpaper ",%s,fill"', last))
        end
    end)
end)
EOF


# 9. wofi_theme.lua
cat << 'EOF' > "$SERVICES_DIR/wofi_theme.lua"
local home = os.getenv("HOME")
package.path = package.path .. ";" .. home .. "/.config/hypr/hyprland/lib/?.lua"
package.path = package.path .. ";" .. home .. "/.config/hypr/hyprland/?.lua"

local Service = require("services")
local colors  = require("colors")

local CONFIG_DIR = os.getenv("HOME") .. "/.config/wofi"

local function hex_to_css_rgba(hex, alpha)
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    return string.format("rgba(%d, %d, %d, %.2f)", r, g, b, alpha)
end

local function write_config()
    local config = [[
show=drun
allow_images=true
image_size=20
width=500
lines=10
location=top
yoffset=20
hide_scroll=true
print_command=true
]]
    local f = io.open(CONFIG_DIR .. "/config", "w")
    if f then f:write(config) f:close() end
end

local function write_style()
    local css = string.format([[
window { margin: 0px; background-color: %s; border: 2px solid %s; border-radius: 12px; font-family: 'Inter', 'JetBrains Mono', 'monospace'; font-size: 14px; }
#input { margin: 12px 12px 6px 12px; border: 1px solid %s; border-radius: 8px; background-color: %s; color: %s; padding: 8px; }
#inner-box { margin: 6px 12px 12px 12px; border: none; background-color: transparent; }
#entry { padding: 6px 8px; background-color: transparent; border-radius: 6px; border: none; }
#entry:selected { background-color: %s; transition: background-color 0.1s ease-in-out; }
#img { margin-right: 10px; }
#text { color: %s; background-color: transparent; }
#text:selected { color: %s; font-weight: bold; }
#outer-box { margin: 0px; border: none; background-color: transparent; }
#scroll { margin: 0px; border: none; background-color: transparent; }
]],
        hex_to_css_rgba(colors.background.hex, 0.85),
        colors.border_active.hex,
        colors.border_inactive.hex,
        hex_to_css_rgba(colors.surface.hex, 0.7),
        colors.text.hex,
        hex_to_css_rgba(colors.surface.hex, 0.9),
        colors.text.hex,
        colors.border_active.hex)

    local f = io.open(CONFIG_DIR .. "/style.css", "w")
    if f then f:write(css) f:close() end
end

return Service.define("wofi_theme", function()
    hl.on("hyprland.start", function()
        os.execute("mkdir -p " .. CONFIG_DIR)
        write_config()
        write_style()
    end)
end)
EOF







# ============================================================ #
# ==== CONFIGURAMOS LOS ESTILOS Y CONFIGURACIONES DE WOFI ==== #
# ============================================================ #
# ".configs"
# Cargar la paleta global de colores (archivo generado por colors.sh,
# NUNCA el script generador).
PALETTE_FILE="$SRC_DIR/colors/palette.sh"
if [[ -f "$PALETTE_FILE" ]]; then
    source "$PALETTE_FILE"
else
    # Fallback de seguridad si por algún motivo no existe la paleta
    C_BG="#1e222a"
    C_SURFACE="#282c34"
    C_BORDER_INACTIVE="#4b5263"
    C_ACCENT_BLUE="#7aa2f7"
    C_ACCENT_GREEN="#7ec7a2"
    C_TEXT="#abb2bf"
fi

echo "=========================================================="
echo "${TXT_WOFI_EXTRA_INSTALLING:-Generando menús extra de Wofi (portapapeles y atajos)...}"
echo "=========================================================="

WOFI_DIR="$HOME/.config/wofi"
WOFI_THEMES="$WOFI_DIR/themes"
WOFI_CONFIGS="$WOFI_DIR/configs"
BIN_DIR="$HOME/.local/bin/minimalist_dots/scripts/"
mkdir -p "$WOFI_THEMES" "$WOFI_CONFIGS" "$BIN_DIR"

# Convertidor HEX -> CSS rgba(r, g, b, alpha)
hex_to_rgba() {
    local hex="${1#\#}"
    local alpha="$2"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo "rgba($r, $g, $b, $alpha)"
}

BG_90_RGBA=$(hex_to_rgba "$C_BG" 0.90)
SURFACE_70_RGBA=$(hex_to_rgba "$C_SURFACE" 0.70)
SURFACE_90_RGBA=$(hex_to_rgba "$C_SURFACE" 0.90)

# ==========================================================
# 1. PORTAPAPELES (cliphist)
# ==========================================================
cat << EOF > "$WOFI_CONFIGS/config-clipboard"
# Configuración específica para Gestor de Portapapeles (cliphist)
show=dmenu
allow_images=false
width=700
height=420
lines=12
location=center
hide_scroll=true
matching=fuzzy
prompt=📋 Portapapeles
EOF

cat << EOF > "$WOFI_THEMES/style-clipboard.css"
/* Estilo dedicado para Portapapeles */
window {
    margin: 0px;
    background-color: ${BG_90_RGBA};
    border: 2px solid ${C_ACCENT_BLUE}; /* Acento azul para diferenciar del lanzador */
    border-radius: 10px;
    font-family: 'JetBrainsMono Nerd Font', 'monospace';
    font-size: 13px;
}
#input {
    margin: 10px 10px 4px 10px;
    border: 1px solid ${C_BORDER_INACTIVE};
    border-radius: 6px;
    background-color: ${SURFACE_70_RGBA};
    color: ${C_TEXT};
    padding: 6px 10px;
}
#inner-box { margin: 4px 10px 10px 10px; border: none; background-color: transparent; }
#entry { padding: 4px 6px; background-color: transparent; border-radius: 4px; border: none; }
#entry:selected { background-color: ${SURFACE_90_RGBA}; transition: background-color 0.1s ease-in-out; }
#text { color: ${C_TEXT}; background-color: transparent; }
#text:selected { color: ${C_ACCENT_BLUE}; font-weight: bold; }
#outer-box { margin: 0px; border: none; background-color: transparent; }
#scroll { margin: 0px; border: none; background-color: transparent; }
EOF

# ==========================================================
# 2. VISOR DE ATAJOS DE TECLADO (lee ~/.cache/hypr/keybinds.json,
#    escrito por hyprland/lib/keybinder.lua -> export_json())
# ==========================================================
cat << EOF > "$WOFI_CONFIGS/config-binds"
# Configuración específica para el menú de Atajos de Teclado
show=dmenu
allow_images=false
width=650
height=480
lines=14
location=center
hide_scroll=true
matching=fuzzy
prompt=⌨️  Atajos de Teclado
EOF

cat << EOF > "$WOFI_THEMES/style-binds.css"
/* Estilo dedicado para el visualizador de atajos de teclado */
window {
    margin: 0px;
    background-color: ${BG_90_RGBA};
    border: 2px solid ${C_ACCENT_GREEN};
    border-radius: 12px;
    font-family: 'JetBrainsMono Nerd Font', 'monospace';
    font-size: 13px;
}
#input {
    margin: 10px 10px 4px 10px;
    border: 1px solid ${C_BORDER_INACTIVE};
    border-radius: 6px;
    background-color: ${SURFACE_70_RGBA};
    color: ${C_TEXT};
    padding: 6px 10px;
}
#inner-box { margin: 4px 10px 10px 10px; border: none; background-color: transparent; }
#entry { padding: 4px 6px; background-color: transparent; border-radius: 4px; border: none; }
#entry:selected { background-color: ${SURFACE_90_RGBA}; transition: background-color 0.1s ease-in-out; }
#text { color: ${C_TEXT}; background-color: transparent; }
#text:selected { color: ${C_ACCENT_GREEN}; font-weight: bold; }
#outer-box { margin: 0px; border: none; background-color: transparent; }
#scroll { margin: 0px; border: none; background-color: transparent; }
EOF

# El binario "show_binds" agrupa por categoría usando jq y lanza Wofi
# con el estilo generado arriba. Consume el JSON que exporta el
# Keybinder de Lua (categorías incluidas).
cat << 'EOF' > "$BIN_DIR/show_binds"
#!/usr/bin/env bash
set -euo pipefail

JSON_FILE="$HOME/.cache/hypr/keybinds.json"
WOFI_CONFIG="$HOME/.config/wofi/configs/config-binds"
WOFI_STYLE="$HOME/.config/wofi/themes/style-binds.css"

if ! command -v jq &>/dev/null; then
    notify-send -a "Atajos" -i "dialog-error" "Error" "jq no está instalado."
    exit 1
fi

if [[ ! -f "$JSON_FILE" ]]; then
    notify-send -a "Atajos" -i "dialog-warning" "Atajos no encontrados" "No se detectó $JSON_FILE"
    exit 1
fi

formatted_list=$(jq -r '
    group_by(.category) | .[] |
    "󰌌  [" + .[0].category + "]",
    (.[] | "   " + (if .mod == "" then "" else .mod + " + " end) + .key + "  󰁔  " + .description),
    ""
' "$JSON_FILE")

echo "$formatted_list" | wofi -c "$WOFI_CONFIG" -s "$WOFI_STYLE" --dmenu | true
EOF

chmod +x "$BIN_DIR/show_binds"

echo "${TXT_WOFI_EXTRA_OK:-Menús extra de Wofi generados correctamente.}"
echo ""

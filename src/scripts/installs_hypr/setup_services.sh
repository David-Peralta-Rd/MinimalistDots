#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LANG_FILE="${1:-es.cfg}"
PATH_TRADUCCION="$SCRIPT_DIR/src/lang/$LANG_FILE"

if [[ -f "$PATH_TRADUCCION" ]]; then
    source "$PATH_TRADUCCION"
fi

echo "=========================================================="
echo "${TXT_SERVICES_INSTALLING:-Generando servicios...}"
echo "=========================================================="

SERVICES_DIR="$HOME/.config/hypr/hyprland/services"
mkdir -p "$SERVICES_DIR"

# 1. clipboard.lua
cat << 'EOF' > "$SERVICES_DIR/clipboard.lua"
local Service = require("hyprland.lib.services")

return Service.define("clipboard", function()
    hl.on("hyprland.start", function()
        hl.exec_cmd("wl-paste --type text --watch cliphist store")
        hl.exec_cmd("wl-paste --type image --watch cliphist store")
    end)
end)
EOF

# 2. create_custom_config.lua
cat << 'EOF' > "$SERVICES_DIR/create_custom_config.lua"
local Service = require("hyprland.lib.services")

local CUSTOM_DIR   = HOME .. "/.config/hypr/custom_minimalist"
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
                lines[#lines + 1] = 'require("custom_minimalist.services.' .. modname .. '")'
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

# 3. cursor.lua
cat << 'EOF' > "$SERVICES_DIR/cursor.lua"
local Service = require("hyprland.lib.services")

return Service.define("cursor", function()
    hl.on("hyprland.start", function()
        hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
    end)
end)
EOF

# 4. dbus_env.lua
cat << 'EOF' > "$SERVICES_DIR/dbus_env.lua"
local Service = require("hyprland.lib.services")

return Service.define("dbus_env", function()
    hl.on("hyprland.start", function()
        hl.exec_cmd("dbus-update-activation-environment --all")
        hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    end)
end)
EOF

# 5. export_keybinds.lua
cat << 'EOF' > "$SERVICES_DIR/export_keybinds.lua"
local Service = require("hyprland.lib.services")
local Keybinder = require("hyprland.lib.keybinder")

return Service.define("export_keybinds", function()
    hl.on("hyprland.start", function()
        Keybinder.export_json()
    end)
end)
EOF

# 6. footclient.lua
cat << 'EOF' > "$SERVICES_DIR/footclient.lua"
local Service = require("hyprland.lib.services")

return Service.define("footclient", function()
    hl.on("hyprland.start", function()
        hl.exec_cmd("foot --server")
    end)
end)
EOF

# 7. hypridle.lua
cat << 'EOF' > "$SERVICES_DIR/hypridle.lua"
local Service = require("hyprland.lib.services")

return Service.define("hypridle", function()
    hl.on("hyprland.start", function()
        hl.exec_cmd("hypridle")
    end)
end)
EOF

# 8. keybinds_show.lua (Lector nativo mediante Wofi)
cat << 'EOF' > "$SERVICES_DIR/keybinds_show.lua"
local Service = require("hyprland.lib.services")

local BIN_DIR  = os.getenv("HOME") .. "/.local/bin/minimaldots"
local SCRIPT   = BIN_DIR .. "/show_binds"

local WOFI_SCRIPT = [[#!/usr/bin/env bash
JSON_FILE="$HOME/.cache/hypr/keybinds.json"

if [[ ! -f "$JSON_FILE" ]]; then
    notify-send "Keybinds" "No se encontró el archivo de atajos en $JSON_FILE"
    exit 1
fi

jq -r '.[] | "\(.category // "Otros") │ \(.mod)\(if .mod != "" and .key != "" then " + " else "" end)\(.key) ➔ \(.description)"' "$JSON_FILE" \
    | wofi --dmenu --prompt "Atajos de teclado / Keybinds" --width 650 --height 400
]]

return Service.define("keybinds-generator", function()
    os.execute("mkdir -p " .. BIN_DIR)
    local f = io.open(SCRIPT, "w")
    if f then
        f:write(WOFI_SCRIPT)
        f:close()
        os.execute("chmod +x " .. SCRIPT)
    end
end)
EOF

# 9. notifications.lua
cat << 'EOF' > "$SERVICES_DIR/notifications.lua"
local Service = require("hyprland.lib.services")
local colors  = require("hyprland.colors")

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

# 10. polkit.lua
cat << 'EOF' > "$SERVICES_DIR/polkit.lua"
local Service = require("hyprland.lib.services")

return Service.define("polkit", function()
    hl.on("hyprland.start", function()
        hl.exec_cmd("systemctl --user start hyprpolkitagent")
    end)
end)
EOF

# 11. udiskie.lua
cat << 'EOF' > "$SERVICES_DIR/udiskie.lua"
local Service = require("hyprland.lib.services")

return Service.define("udiskie", function()
    hl.on("hyprland.start", function()
        hl.exec_cmd("udiskie --no-tray")
    end)
end)
EOF

# 12. wallpaper.lua
cat << 'EOF' > "$SERVICES_DIR/wallpaper.lua"
local Service = require("hyprland.lib.services")

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

# 13. waybar.lua
cat << 'EOF' > "$SERVICES_DIR/waybar.lua"
local Service = require("hyprland.lib.services")
local colors  = require("hyprland.colors")

local CONFIG_DIR = os.getenv("HOME") .. "/.config/waybar"

local function hex_to_rgb(hex)
    hex = hex:gsub("#", "")
    return tonumber(hex:sub(1,2), 16), tonumber(hex:sub(3,4), 16), tonumber(hex:sub(5,6), 16)
end

local function write_config()
    local config = [[
{
    "layer": "top",
    "position": "top",
    "height": 28,
    "margin-top": 4,
    "margin-left": 8,
    "margin-right": 8,
    "modules-left": ["hyprland/workspaces"],
    "modules-right": ["clock"],

    "hyprland/workspaces": {
        "format": "{id}",
        "on-click": "activate"
    },

    "clock": {
        "format": "{:%H:%M}",
        "tooltip-format": "{:%A, %d %B %Y}"
    }
}
]]
    local f = io.open(CONFIG_DIR .. "/config.jsonc", "w")
    if f then f:write(config) f:close() end
end

local function write_style()
    local bg_r, bg_g, bg_b = hex_to_rgb(colors.surface.hex)

    local css = string.format([[
* { font-family: sans-serif; font-size: 13px; min-height: 0; }
window#waybar { background: rgba(%d, %d, %d, 0.25); border-radius: 6px; }
#workspaces { background: transparent; margin: 0 6px; }
#workspaces button { padding: 0 8px; color: %s; background: transparent; border: none; border-bottom: 2px solid transparent; }
#workspaces button:nth-child(3n+1) { border-bottom-color: %s; }
#workspaces button:nth-child(3n+2) { border-bottom-color: %s; }
#workspaces button:nth-child(3n+3) { border-bottom-color: %s; }
#workspaces button.active { border-bottom-color: %s; color: %s; font-weight: bold; }
#clock { color: %s; padding: 0 10px; }
]],
        bg_r, bg_g, bg_b,
        colors.text.hex,
        colors.border_active.hex, colors.text.hex, colors.border_inactive.hex,
        colors.border_active.hex, colors.border_active.hex,
        colors.text.hex)

    local f = io.open(CONFIG_DIR .. "/style.css", "w")
    if f then f:write(css) f:close() end
end

return Service.define("waybar", function()
    hl.on("hyprland.start", function()
        os.execute("mkdir -p " .. CONFIG_DIR)
        write_config()
        write_style()
        hl.exec_cmd("waybar")
    end)
end)
EOF

# 14. wofi_theme.lua
cat << 'EOF' > "$SERVICES_DIR/wofi_theme.lua"
local Service = require("hyprland.lib.services")
local colors  = require("hyprland.colors")

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

# 15. init.lua Principal
cat << 'EOF' > "$SERVICES_DIR/init.lua"
require("hyprland.services.polkit")
require("hyprland.services.footclient")
require("hyprland.services.dbus_env")
require("hyprland.services.clipboard")
require("hyprland.services.cursor")
require("hyprland.services.export_keybinds")
require("hyprland.services.notifications")
require("hyprland.services.create_custom_config")
require("hyprland.services.hypridle")
-- require("hyprland.services.waybar")
require("hyprland.services.wofi_theme")
require("hyprland.services.wallpaper")
require("hyprland.services.udiskie")
require("hyprland.services.keybinds_show")

require_if_exists(
    "custom_minimalist.services.init",
    HOME .. "/.config/hypr/custom_minimalist/services/init.lua"
)

-- Ejecutar todos los servicios
require("hyprland.lib.services").run_all()
EOF

echo "${TXT_SERVICES_OK:-Servicios generados exitosamente.}"
echo ""

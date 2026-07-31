-- ~/.config/hypr/hyprland/services/waybar.lua
local Service = require("lib.services")
local colors  = require("colors")

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
* {
    font-family: sans-serif;
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background: rgba(%d, %d, %d, 0.25);
    border-radius: 6px;
}

#workspaces {
    background: transparent;
    margin: 0 6px;
}

#workspaces button {
    padding: 0 8px;
    color: %s;
    background: transparent;
    border: none;
    border-bottom: 2px solid transparent;
}

/* Rotan entre los 3 acentos de la paleta, escritorio a escritorio */
#workspaces button:nth-child(3n+1) { border-bottom-color: %s; }
#workspaces button:nth-child(3n+2) { border-bottom-color: %s; }
#workspaces button:nth-child(3n+3) { border-bottom-color: %s; }

#workspaces button.active {
    border-bottom-color: %s;
    color: %s;
    font-weight: bold;
}

#clock {
    color: %s;
    padding: 0 10px;
}
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

require("load_direction")


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

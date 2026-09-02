require("load_direction")


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

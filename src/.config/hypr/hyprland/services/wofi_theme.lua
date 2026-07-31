-- ~/.config/hypr/hyprland/services/wofi_theme.lua
local Service = require("hyprland.lib.services")
local colors  = require("hyprland.colors")

local CONFIG_DIR = os.getenv("HOME") .. "/.config/wofi"

local function write_config()
    local config = [[
allow_images=true
image_size=140
insensitive=true
width=500
height=400
location=center
]]
    local f = io.open(CONFIG_DIR .. "/config", "w")
    if f then f:write(config) f:close() end
end

local function write_style()
    local css = string.format([[
window {
    background: %s;
    border: 1px solid %s;
    border-radius: 10px;
}
#input {
    background: %s;
    color: %s;
    border-radius: 6px;
    padding: 6px;
    margin: 8px;
}
#entry {
    padding: 4px;
    border-radius: 6px;
}
#entry:selected {
    background: %s;
}
#img {
    border-radius: 6px;
}
#text {
    color: %s;
}
]],
        colors.surface.hex, colors.border_inactive.hex,
        colors.background.hex, colors.text.hex,
        colors.border_inactive.hex,
        colors.text.hex)

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

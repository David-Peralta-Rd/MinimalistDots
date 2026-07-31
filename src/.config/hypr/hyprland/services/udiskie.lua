-- ~/.config/hypr/hyprland/services/udiskie.lua
local Service = require("hyprland.lib.services")

return Service.define("udiskie", function()
    hl.on("hyprland.start", function()
        hl.exec_cmd("udiskie --no-tray")
    end)
end)

-- ~/.config/hypr/hyprland/services/hypridle.lua
local Service = require("hyprland.lib.services")

return Service.define("hypridle", function()
    hl.on("hyprland.start", function()
        hl.exec_cmd("hypridle")
    end)
end)

-- ~/.config/hypr/hyprland/services/cursor.lua
local Service = require("hyprland.lib.services")

return Service.define("cursor", function()
    hl.on("hyprland.start", function()
        hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
    end)
end)

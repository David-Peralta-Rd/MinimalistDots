-- ~/.config/hypr/hyprland/services/polkit.lua
local Service = require("hyprland.lib.services")

return Service.define("polkit", function()
    hl.on("hyprland.start", function()
        hl.exec_cmd("systemctl --user start hyprpolkitagent")
    end)
end)

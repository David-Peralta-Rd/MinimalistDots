require("load_direction")


local Service = require("hyprland.lib.services")

return Service.define("clipboard", function()
    hl.on("hyprland.start", function()
        hl.exec_cmd("wl-paste --type text --watch cliphist store")
        hl.exec_cmd("wl-paste --type image --watch cliphist store")
    end)
end)

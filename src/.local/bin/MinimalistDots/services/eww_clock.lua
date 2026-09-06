require("load_direction")


local Service = require("hyprland.lib.services")

return Service.define("footclient", function()
    hl.on("hyprland.start", function()
        hl.exec_cmd("eww open desktop_clock")
    end)
end)

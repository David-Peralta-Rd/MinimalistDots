require("load_direction")


local Service = require("hyprland.lib.services")

return Service.define("hypridle", function()
    hl.on("hyprland.start", function()
        hl.exec_cmd("hypridle")
    end)
end)

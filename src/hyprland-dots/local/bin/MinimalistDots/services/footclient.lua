require("load_direction")


local Service = require("hyprland.lib.services")

return Service.define("footclient", function()
    hl.on("hyprland.start", function()
        hl.exec_cmd("foot --server")
    end)
end)

require("load_direction")


local Service = require("hyprland.lib.services")
local Keybinder = require("hyprland.lib.keybinder")

return Service.define("export_keybinds", function()
    hl.on("hyprland.start", function()
        Keybinder.export_json()
    end)
end)

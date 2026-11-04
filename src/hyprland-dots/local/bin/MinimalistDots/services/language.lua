require("load_direction")

local Service = require("hyprland.lib.services")
local SELECTOR = HOME .. "/.local/bin/MinimalistDots/scripts/language_selector.sh"

-- Resuelve el idioma una vez por sesión; no deja watcher ni proceso residente.
return Service.define("language", function()
    hl.on("hyprland.start", function()
        hl.exec_cmd('"' .. SELECTOR .. '" --activate')
    end)
end)

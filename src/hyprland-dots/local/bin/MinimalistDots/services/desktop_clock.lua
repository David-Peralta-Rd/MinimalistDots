require("load_direction")


local Service = require("hyprland.lib.services")

-- Reloj de escritorio (Quickshell). No hace falta daemon: es un proceso `qs` ligero.
local QML = os.getenv("HOME") .. "/.local/bin/MinimalistDots/quickshell/clock.qml"

return Service.define("desktop_clock", function()
    hl.on("hyprland.start", function()
        hl.exec_cmd("qs -p " .. QML)
    end)
end)

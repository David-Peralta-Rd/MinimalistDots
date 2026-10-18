require("load_direction")


local Service = require("hyprland.lib.services")

-- Servidor de notificaciones en Quickshell (reemplaza a SwayNC).
-- Debe haber un solo servidor en el bus: si aún tienes swaync instalado, desinstálalo.
local QML = os.getenv("HOME") .. "/.local/bin/MinimalistDots/quickshell/notifd.qml"

return Service.define("notifications", function()
    hl.on("hyprland.start", function()
        hl.exec_cmd("qs -p " .. QML)
    end)
end)

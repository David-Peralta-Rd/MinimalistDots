require("load_direction")


local Service = require("hyprland.lib.services")

return Service.define("dbus_env", function()
    hl.on("hyprland.start", function()
        hl.exec_cmd("dbus-update-activation-environment --all")
        hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    end)
end)

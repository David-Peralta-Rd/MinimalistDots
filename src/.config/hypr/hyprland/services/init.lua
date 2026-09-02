local home = os.getenv("HOME")


-- DIRECTORIO DE SERVICIOS
package.path = package.path .. ";" .. home .. "/.local/bin/MinimalistDots/services/?.lua"

-- SI DESEAS DESACTIVAR UN SERVICIO, SOLO DOCUMENTALO CON '--'
-- EJEMPLO:

--require("example.lua")

require("polkit")
require("footclient")
require("dbus_env")
require("clipboard")
require("export_keybinds")
require("notifications")
require("create_custom_config")
require("hypridle")
require("wallpaper")


-- Custom
require_if_exists(
    "custom.services.init",
    HOME .. "/.config/hypr/custom/services/init.lua"
)

-- Ejecutar todos los servicios
require("hyprland.lib.services").run_all()

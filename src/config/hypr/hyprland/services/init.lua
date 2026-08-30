local home = os.getenv("HOME")

-- DIRECTORIO DE SERVICIOS
package.path = package.path .. ";" .. home .. "/.local/bin/minimalist_dots/services/?.lua"


require("polkit")

require("dbus_env")

require("clipboard")

require("export_keybinds")

require("notifications")

require("create_custom_config")

require("hypridle")

require("wofi_theme")

require("wallpaper")

-- Custom
require_if_exists(
    "custom.services.init",
    HOME .. "/.config/hypr/custom/services/init.lua"
)

-- Ejecutar todos los servicios
require("hyprland.lib.services").run_all()

-- ~/.config/hypr/hyprland/services/init.lua
require("hyprland.services.polkit")
require("hyprland.services.footclient")
require("hyprland.services.dbus_env")
require("hyprland.services.clipboard")
require("hyprland.services.cursor")
require("hyprland.services.export_keybinds")
require("hyprland.services.notifications")
require("hyprland.services.create_custom_config")
require("hyprland.services.hypridle")
--require("hyprland.services.waybar")
require("hyprland.services.wofi_theme")
require("hyprland.services.wallpaper")
require("hyprland.services.udiskie")
require("hyprland.services.keybinds_show")


require_if_exists(
    "custom_minimalist.services.init",
    HOME .. "/.config/hypr/custom_minimalist/services/init.lua"
)

-- run all
require("hyprland.lib.services").run_all()

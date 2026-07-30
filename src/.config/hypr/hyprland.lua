--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- NO MODIFIQUES ESTA CONFIGURACIÓN; SI DESEAS HACER CAMBIOS,                       --
-- VE A LA SIGUIENTE CARPETA Y REALIZA TUS CONFIGURACIONES PERSONALES:              --
-- ~/.config/hypr/custom_minimalist/                                                --
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- DO NOT TOUCH THIS CONFIGURATION; IF YOU WANT TO MODIFY ANYTHING,                 --
-- GO TO THE FOLDER AND MAKE YOUR PERSONAL CONFIGURATIONS:                          --
-- ~/.config/hypr/custom_minimalist/                                                --
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
-- Loading lib
require("hyprland.lib")
-- Loading services
require("hyprland.services")
-- Loading Animation Fast
require("hyprland.animations")
-- Loading env MinimalDtos
require("hyprland.env")
require_if_exists("custom_minimalist.env", HOME .. "/.config/hypr/custom_minimalist/env.lua")
-- Configuration hyprland (monitores)
require("hyprland.monitors")
require_if_exists("custom_minimalist.monitors", HOME .. "/.config/hypr/custom_minimalist/monitors.lua")
-- Configuration windowrules
require("hyprland.windowrules")
require_if_exists("custom_minimalist.windowrules", HOME .. "/.config/hypr/custom_minimalist/windowrules.lua")
-- Configuration general
require("hyprland.general")
require_if_exists("custom_minimalist.general", HOME .. "/.config/hypr/custom_minimalist/general.lua")
-- Atajos de teclado
require("hyprland.keybinds")
require_if_exists("custom_minimalist.keybinds", HOME .. "/.config/hypr/custom_minimalist/keybinds.lua")

local Keybinder = require("hyprland.lib.keybinder")
local vars = require("hyprland.vars")

local kb = Keybinder.new(vars.mainMod)

kb:exec("B", vars.browser,    "Abrir navegador")
kb:exec("T", vars.terminal,   "Abrir terminal")
kb:exec("E", vars.fileManager,"Abrir gestor de archivos")
kb:exec("A", vars.menu,       "Abrir menú de aplicaciones")
kb:exec("C", vars.editor,     "Abrir editor de codigo")
kb:dispatch("Q", hl.dsp.window.close(), "Cerrar ventana")
kb:dispatch("W", hl.dsp.window.float({ action = "toggle" }), "Alternar ventana flotante")
kb:dispatch("J", hl.dsp.layout("togglesplit"), "Alternar dirección del split")
kb:dispatch("mouse:272", hl.dsp.window.drag(), {mouse = true}, "Mover Ventana")
kb:dispatch("mouse:273", hl.dsp.window.resize(), {mouse = true}, "Redimensionar ventana")

-- Hypridle lock
kb:exec("L", "loginctl lock-session", "Bloquear seccion")

-- Shutdown PC and reboot
kb:exec("SHIFT+BACKSPACE", "shutdown now", "Apagar PC")
kb:exec("SHIFT+ALT+BACKSPACE", "Reboot now", "Reiniciar PC")

-- Wallpaper select
kb:exec("SHIFT+T", HOME .. "/.config/hypr/hyprland/scripts/select_wallpaper.sh", "Elegir fondo de pantalla")



kb:focus("left",  "left")
kb:focus("right", "right")
kb:focus("up",    "up")
kb:focus("down",  "down")
kb:workspaces(10)

Keybinder.media("XF86AudioRaiseVolume", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+", "Subir volumen", true)
Keybinder.media("XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",       "Bajar volumen", true)
Keybinder.media("XF86AudioMute",        "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",      "Silenciar audio", true)

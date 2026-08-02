local Keybinder = require("hyprland.lib.keybinder")
local vars = require("hyprland.vars")

local kb = Keybinder.new(vars.mainMod)

kb:exec("B", vars.browser,    "Abrir navegador / Open browser")
kb:exec("T", vars.terminal,   "Abrir terminal / Open terminal")
kb:exec("E", vars.fileManager,"Abrir gestor de archivos / Open file manager")
kb:exec("A", vars.menu,       "Abrir menú de aplicaciones / Open applications menu")
kb:exec("C", vars.editor,     "Abrir editor de codigo / Open code editor")
kb:exec("V", vars.cliphist,   "Abrir lista de portapapeles / Open clipboard list")
kb:dispatch("Q", hl.dsp.window.close(), "Cerrar ventana / Close window")
kb:dispatch("W", hl.dsp.window.float({ action = "toggle" }), "Alternar ventana flotante / Toggle floating window")
kb:dispatch("J", hl.dsp.layout("togglesplit"), "Alternar dirección del split / Toggle split direction")
kb:dispatch("mouse:272", hl.dsp.window.drag(), {mouse = true}, "Mover Ventana / Move Window")
kb:dispatch("mouse:273", hl.dsp.window.resize(), {mouse = true}, "Redimensionar ventana / Resize window")

-- Hypridle lock
kb:exec("L", vars.hyprlock, "Bloquear seccion / Lock section")

-- Shutdown PC and reboot
kb:exec("SHIFT+BACKSPACE", "shutdown now", "Apagar PC / Shut down PC")
kb:exec("SHIFT+ALT+BACKSPACE", "reboot", "Reiniciar PC / Reboot PC")

-- Wallpaper select
kb:exec("SHIFT+T", vars.select_wallpaper, "Elegir fondo de pantalla / Choose wallpaper")

-- Keybinds Show
kb:exec("SHIFT+ALT+K", vars.show_binds, "Mostrar atajos de teclado / Show keyboard shortcuts")

-- Keybinds Screenshot
kb:exec("SHIFT+P", vars.screenshot p, "Captura de pantalla completa / Full-screen screenshot")
kb:exec("S", vars.screenshot sf, "Captura de pantalla congelado / Frozen screenshot")
kb:exec("SHIFT+S", vars.screenshot sc, "Extraer texto / Extract text")
kb:exec("SHIFT+Q", vars.screenshot sq, "Escanear codigo QR / Scan QR code")


-- Keybinds audio
kb:exec("SHIFT+I", "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ && notify-send -e -u low -h string:x-canonical-private-synchronous:volume 'Volumen' \"$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}' | head -n 1)%\"", "Subir volumen / Turn up the volume")

kb:exec("SHIFT+K", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && notify-send -e -u low -h string:x-canonical-private-synchronous:volume 'Volumen' \"$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}' | head -n 1)%\"", "Bajar volumen / Lower volume")


kb:focus("left",  "left")
kb:focus("right", "right")
kb:focus("up",    "up")
kb:focus("down",  "down")
kb:workspaces(10)

Keybinder.media("XF86AudioRaiseVolume", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+", "Subir volumen / Turn up the volume", true)
Keybinder.media("XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",       "Bajar volumen / Lower volume", true)
Keybinder.media("XF86AudioMute",        "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",      "Silenciar audio / Mute audio", true)

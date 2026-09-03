local Keybinder = require("hyprland.lib.keybinder")
local vars      = require("hyprland.vars")

local kb = Keybinder.new(vars.mainMod)

-- ---------------------------------------------------------
-- APLICACIONES
-- ---------------------------------------------------------
kb:category("Aplicaciones")
  :exec("B", vars.browser,     "Abrir navegador / Open browser")
  :exec("T", vars.terminal,    "Abrir terminal / Open terminal")
  :exec("E", vars.fileManager, "Abrir gestor de archivos / Open file manager")
  :exec("A", vars.menu,        "Abrir menú de aplicaciones / Open applications menu")
  :exec("C", vars.editor,      "Abrir editor de código / Open code editor")
  :exec("V", vars.cliphist,    "Abrir lista de portapapeles / Open clipboard list")

-- ---------------------------------------------------------
-- SISTEMA Y VENTANAS
-- ---------------------------------------------------------
kb:category("Sistema")
  :dispatch("Q", hl.dsp.window.close(), "Cerrar ventana / Close window")
  :dispatch("W", hl.dsp.window.float({ action = "toggle" }), "Alternar ventana flotante / Toggle floating window")
  :dispatch("J", hl.dsp.layout("togglesplit"), "Alternar dirección del split / Toggle split direction")
  :dispatch("mouse:272", hl.dsp.window.drag(), {mouse = true}, "Mover Ventana / Move Window")
  :dispatch("mouse:273", hl.dsp.window.resize(), {mouse = true}, "Redimensionar ventana / Resize window")
  :exec("L", vars.hyprlock, "Bloquear sesión / Lock session")
  :exec("SHIFT+BACKSPACE", "shutdown now", "Apagar PC / Shut down PC")
  :exec("SHIFT+ALT+BACKSPACE", "reboot", "Reiniciar PC / Reboot PC")
  :exec("SHIFT+ALT+T", vars.select_wallpaper, "Elegir fondo de pantalla / Choose wallpaper")
  :exec("SHIFT+ALT+K", vars.show_binds, "Mostrar atajos de teclado / Show keyboard shortcuts")
  :exec("G", vars.process_manager, "Gestor de procesos / Process manager")
  :exec("U", "footclient paru -Syu --noconfirm", "Actualizar sistema con terminal / Update system via terminal")

-- ---------------------------------------------------------
-- CAPTURAS DE PANTALLA
-- ---------------------------------------------------------
kb:category("Capturas")
  :exec("SHIFT+P", vars.screenshot .. " p", "Captura de pantalla completa / Full-screen screenshot")
  :exec("SHIFT+S", vars.screenshot .. " sf", "Captura de pantalla congelado / Frozen screenshot")
  :exec("SHIFT+T", vars.screenshot .. " sc", "Extraer texto / Extract text")
  :exec("SHIFT+Q", vars.screenshot .. " sq", "Escanear código QR / Scan QR code")

-- ---------------------------------------------------------
-- GRABACIÓN DE PANTALLA
-- ---------------------------------------------------------
kb:category("Grabación")
  :exec("ALT+S", vars.screenrecord .. " s -A", "Grabar pantalla con audio (área) / Record screen with audio (area)")
  :exec("ALT+P", vars.screenrecord .. " m", "Grabar pantalla completa / Record the full screen")
  :exec("ALT+SHIFT+P", vars.screenshot .. " sc", "Detener cualquier grabación / Stop any recording")

-- ---------------------------------------------------------
-- MULTIMEDIA
-- ---------------------------------------------------------
kb:category("Multimedia")
  :exec("SHIFT+I", vars.volume_up, "Subir volumen / Turn up the volume")
  :exec("SHIFT+K", vars.volume_down, "Bajar volumen / Lower volume")
  :exec("SHIFT+M", vars.volume_mute, "Volumen muteado / Volume Mute")

Keybinder.media("XF86AudioRaiseVolume", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+", "Subir volumen / Turn up the volume", true)
Keybinder.media("XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",       "Bajar volumen / Lower volume", true)
Keybinder.media("XF86AudioMute",        "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",      "Silenciar audio / Mute audio", true)

-- ---------------------------------------------------------
-- NAVEGACIÓN Y ESPACIOS DE TRABAJO
-- ---------------------------------------------------------
kb:category("Navegación")
  :focus("left",  "left")
  :focus("right", "right")
  :focus("up",    "up")
  :focus("down",  "down")
  :workspaces(10)

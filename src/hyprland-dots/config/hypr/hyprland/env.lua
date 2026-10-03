--------------------------------------------------------------------------------------
-- NO MODIFIQUES ESTA CONFIGURACIÓN; SI DESEAS HACER CAMBIOS,                       --
-- VE A LA SIGUIENTE CARPETA Y REALIZA TUS CONFIGURACIONES PERSONALES:              --
-- ~/.config/hypr/custom/env.lua                                         --
--------------------------------------------------------------------------------------
-- Forzar el tema moderno de Hyprland
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("HYPRCURSOR_SIZE", "20")

-- Fallback para aplicaciones XWayland / Legadas
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")
hl.env("XCURSOR_SIZE", "20")


-- ==== DOLPHIN CONFIGURACION ==== --
-- Gestión de Temas Qt6 (Obligatoria para el tema oscuro de Dolphin)
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_QUICK_CONTROLS_STYLE", "org.kde.desktop")

-- Compatibilidad con Wayland (Evita parpadeos y fallos de renderizado)
hl.env("QT_QPA_PLATFORM", "wayland;xcb")

-- Integración con el Sistema y Portales de Archivos
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

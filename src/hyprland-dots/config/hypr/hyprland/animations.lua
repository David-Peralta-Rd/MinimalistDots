-- ~/.config/hypr/hyprland/animations.lua

hl.curve("quick",  { type = "bezier", points = { {0.15, 0}, {0.1, 1} } })
hl.curve("linear", { type = "bezier", points = { {0, 0},    {1, 1}  } })

local function setAnimations(list)
    for _, a in ipairs(list) do
        hl.animation(a)
    end
end

setAnimations({
    -- Ventanas
    { leaf = "global",     enabled = true, speed = 1.5, bezier = "quick" },
    { leaf = "windows",    enabled = true, speed = 1.5, bezier = "quick" },
    { leaf = "windowsIn",  enabled = true, speed = 1.2, bezier = "quick",  style = "popin 95%" },
    { leaf = "windowsOut", enabled = true, speed = 1.0, bezier = "linear", style = "popin 95%" },
    { leaf = "border",     enabled = true, speed = 1.5, bezier = "quick" },

    -- Fades (heredan a fadeIn/fadeOut si no se definen; aquí los definimos explícito)
    { leaf = "fadeIn",     enabled = true, speed = 1.0, bezier = "linear" },
    { leaf = "fadeOut",    enabled = true, speed = 1.0, bezier = "linear" },

    -- Layers: popups, menús, notificaciones
    { leaf = "layers",     enabled = true, speed = 1.2, bezier = "quick" },
    { leaf = "layersIn",   enabled = true, speed = 1.0, bezier = "quick",  style = "fade" },
    { leaf = "layersOut",  enabled = true, speed = 1.0, bezier = "linear", style = "fade" },

    -- Workspaces
    { leaf = "workspaces",    enabled = true, speed = 1.0, bezier = "linear", style = "fade" },
    { leaf = "workspacesIn",  enabled = true, speed = 1.0, bezier = "linear", style = "fade" },
    { leaf = "workspacesOut", enabled = true, speed = 1.0, bezier = "linear", style = "fade" },

    -- Zoom del overview / pinch gesture
    { leaf = "zoomFactor", enabled = true, speed = 1.5, bezier = "quick" },
})

-- ~/.config/hypr/hyprland/general.lua
local colors = require("hyprland.colors")

hl.config({
    general = {
        gaps_in     = 2,
        gaps_out    = 6,
        border_size = 1,
        col = {
            active_border   = colors.border_active.hypr,
            inactive_border = colors.border_inactive.hypr,
        },
        resize_on_border = true,   -- útil para trabajo rápido con mouse
        allow_tearing    = false,
        layout           = "dwindle",
    },
    decoration = {
        rounding       = 3,        -- casi sin curvas, minimalista
        rounding_power = 2,
        active_opacity   = 1.0,
        inactive_opacity = 0.97,   -- diferencia sutil, ayuda a ubicar la ventana activa sin distraer
        shadow = {
            enabled = false,       -- fuera: menos carga visual y de GPU
        },
        blur = {
            enabled = false,       -- fuera: mismo criterio, prioriza velocidad sobre efectos
        },q
    },
    dwindle = {
        preserve_split = true,
    },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
    },
})



-- Configuration keyboard
hl.config({
    input = {
        kb_layout = "us",
        numlock_by_default = true,
        repeat_delay = 170,
        repeat_rate = 50,

        follow_mouse = 1,
        off_window_axis_events = 2,

        touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
            clickfinger_behavior = true,
            scroll_factor = 0.7
        },

	sensitivity = -0.8,
	accel_profile = flat
    }
})

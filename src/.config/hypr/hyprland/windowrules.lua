local Rules = require("hyprland.lib.rules")

Rules.forClass(".*"):noBlur()
Rules.forClass("^(pavucontrol)$"):float()
Rules.forClass("^(blueman%-manager)$"):float()

Rules.forClass("hyprland-run"):custom({
    name  = "move-hyprland-run",
    move  = "20 monitor_h-120",
    float = true,
})

-- Reglas para imv y mpv (imágenes y videos)
Rules.forClass("imv"):custom({ float = true, size = "70% 70%", center = true })
Rules.forClass("mpv"):custom({ float = true, size = "60% 60%", center = true })

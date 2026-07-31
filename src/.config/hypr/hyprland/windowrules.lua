local Rules = require("hyprland.lib.rules")

Rules.forClass(".*"):noBlur()
Rules.forClass("^(pavucontrol)$"):float()
Rules.forClass("^(blueman%-manager)$"):float()

Rules.forClass("hyprland-run"):custom({
    name  = "move-hyprland-run",
    move  = "20 monitor_h-120",
    float = true,
})


-- Rules para mvp y imv(imagenes y videos)
local imv = Rules.forClass("imv")
imv:custom({ float = true, size = "70% 70%", center = true })

local mpv = Rules.forClass("mpv")
mpv:custom({ float = true, size = "60% 60%", center = true })

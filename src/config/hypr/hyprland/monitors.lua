------------------
---- MONITORS ----
------------------

-- Monitor por defecto: autodetecta resolución preferida y lo ubica en 0x0.
-- Para setups personalizados (multi-monitor, escalado, etc.) usa el override:
-- ~/.config/hypr/custom_minimalist/monitors.lua
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "0x0",
    scale    = "1",
})

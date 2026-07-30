-- ~/.config/hypr/hyprland/colors.lua
-- Paleta oscura minimalista.

local function rgba(hex, alpha)
    alpha = alpha or "ee"
    return "rgba(" .. hex .. alpha .. ")"
end

return {
    background      = { hex = "#1e1e2e", hypr = rgba("1e1e2e") },
    surface         = { hex = "#313244", hypr = rgba("313244") },
    border_inactive = { hex = "#585b70", hypr = rgba("585b70", "aa") },
    border_active   = { hex = "#89b4fa", hypr = rgba("89b4fa") },
    text            = { hex = "#cdd6f4", hypr = rgba("cdd6f4") },
}

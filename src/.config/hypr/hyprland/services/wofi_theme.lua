-- ~/.config/hypr/hyprland/services/wofi_theme.lua
local Service = require("hyprland.lib.services")
local colors  = require("hyprland.colors")

local CONFIG_DIR = os.getenv("HOME") .. "/.config/wofi"

local function write_config()
    local config = [[
# ~/.config/wofi/config
show=drun
allow_images=true
image_size=20
width=500
# Controla la cantidad de elementos visibles (5 programas)
lines=10
# Posiciona el menú arriba en el centro
location=top
yoffset=20
# Oculta elementos estéticos innecesarios
hide_scroll=true
print_command=true
]]
    local f = io.open(CONFIG_DIR .. "/config", "w")
    if f then f:write(config) f:close() end
end

local function write_style()
    local css = string.format([[
/* ~/.config/wofi/style.css */

/* Ventana principal */
window {
    margin: 0px;
    background-color: rgba(30, 30, 46, 0.85); /* #1e1e2e con 85% de opacidad */
    border: 2px solid #89b4fa; /* border_active */
    border-radius: 12px; /* Esquinas suavizadas */
    font-family: 'Inter', 'JetBrains Mono', 'monospace';
    font-size: 14px;
}

/* Caja de búsqueda */
#input {
    margin: 12px 12px 6px 12px;
    border: 1px solid #585b70; /* border_inactive */
    border-radius: 8px;
    background-color: rgba(49, 50, 68, 0.7); /* surface opaco */
    color: #cdd6f4; /* text */
    padding: 8px;
}

/* Contenedor de la lista */
#inner-box {
    margin: 6px 12px 12px 12px;
    border: none;
    background-color: transparent;
}

/* Cada fila de programa */
#entry {
    padding: 6px 8px;
    background-color: transparent;
    border-radius: 6px;
    border: none;
}

/* Elemento seleccionado con cambio suave */
#entry:selected {
    background-color: rgba(49, 50, 68, 0.9); /* surface resaltado */
    transition: background-color 0.1s ease-in-out; /* Suavizado de selección */
}

/* Iconos de las apps */
#img {
    margin-right: 10px;
}

/* Texto de las apps */
#text {
    color: #cdd6f4; /* text */
    background-color: transparent;
}

#text:selected {
    color: #89b4fa; /* border_active como acento */
    font-weight: bold;
}

/* Limpieza de contenedores ocultos */
#outer-box { margin: 0px; border: none; background-color: transparent; }
#scroll { margin: 0px; border: none; background-color: transparent; }

]],
        colors.surface.hex, colors.border_inactive.hex,
        colors.background.hex, colors.text.hex,
        colors.border_inactive.hex,
        colors.text.hex)

    local f = io.open(CONFIG_DIR .. "/style.css", "w")
    if f then f:write(css) f:close() end
end

return Service.define("wofi_theme", function()
    hl.on("hyprland.start", function()
        os.execute("mkdir -p " .. CONFIG_DIR)
        write_config()
        write_style()
    end)
end)

require("load_direction")

local Service = require("hyprland.lib.services")

local WALLPAPER_DIR = os.getenv("HOME") .. "/multimedia/pictures/wallpapers"
local STATE_FILE = os.getenv("HOME") .. "/.cache/hypr/current_wallpaper"

-- Función para obtener un wallpaper aleatorio desde la carpeta
local function get_random_wallpaper()
    local pfile = io.popen(string.format('find "%s" -maxdepth 1 -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \\)', WALLPAPER_DIR))
    if not pfile then return nil end

    local files = {}
    for file in pfile:lines() do
        table.insert(files, file)
    end
    pfile:close()

    if #files == 0 then return nil end

    -- Semilla aleatoria utilizando el tiempo del sistema
    math.randomseed(os.time())
    return files[math.random(#files)]
end

local function save_wallpaper(path)
    local f = io.open(STATE_FILE, "w")
    if f then
        f:write(path .. "\n")
        f:close()
    end
end

return Service.define("wallpaper", function()
    hl.on("hyprland.start", function()
        os.execute("mkdir -p " .. WALLPAPER_DIR)
        os.execute("mkdir -p " .. os.getenv("HOME") .. "/.cache/hypr")

        -- Iniciar hyprpaper
        hl.exec_cmd("hyprpaper")

        -- Elegir un wallpaper aleatorio cada vez que inicia el sistema
        local selected = get_random_wallpaper()

        if selected then
            save_wallpaper(selected)
            -- Precargar y aplicar en hyprpaper
            hl.exec_cmd(string.format('sleep 0.5 && hyprctl hyprpaper preload "%s" && hyprctl hyprpaper wallpaper ",%s,fill"', selected, selected))
        end
    end)
end)

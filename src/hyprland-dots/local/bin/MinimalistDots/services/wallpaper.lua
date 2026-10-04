require("load_direction")

local Service = require("hyprland.lib.services")

local WALLPAPER_DIR = os.getenv("HOME") .. "/multimedia/pictures/wallpapers"
local STATE_FILE = os.getenv("HOME") .. "/.cache/hypr/current_wallpaper"
local SCRIPT_PATH = os.getenv("HOME") .. "/.local/bin/MinimalistDots/scripts/select_wallpaper.sh"

return Service.define("wallpaper", function()
    hl.on("hyprland.start", function()
        os.execute("mkdir -p " .. WALLPAPER_DIR)
        os.execute("mkdir -p " .. os.getenv("HOME") .. "/.cache/hypr")

        -- Iniciar daemon de wallpapers
        hl.exec_cmd("hyprpaper")

        -- Ejecutar el script con el flag aleatorio tras 1 segundo
        hl.exec_cmd(string.format('sleep 1 && bash "%s" --random', SCRIPT_PATH))
    end)
end)

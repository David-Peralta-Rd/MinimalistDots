require("load_direction")


local Service = require("hyprland.lib.services")

local WALLPAPER_DIR = os.getenv("HOME") .. "/multimedia/pictures/wallpapers"
local STATE_FILE = os.getenv("HOME") .. "/.cache/hypr/current_wallpaper"

local function read_last_wallpaper()
    local f = io.open(STATE_FILE, "r")
    if not f then return nil end
    local path = f:read("*l")
    f:close()
    return path
end

return Service.define("wallpaper", function()
    hl.on("hyprland.start", function()
        os.execute("mkdir -p " .. WALLPAPER_DIR)
        os.execute("mkdir -p " .. os.getenv("HOME") .. "/.cache/hypr")

        hl.exec_cmd("hyprpaper")

        local last = read_last_wallpaper()
        if last and is_file_exists(last) then
            hl.exec_cmd(string.format('sleep 1 && hyprctl hyprpaper wallpaper ",%s,fill"', last))
        end
    end)
end)

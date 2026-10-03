-- ~/.config/hypr/hyprland/lib/init.lua
_G.HOME = os.getenv("HOME")

function _G.is_file_exists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

-- Comprueba si un módulo existe antes de cargarlo
function _G.require_if_exists(modulePath, filePath)
    if is_file_exists(filePath) then
        local ok, err = pcall(require, modulePath)
        if not ok then
            print("[custom] Error al cargar " .. modulePath .. ": " .. tostring(err))
        end
    end
end

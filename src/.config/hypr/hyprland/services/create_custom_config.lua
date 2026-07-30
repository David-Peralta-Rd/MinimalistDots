-- ~/.config/hypr/lua/services/create_custom_config.lua
local Service = require("hyprland.lib.services")

local CUSTOM_DIR   = HOME .. "/.config/hypr/custom_minimalist"
local SERVICES_DIR = CUSTOM_DIR .. "/services"

local overrides = { "animations", "colors", "env", "general", "keybinds", "monitors", "vars", "windowrules" }

-- Crea un archivo override vacío, listo para editar, si aún no existe
local function ensure_override_file(name)
    local path = CUSTOM_DIR .. "/" .. name .. ".lua"
    if not is_file_exists(path) then
        local f = io.open(path, "w")
        if f then
            f:write("-- override de '" .. name .. "', seguro de editar\nreturn {}\n")
            f:close()
        end
    end
end

-- Escanea custom_minimalist/services/ y regenera su init.lua con un
-- require por cada archivo .lua encontrado. No edites ese init a mano:
-- se sobreescribe cada inicio de sesión.
local function regenerate_services_init()
    local lines = {
        "-- Autogenerado por create_custom_config. No editar a mano.",
        "-- Para agregar un servicio nuevo: crea un .lua en esta carpeta.",
        "",
    }

    local pipe = io.popen('ls "' .. SERVICES_DIR .. '" 2>/dev/null')
    if pipe then
        for filename in pipe:lines() do
            if filename:match("%.lua$") and filename ~= "init.lua" then
                local modname = filename:gsub("%.lua$", "")
                lines[#lines + 1] = 'require("custom_minimalist.services.' .. modname .. '")'
            end
        end
        pipe:close()
    end

    local f = io.open(SERVICES_DIR .. "/init.lua", "w")
    if f then
        f:write(table.concat(lines, "\n") .. "\n")
        f:close()
    end
end

return Service.define("create_custom_config", function()
    hl.on("hyprland.start", function()
        os.execute('mkdir -p "' .. CUSTOM_DIR .. '"')
        os.execute('mkdir -p "' .. SERVICES_DIR .. '"')

        for _, name in ipairs(overrides) do
            ensure_override_file(name)
        end

        regenerate_services_init()
    end)
end)

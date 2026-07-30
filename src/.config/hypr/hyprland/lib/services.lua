-------------------
---- SERVICES  ----
-------------------

-- ~/.config/hypr/hyprland/lib/services.lua
local Service = {}
Service.__index = Service

local registry = {}

-- Define un servicio. Devuelve un handle, así lo puedes deshabilitar desde custom/
function Service.define(name, fn)
    local self = setmetatable({ name = name, fn = fn, enabled = true }, Service)
    table.insert(registry, self)
    return self
end

function Service:set_enabled(bool)
    self.enabled = bool
    return self
end

-- Ejecuta todos los servicios registrados. Un servicio roto no tumba los demás.
function Service.run_all()
    for _, svc in ipairs(registry) do
        if svc.enabled then
            local ok, err = pcall(svc.fn)
            if not ok then
                print("[services] '" .. svc.name .. "' failed: " .. tostring(err))
            end
        end
    end
end

return Service

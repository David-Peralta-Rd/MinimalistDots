-- ~/.config/hypr/hyprland/lib/services.lua
local Service = {}
Service.__index = Service

local registry = {}

function Service.define(name, fn)
    local self = setmetatable({ name = name, fn = fn, enabled = true }, Service)
    table.insert(registry, self)
    return self
end

function Service:set_enabled(bool)
    self.enabled = bool
    return self
end

function Service.run_all()
    for _, svc in ipairs(registry) do
        if svc.enabled then
            local ok, err = pcall(svc.fn)
            if not ok then
                print("[services] '" .. svc.name .. "' falló: " .. tostring(err))
            end
        end
    end
end

return Service

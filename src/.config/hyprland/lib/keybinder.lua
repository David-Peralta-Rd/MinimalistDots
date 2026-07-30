-- ~/.config/hypr/lua/lib/keybinder.lua
local Keybinder = {}
Keybinder.__index = Keybinder

-- Registro COMPARTIDO por todas las instancias (kb, kbShift, etc.)
local registry = {}

local function register(mod, key, description, kind)
    table.insert(registry, {
        mod         = mod,
        key         = key,
        description = description or "(sin descripción)",
        kind        = kind,
    })
end

function Keybinder.new(mainMod)
    return setmetatable({ mainMod = mainMod }, Keybinder)
end

function Keybinder:exec(key, cmd, description, opts)
    register(self.mainMod, key, description, "exec")
    hl.bind(self.mainMod .. " + " .. key, hl.dsp.exec_cmd(cmd), opts)
    return self
end

function Keybinder:dispatch(key, dispatcher, description, opts)
    register(self.mainMod, key, description, "dispatch")
    hl.bind(self.mainMod .. " + " .. key, dispatcher, opts)
    return self
end

-- Estos ya generan su propia descripción legible, así no repites texto
-- cada vez que enfocas o mueves una ventana.
function Keybinder:focus(key, direction)
    return self:dispatch(key, hl.dsp.focus({ direction = direction }), "Enfocar ventana: " .. direction)
end

function Keybinder:moveWindow(key, direction)
    return self:dispatch(key, hl.dsp.window.move({ direction = direction }), "Mover ventana: " .. direction)
end

function Keybinder:workspaces(count)
    count = count or 10
    for i = 1, count do
        local key = i % 10
        self:dispatch(key,               hl.dsp.focus({ workspace = i }),      "Ir al escritorio " .. i)
        self:dispatch("SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), "Mover ventana al escritorio " .. i)
    end
    return self
end

function Keybinder:with(extraMod)
    return Keybinder.new(self.mainMod .. " + " .. extraMod)
end

-- Las teclas multimedia no tienen mainMod (usan la tecla XF86 directa)
function Keybinder.media(key, cmd, description, repeating)
    register("", key, description, "media")
    hl.bind(key, hl.dsp.exec_cmd(cmd), { locked = true, repeating = repeating or false })
end

-- Exporta todo lo registrado a un JSON simple que tu futura interfaz pueda leer
function Keybinder.export_json(path)
    path = path or (os.getenv("HOME") .. "/.cache/hypr/keybinds.json")

    local function escape(s)
        return tostring(s):gsub('[\\"]', '\\%0'):gsub('\n', '\\n')
    end

    local lines = { "[" }
    for i, entry in ipairs(registry) do
        local comma = (i < #registry) and "," or ""
        lines[#lines + 1] = string.format(
            '  { "mod": "%s", "key": "%s", "description": "%s", "kind": "%s" }%s',
            escape(entry.mod), escape(entry.key), escape(entry.description), escape(entry.kind), comma
        )
    end
    lines[#lines + 1] = "]"

    local f = io.open(path, "w")
    if f then
        f:write(table.concat(lines, "\n"))
        f:close()
    end
end

return Keybinder

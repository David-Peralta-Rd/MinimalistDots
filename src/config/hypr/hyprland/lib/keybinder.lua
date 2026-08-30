-- ~/.config/hypr/hyprland/lib/keybinder.lua
local Keybinder = {}
Keybinder.__index = Keybinder

local registry = {}

-- Modificado: incluye el parámetro 'category'
local function register(mod, key, description, kind, category)
    table.insert(registry, {
        mod         = mod,
        key         = key,
        description = description or "(sin descripción)",
        kind        = kind,
        category    = category or "General",
    })
end

function Keybinder.new(mainMod)
    return setmetatable({ mainMod = mainMod, current_category = "General" }, Keybinder)
end

-- Asigna una categoría para los siguientes bindeos en bloque
function Keybinder:category(cat_name)
    self.current_category = cat_name
    return self
end

function Keybinder:exec(key, cmd, description, opts)
    register(self.mainMod, key, description, "exec", self.current_category)
    hl.bind(self.mainMod .. " + " .. key, hl.dsp.exec_cmd(cmd), opts)
    return self
end

function Keybinder:dispatch(key, dispatcher, description, opts)
    register(self.mainMod, key, description, "dispatch", self.current_category)
    hl.bind(self.mainMod .. " + " .. key, dispatcher, opts)
    return self
end

function Keybinder:focus(key, direction)
    return self:dispatch(key, hl.dsp.focus({ direction = direction }), "Enfocar ventana: " .. direction)
end

function Keybinder:moveWindow(key, direction)
    return self:dispatch(key, hl.dsp.window.move({ direction = direction }), "Mover ventana: " .. direction)
end

function Keybinder:workspaces(count)
    count = count or 10
    local old_cat = self.current_category
    self.current_category = "Workspaces"
    for i = 1, count do
        local key = i % 10
        self:dispatch(tostring(key), hl.dsp.focus({ workspace = i }), "Ir al escritorio " .. i)
        self:dispatch("SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), "Mover ventana al escritorio " .. i)
    end
    self.current_category = old_cat
    return self
end

function Keybinder:with(extraMod)
    local new_kb = Keybinder.new(self.mainMod .. " + " .. extraMod)
    new_kb.current_category = self.current_category
    return new_kb
end

function Keybinder.media(key, cmd, description, repeating)
    register("", key, description, "media", "Multimedia")
    hl.bind(key, hl.dsp.exec_cmd(cmd), { locked = true, repeating = repeating or false })
end

-- Exporta el JSON estructurado por categorías para que Rofi/Wofi lo consuma fácil
function Keybinder.export_json(path)
    path = path or (os.getenv("HOME") .. "/.cache/hypr/keybinds.json")

    local function escape(s)
        return tostring(s):gsub('[\\"]', '\\%0'):gsub('\n', '\\n')
    end

    local dir = path:match("(.+)/")
    if dir then os.execute("mkdir -p " .. dir) end

    local lines = { "[" }
    for i, entry in ipairs(registry) do
        local comma = (i < #registry) and "," or ""
        lines[#lines + 1] = string.format(
            '  { "category": "%s", "mod": "%s", "key": "%s", "description": "%s", "kind": "%s" }%s',
            escape(entry.category), escape(entry.mod), escape(entry.key), escape(entry.description), escape(entry.kind), comma
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

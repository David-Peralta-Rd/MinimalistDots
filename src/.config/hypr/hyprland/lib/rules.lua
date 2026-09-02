-- ~/.config/hypr/hyprland/lib/rules.lua
local Rules = {}
Rules.__index = Rules

function Rules.forClass(classPattern)
    return setmetatable({ match = { class = classPattern } }, Rules)
end

function Rules:float()
    hl.window_rule({ match = self.match, float = true })
    return self
end

function Rules:noBlur()
    hl.window_rule({ match = self.match, no_blur = true })
    return self
end

function Rules:opacity(active, inactive)
    hl.window_rule({ match = self.match, active_opacity = active, inactive_opacity = inactive })
    return self
end

function Rules:custom(props)
    hl.window_rule((function()
        local t = { match = self.match }
        for k, v in pairs(props) do t[k] = v end
        return t
    end)())
    return self
end

return Rules

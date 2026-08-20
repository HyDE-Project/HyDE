local E = {
    vars = {}
}

local function set_env(name, value)
    if type(name) ~= "string" then
        return nil
    end

    if value == nil then
        if E.vars[name] ~= nil then
            return E.vars[name]
        end
        return os.getenv(name)
    end

    E.vars[name] = tostring(value)
    return E.vars[name]
end

local function set_optional(name, value)
    if type(name) ~= "string" then
        return nil
    end

    if value == nil then
        return set_env(name, nil)
    end

    if E.vars[name] ~= nil then
        return E.vars[name]
    end

    local current = os.getenv(name)
    if current ~= nil then
        return current
    end

    E.vars[name] = tostring(value)
    return E.vars[name]
end

setmetatable(E, {
    __call = function(self, name, value)
        return set_env(name, value)
    end,
})

function E.optional(name, value)
    return set_optional(name, value)
end

function E.finalize()
    if type(hl) ~= "table" or type(hl.env) ~= "function" then
        return
    end

    for name, value in pairs(E.vars) do
        hl.env(name, value)
    end
end

_G.hyde = _G.hyde or {}
_G.hyde.env = E

return E

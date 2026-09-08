-- Bind dedup wrapper for Hyprland Lua keybinds.
--
-- This module normalizes keycombo strings and tracks active binds in
-- hyde.binds._active. It deduplicates bindings only when
-- hyde.binds.dedup is enabled, and only for bindings with the same
-- normalized key combo and the same values for configured dedup fields.
-- Description-only metadata is ignored for dedup signature generation.
--
-- Default dedup fields are based on Hyprland bind flags:
--   https://wiki.hypr.land/Configuring/Basics/Binds/#bind-flags
--
-- Default fields:
--   locked, release, click, drag, long_press, repeating,
--   non_consuming, auto_consuming, transparent, ignore_mods,
--   separate, bypass, submap_universal, devices
--
-- TODO: check the Hyprland bind flags documentation periodically and
-- update the dedup field list when new relevant bind flags are added.

-- type(x) == "function" misses the common binding pattern of a table made
-- callable via a __call metamethod, which is what hl.dsp.exec_cmd turns out
-- to be (both the native one and the test stub in tests/lua/bind_harness.lua
-- model it that way).
local function is_callable(value)
    if type(value) == "function" then
        return true
    end
    local mt = getmetatable(value)
    return type(mt) == "table" and type(mt.__call) == "function"
end

local function trim(str)
    return str and str:gsub("^%s+", ""):gsub("%s+$", "") or ""
end

local function normalize(keycombo)
    if type(keycombo) ~= "string" then
        return ""
    end
    return trim(keycombo:gsub("%s*%+%s*", " + "))
end

-- Modifier spellings Hyprland treats as the same bit.
local modifier_aliases = {
    CONTROL = "CTRL",
    WIN = "SUPER",
    LOGO = "SUPER",
    MOD1 = "ALT",
    MOD4 = "SUPER"
}

-- Reduces a combo to the form Hyprland actually matches on: modifiers are a
-- set, so spelling, order and case carry no meaning. "SUPER + CTRL + Left"
-- and "SUPER + CONTROL + LEFT" both become "CTRL + SUPER + LEFT", which is
-- what makes them collide at runtime.
local function canonicalize(keycombo)
    local normalized = normalize(keycombo)
    if normalized == "" then
        return ""
    end

    local tokens = {}
    for token in normalized:gmatch("[^+]+") do
        tokens[#tokens + 1] = trim(token)
    end

    local key = table.remove(tokens) or ""

    local modifiers = {}
    local seen = {}
    for _, token in ipairs(tokens) do
        local upper = token:upper()
        local modifier = modifier_aliases[upper] or upper
        if not seen[modifier] then
            seen[modifier] = true
            modifiers[#modifiers + 1] = modifier
        end
    end
    table.sort(modifiers)

    modifiers[#modifiers + 1] = key:upper()
    return table.concat(modifiers, " + ")
end

-- Minimal encoder for a flat string->string table -- the only shape
-- hyde.binds._commands ever holds. Not a general JSON encoder: no nesting,
-- no numbers, no booleans. Written locally instead of pulling in
-- Configs/.local/lib/hyde/luautils/json.lua because that tree is not on
-- package.path here -- this file runs inside Hyprland's own embedded Lua,
-- a separate interpreter from the one hyde-shell sets up for standalone
-- scripts like gpuinfo.lua.
local function encode_flat_string_map(map)
    local function escape(str)
        return (
            str:gsub(
                '[\\"%c]',
                function(c)
                    if c == "\\" then
                        return "\\\\"
                    elseif c == '"' then
                        return '\\"'
                    elseif c == "\n" then
                        return "\\n"
                    elseif c == "\t" then
                        return "\\t"
                    elseif c == "\r" then
                        return "\\r"
                    end
                    return string.format("\\u%04x", c:byte())
                end
            )
        )
    end

    local parts = {}
    for key, value in pairs(map) do
        parts[#parts + 1] = '"' .. escape(key) .. '":"' .. escape(value) .. '"'
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

local function has_dedup_field(opts)
    if type(opts) ~= "table" then
        return false
    end

    local fields = hyde.binds.dedup_fields
    if type(fields) ~= "table" then
        return false
    end

    for _, field in ipairs(fields) do
        if opts[field] ~= nil then
            return true
        end
    end

    return false
end

local function find_options(...)
    for i = select("#", ...), 1, -1 do
        local arg = select(i, ...)
        if type(arg) == "table" and has_dedup_field(arg) then
            return arg
        end
    end
    return nil
end

local function serialize_flags(opts)
    if type(opts) ~= "table" then
        return ""
    end

    local fields = hyde.binds.dedup_fields
    if type(fields) ~= "table" or #fields == 0 then
        return ""
    end

    local parts = {}
    for _, field in ipairs(fields) do
        local value = opts[field]
        if value ~= nil then
            parts[#parts + 1] = field .. "=" .. tostring(value)
        end
    end

    if #parts == 0 then
        return ""
    end

    return table.concat(parts, "|")
end

hyde = hyde or {}
hyde.binds = hyde.binds or {}

hyde.binds.dedup = hyde.binds.dedup == nil and false or hyde.binds.dedup
hyde.binds.dedup_fields =
    hyde.binds.dedup_fields or
    {
        "locked",
        "release",
        "click",
        "drag",
        "long_press",
        "repeating",
        "non_consuming",
        "auto_consuming",
        "transparent",
        "ignore_mods",
        "separate",
        "bypass",
        "submap_universal",
        "devices"
    }

hyde.binds.normalize = normalize
hyde.binds.canonicalize = canonicalize

-- Maps a canonical combo to the exact string the live bind was registered
-- with. Unbinding matches that string, not the resolved key and modifiers, so
-- the original spelling has to be kept around to remove a bind again.
hyde.binds._active = hyde.binds._active or {}

-- Resolves __lua binds back to a launchable command for the keybind-hint
-- menu (#1996). Hyprland exposes every hl.bind() action over hyprctl as an
-- opaque "__lua" registry reference with no way to invoke it externally,
-- except by re-emitting a fresh hl.dsp.exec_cmd("...") call -- so
-- hint-hyprland.py needs the original command string for binds built that
-- way. Lua evaluates hl.dsp.exec_cmd(cmd) fully before hl.bind(combo, <that
-- result>, opts) runs, so wrapping exec_cmd to remember only the command it
-- was just called with, then having hl.bind read-and-clear that value
-- immediately, pairs the two correctly without inspecting what exec_cmd
-- actually returns. A bind built any other way -- a plain Lua function, a
-- native dispatcher called directly -- never sets it and stays unresolved,
-- which is the documented limit: those can't be reduced to one command.
hyde.binds._commands = hyde.binds._commands or {}

local pending_command
if type(hl.dsp) == "table" and is_callable(hl.dsp.exec_cmd) then
    local orig_exec_cmd = hl.dsp.exec_cmd
    hl.dsp.exec_cmd = function(command, ...)
        pending_command = command
        return orig_exec_cmd(command, ...)
    end
end

local orig_add = hl.bind

hl.bind = function(keycombo, action, ...)
    local command = pending_command
    pending_command = nil

    local normalized = hyde.binds.normalize(keycombo)
    local opts = find_options(...)
    local signature = serialize_flags(opts)
    local dedup_id = canonicalize(keycombo) .. "|" .. signature

    if normalized ~= "" and hyde.binds.dedup then
        local registered = hyde.binds._active[dedup_id]
        if registered then
            hl.unbind(registered)
        end
    end

    if normalized ~= "" then
        hyde.binds._active[dedup_id] = normalized
        keycombo = normalized
    end

    if normalized ~= "" and type(command) == "string" and command ~= "" then
        hyde.binds._commands[canonicalize(keycombo)] = command
    end

    return orig_add(keycombo, action, ...)
end

-- Written once per full config (re)load, not per-bind: hl.bind() runs on the
-- order of seventy times in a row during one load, and hint-hyprland.py only
-- ever reads this after a load has already finished, so only the state after
-- the last call matters. "config.reloaded" covers every later
-- `hyprctl reload`; "hyprland.start" covers the very first load, which never
-- fires as a reload.
local function write_commands_cache()
    if type(hyde.path) ~= "table" or type(hyde.path.cache) ~= "string" then
        return
    end

    local file = io.open(hyde.path.cache .. "/hyde/lua_bind_commands.json", "w")
    if not file then
        return
    end

    file:write(encode_flat_string_map(hyde.binds._commands))
    file:close()
end

hyde.binds._write_commands_cache = write_commands_cache

if type(hl.on) == "function" then
    hl.on("hyprland.start", write_commands_cache)
    hl.on("config.reloaded", write_commands_cache)
end

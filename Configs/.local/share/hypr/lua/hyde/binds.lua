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

-- Minimal encoder for a flat string->string table -- the shape of the action
-- manifest hyde.binds exports. Not a general JSON encoder: no nesting,
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

-- Every registered bind's own action, keyed by the Lua registry reference
-- Hyprland reports for it over `hyprctl binds` (handle.arg). The reference is
-- what identifies one bind: a combo can carry a press and a release bind, the
-- same combo repeats across submaps, and Hyprland reuses a reference once its
-- bind is gone. `token` pins one registration, so a hint cache from an earlier
-- load -- or from a reference that was since rebound -- is refused instead of
-- running another bind's action.
--
-- `hyprctl dispatch` evaluates its argument in this same Lua state and
-- hl.dispatch accepts the same actions hl.bind does, so the keybind-hint menu
-- runs a bind with `hyde.binds.action("<ref>", "<token>")`.
hyde.binds._actions = {}

-- Unique per loaded module, so tokens of an earlier load never match again.
local generation = tostring({}) .. ":" .. tostring(os.clock())
local sequence = 0

hyde.binds.action = function(ref, token)
    local entry = hyde.binds._actions[tostring(ref)]
    if entry == nil or entry.token ~= token then
        error("hyde.binds.action: stale or unknown bind reference " .. tostring(ref) .. ", reopen the keybind hint")
    end
    if type(entry.handle.is_enabled) ~= "function" then
        error("hyde.binds.action: this Hyprland exposes no bind state for " .. tostring(ref))
    end
    local enabled = entry.handle:is_enabled()
    if enabled == nil then
        error("hyde.binds.action: bind reference " .. tostring(ref) .. " has expired")
    end
    if not enabled then
        error("hyde.binds.action: bind reference " .. tostring(ref) .. " is disabled")
    end
    return entry.action
end

local orig_add = hl.bind
local warned_missing_ref = false

hl.bind = function(keycombo, action, ...)
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

    local handle = orig_add(keycombo, action, ...)

    if handle ~= nil and action ~= nil then
        local ref = handle.arg
        if ref == nil then
            -- Older Hyprland exposes no registry reference, so there is
            -- nothing the hint menu could replay. Say so once rather than
            -- guessing an identity from the combo.
            if not warned_missing_ref then
                warned_missing_ref = true
                io.stderr:write(
                    "hyde.binds: hl.bind() exposes no handle.arg; the keybind hint cannot replay Lua binds\n"
                )
            end
        else
            sequence = sequence + 1
            hyde.binds._actions[tostring(ref)] = {
                action = action,
                handle = handle,
                token = generation .. ":" .. sequence
            }
        end
    end

    return handle
end

-- Written once per full config (re)load, not per-bind: hl.bind() runs on the
-- order of seventy times in a row during one load, and hint-hyprland.py only
-- ever reads this after a load has already finished, so only the state after
-- the last call matters. "config.reloaded" covers every later
-- `hyprctl reload`; "hyprland.start" covers the very first load, which never
-- fires as a reload.
local function _write_actions_cache()
    if type(hyde.path) ~= "table" or type(hyde.path.cache) ~= "string" then
        return
    end

    local tokens = {}
    for ref, entry in pairs(hyde.binds._actions) do
        tokens[ref] = entry.token
    end

    -- The hint script only ever reads a finished manifest, so write beside it
    -- and rename: a failure leaves the previous load's manifest intact
    -- instead of truncating it.
    local manifest_path = hyde.path.cache .. "/hyde/lua_bind_actions.json"
    local tmp_path = manifest_path .. ".tmp"
    local file, open_error = io.open(tmp_path, "w")
    if not file then
        io.stderr:write("hyde.binds: cannot write " .. tmp_path .. ": " .. tostring(open_error) .. "\n")
        return
    end

    local written, write_error = file:write(encode_flat_string_map(tokens))
    local closed, close_error = file:close()
    if not written or not closed then
        os.remove(tmp_path)
        io.stderr:write(
            "hyde.binds: cannot write " .. tmp_path .. ": " .. tostring(write_error or close_error) .. "\n"
        )
        return
    end

    local renamed, rename_error = os.rename(tmp_path, manifest_path)
    if not renamed then
        os.remove(tmp_path)
        io.stderr:write("hyde.binds: cannot replace " .. manifest_path .. ": " .. tostring(rename_error) .. "\n")
    end
end

hyde.binds._write_actions_cache = _write_actions_cache

if type(hl.on) == "function" then
    hl.on("hyprland.start", _write_actions_cache)
    hl.on("config.reloaded", _write_actions_cache)
end

-- luautils/global/state.lua
-- Shared state I/O for HyDE Lua scripts.
--
-- Provides two independent state channels:
--   staterc  — the shell-compatible $XDG_STATE_HOME/hyde/staterc file
--              (KEY="value" format, shared with shell and Python)
--   lua_state — per-selector .lua stub files under $XDG_STATE_HOME/hyde/lua_state/
--              (fast dofile-based cache, Lua-only)
--
-- Usage:
--   local state = require("luautils.global.state")
--
--   state.staterc_get("HYPR_WORKFLOW")            → "gaming" or nil
--   state.staterc_set("HYPR_WORKFLOW", "gaming")  → writes staterc
--
--   state.read("/path/to/mymodule.lua")           → item table or nil
--   state.write("/state/dir", "/state/file.lua", item)

local lfs = require("lfs")
local xdg = require("luautils.xdg")

local S = {}

-- ── internal ──────────────────────────────────────────────────────────────────

local function ensure_dir(path)
    local current = ""
    for part in path:gmatch("[^/]+") do
        current = current .. "/" .. part
        lfs.mkdir(current)
    end
end

-- ── staterc (shell-compatible, shared with shell/Python) ─────────────────────

local staterc_path = xdg.state .. "/hyde/staterc"

--- Read a value from staterc. Returns the unquoted string or nil.
function S.staterc_get(key)
    local f = io.open(staterc_path, "r")
    if not f then
        return nil
    end
    for line in f:lines() do
        local v = line:match("^" .. key .. '="?(.-)"%s*$') or line:match("^" .. key .. "=(.-)%s*$")
        if v then
            f:close()
            return v
        end
    end
    f:close()
    return nil
end

--- Write (or replace) a key in staterc in bash KEY="value" format.
function S.staterc_set(key, value)
    ensure_dir(xdg.state .. "/hyde")
    local lines = {}
    local found = false
    local f = io.open(staterc_path, "r")
    if f then
        for line in f:lines() do
            if line:match("^" .. key .. "=") then
                lines[#lines + 1] = key .. '="' .. tostring(value) .. '"'
                found = true
            else
                lines[#lines + 1] = line
            end
        end
        f:close()
    end
    if not found then
        lines[#lines + 1] = key .. '="' .. tostring(value) .. '"'
    end
    local out = assert(io.open(staterc_path, "w"))
    out:write(table.concat(lines, "\n") .. "\n")
    out:close()
end

-- ── lua_state (fast Lua-only cache, per-selector .lua stub files) ─────────────

--- Read a lua_state stub file. Returns the item table or nil.
function S.read(state_file)
    if not lfs.attributes(state_file) then
        return nil
    end
    local ok, result = pcall(dofile, state_file)
    return (ok and type(result) == "table") and result or nil
end

--- Write a lua_state stub for the given item.
--- .lua items get a dofile() stub so live edits are always picked up;
--- everything else (e.g. static items without a path) gets a static snapshot.
function S.write(state_dir, state_file, item)
    ensure_dir(state_dir)
    local f, err = io.open(state_file, "w")
    if not f then
        error("failed to write state file: " .. tostring(err))
    end
    if item.path and item.path:match("%.lua$") then
        local p = string.format("%q", item.path)
        local dir = string.format("%q", item.path:match("^(.*)/[^/]+$") or ".")
        local key = string.format("%q", item.key or "")
        -- Use require() so Hyprland hot-reload cache invalidation works.
        -- The item's directory is injected into package.path before the call.
        f:write("local _dir = ", dir, "\n")
        f:write("local _p   = ", p, "\n")
        f:write('local _mod = _p:match("^.*/(.-)%.lua$")\n')
        f:write('if not package.path:find(_dir .. "/?.lua", 1, true) then\n')
        f:write('    package.path = _dir .. "/?.lua;" .. package.path\n')
        f:write("end\n")
        f:write("local _ok, _t = pcall(require, _mod)\n")
        f:write("if not (_ok and type(_t) == 'table') then _t = {} end\n")
        f:write("_t.path = _p\n")
        f:write("_t.key  = _t.key or ", key, "\n")
        f:write("return _t\n")
    else
        f:write("return {")
        if item.path then
            f:write("\n  path = ", string.format("%q", item.path), ",")
        end
        if item.key then
            f:write("\n  key = ", string.format("%q", item.key), ",")
        end
        if item.name then
            f:write("\n  name = ", string.format("%q", item.name), ",")
        end
        if item.description then
            f:write("\n  description = ", string.format("%q", item.description), ",")
        end
        if item.icon then
            f:write("\n  icon = ", string.format("%q", item.icon), ",")
        end
        f:write("\n}\n")
    end
    f:close()
end

return S

-- Simulates one or more config loads sharing one process environment -- what
-- `hyprctl reload` actually does, since hl.env("PATH", ...) sets the live
-- compositor's own env var, and the next reload's os.getenv("PATH") sees
-- whatever the previous load left there.
--
-- #1521 reports PATH entries duplicated after a reload; env.lua used to
-- append hyde.path.lib to PATH unconditionally on every load, growing it by
-- one more copy each time.

local repo_root = assert(os.getenv("REPO_ROOT"), "REPO_ROOT is not set")
local hypr_lua = repo_root .. "/Configs/.local/share/hypr/lua"
local lib = "/home/user/.local/lib"

local real_path
local real_getenv = os.getenv
os.getenv = function(name)
    if name == "PATH" then
        return real_path
    end
    return real_getenv(name)
end

_G.hl = {
    env = function(name, value)
        if name == "PATH" then
            real_path = value
        end
    end
}

local function load_once()
    -- A fresh hyde.env module state each time, like a fresh Lua VM per reload.
    _G.hyde = {path = {lib = lib}}
    dofile(hypr_lua .. "/hyde/env.lua")
    dofile(hypr_lua .. "/env.lua")
end

local function count_segment(path, segment)
    local count = 0
    for part in (path .. ":"):gmatch("([^:]*):") do
        if part == segment then
            count = count + 1
        end
    end
    return count
end

local failures = 0
local function check(condition, message)
    if not condition then
        failures = failures + 1
        print("    fail: " .. message)
    end
end

-- Two reloads sharing one environment must not duplicate the lib entry.
real_path = "/usr/bin"
load_once()
load_once()
check(
    count_segment(real_path, lib) == 1,
    string.format("PATH contains %d copies of %s after two reloads, want 1 -- %s", count_segment(real_path, lib), lib, real_path)
)
print("    PATH after two reloads: " .. real_path)

-- A completely empty inherited PATH must not gain a leading empty segment --
-- that puts the current directory first in the search order (CWE-427).
real_path = ""
load_once()
check(real_path:sub(1, 1) ~= ":", string.format("PATH starts with an empty segment on an empty inherited PATH -- %q", real_path))
check(count_segment(real_path, lib) == 1,
    string.format("PATH must contain exactly one copy of %s -- %q", lib, real_path))
print("    PATH from an empty inherited PATH: " .. real_path)

os.exit(failures == 0 and 0 or 1)

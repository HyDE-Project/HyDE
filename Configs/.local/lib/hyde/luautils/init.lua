-- luautils/init.lua
-- Initializes Lua module search paths for HyDE using XDG base directories.
local xdg = require("luautils.xdg")

local XDG_DATA_HOME = xdg.data
local XDG_STATE_HOME = xdg.state
local XDG_CONFIG_HOME = xdg.config

local HYDE_STATE_HOME = os.getenv("HYDE_STATE_HOME") or (XDG_STATE_HOME .. "/hyde")
local HYDE_CONFIG_HOME = os.getenv("HYDE_CONFIG_HOME") or (XDG_CONFIG_HOME .. "/hyde")

local HYDE_SCRIPTS_PATH = os.getenv("HYDE_SCRIPTS_PATH")
if not HYDE_SCRIPTS_PATH then
    local src = debug.getinfo(1, "S").source
    if src and src:sub(1, 1) == "@" then
        local luautils_dir = src:sub(2):match("(.*/luautils)/")
        if luautils_dir then
            HYDE_SCRIPTS_PATH = luautils_dir:gsub("/luautils/$?", "")
        end
    end
end
HYDE_SCRIPTS_PATH = HYDE_SCRIPTS_PATH or (XDG_DATA_HOME .. "/hyde")
local lua_version = _VERSION:match("%d+%.%d+")

local pkg_paths = {
    HYDE_STATE_HOME .. "/?.lua",
    HYDE_SCRIPTS_PATH .. "/?.lua",
    HYDE_SCRIPTS_PATH .. "/luautils/?.lua",
    XDG_DATA_HOME .. "/hypr/lua/?.lua",
    HYDE_CONFIG_HOME .. "/hypr/?.lua",
    HYDE_STATE_HOME .. "/lua_env/share/lua/" .. lua_version .. "/?.lua",
    HYDE_STATE_HOME .. "/lua_env/share/lua/" .. lua_version .. "/?/init.lua"
}
for _, d in ipairs(xdg.dirs.config) do
    if d and d ~= "" then
        table.insert(pkg_paths, d .. "/hyde/?.lua")
        table.insert(pkg_paths, d .. "/hyde/?/init.lua")
    end
end
package.path = package.path .. ";" .. table.concat(pkg_paths, ";") .. ";"
package.cpath =
    package.cpath ..
    ";" ..
        HYDE_STATE_HOME ..
            "/lua_env/lib/lua/" ..
                lua_version .. "/?.so;" .. HYDE_STATE_HOME .. "/lua_env/lib/lua/" .. lua_version .. "/?/init.so;"

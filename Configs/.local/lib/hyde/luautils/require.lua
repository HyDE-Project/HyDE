-- luautils/require.lua
-- v_require: require a module, auto-install with luarocks if missing
-- Usage: local v_require = require("luautils.require")
--        local mod = v_require("modname", "rockname")


local function is_url(str)
    return type(str) == "string" and (str:match("^https?://") or str:match("^file://"))
end

local function v_require(mod, rock)
    local ok, m = pcall(require, mod)
    if ok then return m end
    io.stderr:write("[v_require] Lua module '" .. mod .. "' not found. Attempting to install '" .. (rock or mod) .. "'...\n")
    local luarocks = os.getenv("LUAROCKS") or "luarocks"
    local install_target = rock or mod
    local cmd
    local env_prefix = "LUAROCKS_DOWNLOADER=curl ";
    if is_url(install_target) then
        cmd = string.format(env_prefix .. "%s install '%s'", luarocks, install_target)
    else
        cmd = string.format(env_prefix .. "%s install %s", luarocks, install_target)
    end
    local res = os.execute(cmd)
    if res == 0 then
        local ok2, m2 = pcall(require, mod)
        if ok2 then return m2 end
    end
    io.stderr:write("[v_require] Failed to install '" .. (rock or mod) .. "'. Please install it manually.\n")
    os.exit(1)
end

return v_require

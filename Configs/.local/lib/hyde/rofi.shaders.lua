#!/usr/bin/env lua

local root = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = package.path .. ";" .. root .. "?.lua;" .. root .. "?/init.lua;"
require("luautils.init")
require("luautils.theme.parser")

local sh = require("shaders")

local current = sh.current() or {}
local current_name = current.name or current.key or os.getenv("HYPR_SHADER") or "disable"
local current_icon = current.icon or ""
local current_row
for i, item in ipairs(sh.list) do
    if item.key == current.key or item.name == current_name or item.key == current_name then
        current_row = i - 1
        break
    end
end

local item, err = sh.select({
    env_prefix = "ROFI_SHADER",
    prioritize = {"00-disable", "disable", "Disable Shader"},
    current_name = current_name,
    current_icon = current_icon,
    current_row = current_row,
    prompt = "Select shader",
    placeholder = "Shaders..."
})
if err then
    io.stderr:write("Error: " .. tostring(err) .. "\n")
    os.exit(1)
end

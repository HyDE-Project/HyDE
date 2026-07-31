#!/usr/bin/env lua

local root = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = package.path .. ";" .. root .. "?.lua;" .. root .. "?/init.lua;"
require("luautils.init")
require("luautils.theme.parser")

local rofi = require("luautils.selector.rofi")
local layout = require("layouts")

local current = layout.current() or {}
local current_name = current.name or os.getenv("HYPR_LAYOUT") or "stacking"
local current_icon = current.icon or ""

local selected =
    rofi.select(
    layout.list,
    {
        env_prefix = "ROFI_LAYOUT",
        hoist_default = false,
        current_name = current_name,
        current_icon = current_icon,
        prompt = "Select layout",
        placeholder = "Layouts..."
    }
)

if selected and selected ~= "" then
    layout.set(selected)
end

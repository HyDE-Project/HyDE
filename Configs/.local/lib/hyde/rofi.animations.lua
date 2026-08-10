#!/usr/bin/env lua

local root = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = package.path .. ";" .. root .. "?.lua;" .. root .. "?/init.lua;"
require("luautils.init")
require("luautils.theme.parser")

local rofi = require("luautils.selector.rofi")
local anim = require("animations")

local current = anim.current() or {}
local current_name = current.name or os.getenv("HYPR_ANIMATION") or "theme"
local current_icon = current.icon or ""

local selected =
    rofi.select(
    anim.list,
    {
        env_prefix = "ROFI_ANIMATION",
        hoist_default = false, -- static_items already put Disable/Theme at top
        current_name = current_name,
        current_icon = current_icon,
        prompt = "Select animation",
        placeholder = "Animations..."
    }
)

if selected and selected ~= "" then
    anim.set(selected)
end

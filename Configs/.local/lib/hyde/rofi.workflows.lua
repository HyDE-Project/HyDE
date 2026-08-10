#!/usr/bin/env lua

local root = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = package.path .. ";" .. root .. "?.lua;" .. root .. "?/init.lua;"
require("luautils.init")
require("luautils.theme.parser")

local rofi = require("luautils.selector.rofi")
local wf = require("workflows")

local current = wf.current() or {}
local current_name = current.name or os.getenv("HYPR_WORKFLOW") or "Default"
local current_icon = current.icon or ""

local selected =
    rofi.select(
    wf.list,
    {
        env_prefix = "ROFI_WORKFLOW",
        current_name = current_name,
        current_icon = current_icon,
        prompt = "Select workflow",
        placeholder = "Workflows..."
    }
)

if selected and selected ~= "" then
    wf.set(selected)
end

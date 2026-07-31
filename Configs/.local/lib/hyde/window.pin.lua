#!/usr/bin/env lua

local root = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = package.path .. ";" .. root .. "?.lua;" .. root .. "?/init.lua;"
require("luautils.init")
local hyprctl = require("luautils.hypr.hyprctl")
local client = assert(hyprctl.active_window())

if client.pinned then
    return hyprctl.dispatch('hl.dsp.window.float({action="toggle"})')
end

if not client.floating then
    hyprctl.dispatch('hl.dsp.window.float({action="toggle"})')
end

hyprctl.dispatch("hl.dsp.window.pin()")

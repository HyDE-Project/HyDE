#!/usr/bin/env lua

local root = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = package.path .. ";" .. root .. "?.lua;" .. root .. "?/init.lua;"
require("luautils.init")
require("luautils.theme.parser")

local lfs = require("lfs")
local rofi = require("luautils.selector.rofi")
local wf = require("workflows")
local first_time = not lfs.attributes(wf.state_file)

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
    -- Hyprland's own hot-reload already picks up edits to an already-required
    -- lua_state file; a forced reload is only needed the first time the file
    -- is created, before Hyprland has anything to watch.
    local item, err = wf.set(selected)
    if item then
        if first_time then
            local ok, err_type, err_code = os.execute("hyprctl reload >/dev/null 2>&1")
            if not ok then
                io.stderr:write("Error: hyprctl reload failed: " .. tostring(err_type) .. " " .. tostring(err_code) .. "\n")
            end
        end
    else
        io.stderr:write("Error: " .. tostring(err) .. "\n")
    end
end

#!/usr/bin/env lua

local root = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = package.path .. ";" .. root .. "?.lua;" .. root .. "?/init.lua;"

require("luautils.init")
local xdg = require("luautils.xdg")
local common = require("luautils.selector.common")

local M =
    common.new(
    {
        dirs = {
            xdg.config .. "/hypr/workflows",
            xdg.data .. "/hypr/lua/workflows",
            "/usr/local/share/hypr/lua/workflows",
            "/usr/share/hypr/lua/workflows"
        },
        state_name = "workflows",
        waybar_class = "custom-workflows",
        staterc_key = "HYPR_WORKFLOW"
    }
)

local _src = debug.getinfo(1, "S").source
local _is_main = arg and arg[0] and (_src == "@" .. arg[0] or _src:sub(2):match("[^/]+$") == arg[0]:match("[^/]+$"))
if _is_main then
    common.run(
        M,
        {
            name = "hyde-shell workflows",
            description = "HyDE Workflow Selector"
        }
    )
end

return M

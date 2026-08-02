#!/usr/bin/env lua

local root = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = package.path .. ";" .. root .. "?.lua;" .. root .. "?/init.lua;"

require("luautils.init")
local xdg = require("luautils.xdg")
local lfs = require("lfs")
local common = require("luautils.selector.common")

local function write_layouts_conf(item)
    local conf_dir = xdg.config .. "/hypr"
    local cur = ""
    for part in conf_dir:gmatch("[^/]+") do
        cur = cur .. "/" .. part
        lfs.mkdir(cur)
    end
    local f = assert(io.open(conf_dir .. "/layouts.conf", "w"))
    f:write("source = ./layouts/" .. item.key .. ".conf\n")
    f:close()
end

local M =
    common.new(
    {
        dirs = {
            xdg.config .. "/hypr/lua/layouts",
            xdg.data .. "/hypr/lua/layouts",
            "/usr/local/share/hypr/lua/layouts",
            "/usr/share/hypr/lua/layouts"
        },
        state_name = "layouts",
        waybar_class = "custom-layouts",
        staterc_key = "HYPR_LAYOUT",
        on_set = write_layouts_conf
    }
)

local _base_current = M.current
M.current = function()
    local env = os.getenv("HYPR_LAYOUT")
    if env then
        local item = M.find(env)
        if item then
            return item
        end
    end
    return _base_current()
end

local _src = debug.getinfo(1, "S").source
local _is_main = arg and arg[0] and (_src == "@" .. arg[0] or _src:sub(2):match("[^/]+$") == arg[0]:match("[^/]+$"))
if _is_main then
    common.run(
        M,
        {
            name = "hyde-shell layouts",
            description = "HyDE Layout Selector"
        }
    )
end

return M

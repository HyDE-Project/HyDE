#!/usr/bin/env lua

local root = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = package.path .. ";" .. root .. "?.lua;" .. root .. "?/init.lua;"

require("luautils.init")
local xdg = require("luautils.xdg")
local lfs = require("lfs")
local common = require("luautils.selector.common")

-- Write $XDG_CONFIG_HOME/hypr/animations.conf after selection
local function write_animations_conf(item)
    local conf_dir = xdg.config .. "/hypr"
    local cur = ""
    for part in conf_dir:gmatch("[^/]+") do
        cur = cur .. "/" .. part
        lfs.mkdir(cur)
    end
    local f = assert(io.open(conf_dir .. "/animations.conf", "w"))
    f:write("$ANIMATION=", item.key, "\n")
    f:write("$ANIMATION_PATH=./animations/", item.key, ".conf\n")
    f:write("source = $ANIMATION_PATH\n")
    f:close()
end

local M =
    common.new(
    {
        dirs = {
            xdg.config .. "/hypr/lua/animations",
            xdg.data .. "/hypr/lua/animations",
            "/usr/local/share/hypr/lua/animations",
            "/usr/share/hypr/lua/animations"
        },
        state_name = "animations",
        waybar_class = "custom-animations",
        staterc_key = "HYPR_ANIMATION",
        -- .lua item files, same convention as workflows
        -- static_items = {
        --     {key = "disable", name = "Disable Animation", description = "Turn off all animations", icon = ""},
        --     {key = "theme", name = "Theme Preference", description = "Use the theme's animation setting", icon = ""}
        -- },
        static_items_position = "prepend",
        on_set = write_animations_conf
    }
)

-- current() checks $HYPR_ANIMATION env first (set by hyde globalcontrol)
local _base_current = M.current
M.current = function()
    local env = os.getenv("HYPR_ANIMATION")
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
            name = "hyde-shell animations",
            description = "HyDE Animation Selector"
        }
    )
end

return M

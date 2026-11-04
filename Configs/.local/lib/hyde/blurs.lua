#!/usr/bin/env lua

local root = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = package.path .. ";" .. root .. "?.lua;" .. root .. "?/init.lua;"

require("luautils.init")
local xdg = require("luautils.xdg")
local common = require("luautils.selector.common")
local lfs = require("lfs")
local hyprctl = require("luautils.hypr.hyprctl")

local state_file = xdg.state .. "/hyde/lua_state/blurs.lua"
local first_time = not lfs.attributes(state_file)

local excluded = {
    lib = true,
    wobble = true,
    shadow = true,
    glow = true,
    motion_blur = true,
    window = true
}

local function load_blur_item(path, base)
    if excluded[base] or base:match("^_") then
        return nil
    end

    local ok, item = pcall(dofile, path)
    if not ok or type(item) ~= "table" then
        return nil
    end

    item.path = path
    item.key = item.key or base
    item.name = item.name or base
    item.description = item.description or "No description available"
    item.icon = item.icon or ""
    return item
end

local M =
    common.new(
    {
        dirs = {
            xdg.config .. "/hypr/lua/blurs",
            xdg.data .. "/hypr/lua/blurs",
            "/usr/local/share/hypr/lua/blurs",
            "/usr/share/hypr/lua/blurs"
        },
        state_name = "blurs",
        waybar_class = "custom-blurs",
        staterc_key = "HYPR_BLUR",
        load_item = load_blur_item,
        rofi_opts = {
            env_prefix = "ROFI_BLUR",
            prompt = "Select blur",
            placeholder = "Blurs...",
            hoist_default = true
        },
        on_set = function()
            if first_time then
                local ok = hyprctl.reload()
                if ok then
                    first_time = false
                end
            end
        end
    }
)

local _base_current = M.current
M.current = function()
    local env = os.getenv("HYPR_BLUR")
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
            name = "hyde-shell blurs",
            description = "HyDE Blurs Selector"
        }
    )
end

return M

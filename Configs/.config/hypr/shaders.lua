--[[
    █▀ █░█ ▄▀█ █▀▄ █▀▀ █▀█ █▀
    ▄█ █▀█ █▀█ █▄▀ ██▄ █▀▄ ▄█

    Shader Configuration
    https://wiki.hypr.land/Configuring/Variables/#decoration

    DOORwayDE managed — do not edit directly.
    Use 'doorwayde-shell shaders --select' to change the active shader.
--]]

local xdg_config = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")

local screen_shader          = "disable"
local screen_shader_path     = xdg_config .. "/hypr/shaders/disable.frag"
local screen_shader_compiled = xdg_config .. "/hypr/shaders/.compiled.cache.glsl"

if screen_shader ~= "disable" then
    hl.config({
        decoration = {
            screen_shader = screen_shader_compiled,
        },
    })
end

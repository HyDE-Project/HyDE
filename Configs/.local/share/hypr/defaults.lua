--[[
    DOORwayDE default Hyprland settings.

    Originally `defaults.conf` (hyprlang). Hyprland 0.55+ lua migration.

    Covers monitor fallback, decoration, animations, input, layouts, misc,
    xwayland, and floating-window snap. Theme-driven values live in
    dynamic.lua; this file is intentionally static.
--]]

-- // █▀▄▀█ █▀█ █▄░█ █ ▀█▀ █▀█ █▀█
-- // █░▀░█ █▄█ █░▀█ █ ░█░ █▄█ █▀▄

-- Fallback monitor: any output, preferred mode, auto-positioned.
-- See https://wiki.hypr.land/Configuring/Monitors/
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- // █▀ █▀█ █▀▀ █▀▀ █ ▄▀█ █░░
-- // ▄█ █▀▀ ██▄ █▄▄ █ █▀█ █▄▄

hl.config({
    decoration = {
        dim_special      = 0.3,
        active_opacity   = 0.90,
        inactive_opacity = 0.75,
        fullscreen_opacity = 1,
        blur = {
            special = true,
        },
    },

    -- // ▄▀█ █▄░█ █ █▀▄▀█ ▄▀█ ▀█▀ █ █▀█ █▄░█
    -- // █▀█ █░▀█ █ █░▀░█ █▀█ ░█░ █ █▄█ █░▀█
    animations = {
        enabled = true,
        bezier = {
            { "wind",   0.05, 0.9,  0.1, 1.05 },
            { "winIn",  0.1,  1.1,  0.1, 1.1  },
            { "winOut", 0.3, -0.3,  0,   1    },
            { "liner",  1,    1,    1,   1    },
        },
        animation = {
            { "windows",     1, 6,  "wind",    "slide" },
            { "windowsIn",   1, 6,  "winIn",   "slide" },
            { "windowsOut",  1, 5,  "winOut",  "slide" },
            { "windowsMove", 1, 5,  "wind",    "slide" },
            { "border",      1, 1,  "liner"            },
            { "borderangle", 1, 30, "liner",   "once"  },
            { "fade",        1, 10, "default"          },
            { "workspaces",  1, 5,  "wind"             },
        },
    },

    -- // █ █▄░█ █▀█ █░█ ▀█▀
    -- // █ █░▀█ █▀▀ █▄█ ░█░
    input = {
        accel_profile      = "flat",
        numlock_by_default = true,
    },

    -- // █░░ ▄▀█ █▄█ █▀█ █░█ ▀█▀ █▀
    -- // █▄▄ █▀█ ░█░ █▄█ █▄█ ░█░ ▄█
    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    -- // █▀▄▀█ █ █▀ █▀▀
    -- // █░▀░█ █ ▄█ █▄▄
    misc = {
        vrr                       = 0,
        disable_hyprland_logo     = true,
        disable_splash_rendering  = true,
        force_default_wallpaper   = 0,
        anr_missed_pings          = 5,
        allow_session_lock_restore = true,
    },

    xwayland = {
        force_zero_scaling = true,
    },

    general = {
        snap = {
            enabled = true,
        },
    },
})

-- Touchpad gestures. See https://wiki.hypr.land/Configuring/Gestures/
-- Guard: hl.gesture is a Lua-specific binding function; existence check follows the
-- same pattern as hl.source in dynamic.lua — avoids a crash if not yet implemented.
if hl.gesture then
    hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
    hl.gesture({ fingers = 3, direction = "pinchin",    action = "float", action_modifier = "tile" })
    hl.gesture({ fingers = 3, direction = "pinchout",   action = "float", action_modifier = "float" })
end

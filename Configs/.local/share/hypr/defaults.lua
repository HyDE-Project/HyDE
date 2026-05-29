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
    -- Only `animations.enabled` is a valid HL.ConfigKey; bezier curves and
    -- per-leaf animation specs use hl.curve / hl.animation below.
    animations = {
        enabled = true,
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

-- // █▀▀ █░█ █▀█ █░█ █▀▀ █▀
-- // █▄▄ █▄█ █▀▄ ▀▄▀ ██▄ ▄█
-- Bezier curves: hyprlang `bezier = name, x0, y0, x1, y1` becomes
-- hl.curve(name, {type="bezier", points={{x0,y0},{x1,y1}}}). See the
-- vendored example at /nix/store/.../hyprland-0.55.2/share/hypr/hyprland.lua.
hl.curve("wind",   { type = "bezier", points = { {0.05, 0.9 }, {0.1, 1.05} } })
hl.curve("winIn",  { type = "bezier", points = { {0.1,  1.1 }, {0.1, 1.1 } } })
hl.curve("winOut", { type = "bezier", points = { {0.3, -0.3 }, {0,   1   } } })
hl.curve("liner",  { type = "bezier", points = { {1,    1   }, {1,   1   } } })

-- Animations: hyprlang `animation = leaf, on, speed, curve, [style]` becomes
-- hl.animation({leaf=..., enabled=..., speed=..., bezier=..., style=...}).
hl.animation({ leaf = "windows",     enabled = true, speed = 6,  bezier = "wind",    style = "slide" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 6,  bezier = "winIn",   style = "slide" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 5,  bezier = "winOut",  style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5,  bezier = "wind",    style = "slide" })
hl.animation({ leaf = "border",      enabled = true, speed = 1,  bezier = "liner"                    })
hl.animation({ leaf = "borderangle", enabled = true, speed = 30, bezier = "liner",   style = "once"  })
hl.animation({ leaf = "fade",        enabled = true, speed = 10, bezier = "default"                  })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 5,  bezier = "wind"                     })

-- Touchpad gestures. See https://wiki.hypr.land/Configuring/Gestures/
-- Guard: hl.gesture is a Lua-specific binding function; existence check follows the
-- same pattern as hl.source in dynamic.lua — avoids a crash if not yet implemented.
if hl.gesture then
    hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
    hl.gesture({ fingers = 3, direction = "pinchin",    action = "float", action_modifier = "tile" })
    hl.gesture({ fingers = 3, direction = "pinchout",   action = "float", action_modifier = "float" })
end

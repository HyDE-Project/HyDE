--[[
    █▀█ █▀█ █░█░█ █▀▀ █▀█ █▀ ▄▀█ █░█ █▀▀ █▀█
    █▀▀ █▄█ ▀▄▀▄▀ ██▄ █▀▄ ▄█ █▀█ ▀▄▀ ██▄ █▀▄

    Workflow: Power Saver
    Saves as much power as possible.
    Disables all animations and effects while preserving readability.

    Select with: doorwayde-shell workflows --select
--]]

hl.config({
    general = {
        gaps_in = 0,
        gaps_out = 0,
        border_size = 1,
    },
    decoration = {
        rounding = 0,
        active_opacity = 1,
        inactive_opacity = 1,
        fullscreen_opacity = 1,
        shadow = { enabled = false },
        blur = { enabled = false, xray = true },
    },
    animations = { enabled = false },
})

hl.window_rule({
    match = { class = "(.*)" },
    opaque = true,
})

hl.layer_rule({
    name = "workflows_powersaver",
    match = { namespace = "^(rofi|quickshell:notificationPopups|swaync-(notification-window|control-center)|quickshell:session|quickshell:bar)$" },
    blur = false,
    no_anim = true,
})

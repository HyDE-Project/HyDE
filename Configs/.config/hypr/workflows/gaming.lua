--[[
    █▀▀ ▄▀█ █▀▄▀█ █▀▀ █▀▄▀█ █▀█ █▀▄ █▀▀
    █▄█ █▀█ █░▀░█ ██▄ █░▀░█ █▄█ █▄▀ ██▄

    Workflow: Gaming
    Emphasis on performance — disables compositor expensive features.
    Removes shadows, blur, rounding, gaps, and animations.

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
    name = "workflows_gaming",
    match = { namespace = "^(rofi|notifications|swaync-(notification-window|control-center)|logout_dialog|waybar|.*www-daemon)$" },
    blur = false,
    no_anim = true,
})

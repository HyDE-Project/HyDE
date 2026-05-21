--[[
     █▀▀ █▀▄ █ ▀█▀ █▀█ █▀█
    ██▄ █▄▀ █ ░█░ █▄█ █▀▄

    Workflow: Editing
    Best for writing and editing.
    Disables xray and makes all windows opaque for accurate color rendering.

    Select with: doorwayde-shell workflows --select
--]]

hl.config({
    decoration = {
        active_opacity = 1,
        inactive_opacity = 1,
        fullscreen_opacity = 1,
        blur = { enabled = true },
    },
})

hl.window_rule({
    match = { class = "(.*)" },
    opaque = true,
})

hl.layer_rule({
    name = "workflows_editing",
    match = { namespace = "^(rofi|notifications|swaync-(notification-window|control-center)|logout_dialog|waybar)$" },
    blur = true,
})

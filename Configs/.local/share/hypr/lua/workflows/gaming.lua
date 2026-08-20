local workflow = {
    name = "Gaming",
    icon = "",
    description = "Emphasis on performance and disabling compositors expensive features"
}

if not hl then
    return workflow
end

hl.config(
    {
        decoration = {
            shadow = {
                enabled = false
            },
            blur = {
                enabled = false,
                xray = true
            },
            rounding = 0,
            active_opacity = 1,
            inactive_opacity = 1,
            fullscreen_opacity = 1
        },
        general = {
            gaps_in = 0,
            gaps_out = 0,
            border_size = 1
        }
    }
)
hl.window_rule(
    {
        opaque = true,
        match = {
            class = ".*"
        }
    }
)
hl.layer_rule(
    {
        name = "hyde_workflow_gaming",
        blur = false,
        no_anim = true,
        match = {
            namespace = "^(rofi|notifications|swaync-(notification-window|control-center)|logout_dialog|waybar|.*www-daemon)$"
        }
    }
)

require("animations.00-disable")

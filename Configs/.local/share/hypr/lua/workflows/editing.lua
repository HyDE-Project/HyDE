local workflow = {
    name = "Editing",
    icon = "",
    description = "Best for writing and editing // Disables xray and blur that might affect color picking/contrast"
}

if not hl then
    return workflow
end

hl.config(
    {
        decoration = {
            blur = {
                enabled = true
            },
            active_opacity = 1,
            inactive_opacity = 1,
            fullscreen_opacity = 1
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
        name = "hyde_workflow_editing",
        blur = true,
        match = {
            namespace = "^(rofi|notifications|swaync-(notification-window|control-center)|logout_dialog|waybar)$"
        }
    }
)

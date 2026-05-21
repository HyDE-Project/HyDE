--[[
    Animation preset: Vertical
    Select with: doorwayde-shell animations --select

    Note: the original .conf also defined gestures (gesture = 3, vertical,
    workspace) due to https://github.com/hyprwm/Hyprland/pull/11490.
    Configure those in your workflow/keybindings .lua if you want the same
    behavior — this preset only sets animations.
--]]

hl.config({
    animations = {
        enabled = true,
        bezier = {
            { "fluent_decel",  0,    0.2,  0.4,  1 },
            { "easeOutCirc",   0,    0.55, 0.45, 1 },
            { "easeOutCubic",  0.33, 1,    0.68, 1 },
            { "easeinoutsine", 0.37, 0,    0.63, 1 },
        },
        animation = {
            { "windowsIn",        1, 1.5, "easeinoutsine", "popin 60%" },
            { "windowsOut",       1, 1.5, "easeOutCubic",  "popin 60%" },
            { "windowsMove",      1, 1.5, "easeinoutsine", "slide" },
            { "fade",             1, 2.5, "fluent_decel" },
            { "fadeLayersIn",     0 },
            { "border",           0 },
            { "layers",           1, 1.5, "easeinoutsine", "popin" },
            { "workspaces",       1, 3,   "fluent_decel",  "slidefadevert 30%" },
            { "specialWorkspace", 1, 2,   "fluent_decel",  "slidefade 10%" },
        },
    },
})

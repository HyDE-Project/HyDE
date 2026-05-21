--[[
    Animation preset: LimeFrenzy
    Source: https://github.com/xaicat/LimeFrenzy/
    Select with: doorwayde-shell animations --select
--]]

hl.config({
    animations = {
        enabled = true,
        bezier = {
            { "default",  0.12, 0.92, 0.08, 1.0  },
            { "wind",     0.12, 0.92, 0.08, 1.0  },
            { "overshot", 0.18, 0.95, 0.22, 1.03 },
            { "liner",    1,    1,    1,    1    },
        },
        animation = {
            { "windows",     1, 5,  "wind",     "popin 60%" },
            { "windowsIn",   1, 6,  "overshot", "popin 60%" },
            { "windowsOut",  1, 4,  "overshot", "popin 60%" },
            { "windowsMove", 1, 4,  "overshot", "slide" },
            { "layers",      1, 4,  "default",  "popin" },
            { "fadeIn",      1, 7,  "default" },
            { "fadeOut",     1, 7,  "default" },
            { "fadeSwitch",  1, 7,  "default" },
            { "fadeShadow",  1, 7,  "default" },
            { "fadeDim",     1, 7,  "default" },
            { "fadeLayers",  1, 7,  "default" },
            { "workspaces",  1, 5,  "overshot", "slidevert" },
            { "border",      1, 1,  "liner" },
            { "borderangle", 1, 24, "liner",    "loop" },
        },
    },
})

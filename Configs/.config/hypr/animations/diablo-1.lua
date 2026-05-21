--[[
    Animation preset: Diablo-1
    Credit: https://github.com/Itz-Abhishek-Tiwari
    Select with: doorwayde-shell animations --select
--]]

hl.config({
    animations = {
        enabled = true,
        bezier = {
            { "default",          0.05, 0.9,  0.1,  1.05 },
            { "wind",             0.05, 0.9,  0.1,  1.05 },
            { "overshot",         0.13, 0.99, 0.29, 1.08 },
            { "liner",            1,    1,    1,    1    },
            { "bounce",           0.4,  0.9,  0.6,  1.0  },
            { "snappyReturn",     0.4,  0.9,  0.6,  1.0  },
            { "slideInFromRight", 0.5,  0.0,  0.5,  1.0  },
        },
        animation = {
            { "windows",     1, 5,  "snappyReturn", "slidevert" },
            { "windowsIn",   1, 5,  "snappyReturn", "slidevert right" },
            { "windowsOut",  1, 5,  "snappyReturn", "slide" },
            { "windowsMove", 1, 6,  "bounce",       "slide" },
            { "layersOut",   1, 5,  "bounce",       "slidevert right" },
            { "fadeIn",      1, 10, "default" },
            { "fadeOut",     1, 10, "default" },
            { "fadeSwitch",  1, 10, "default" },
            { "fadeShadow",  1, 10, "default" },
            { "fadeDim",     1, 10, "default" },
            { "fadeLayers",  1, 10, "default" },
            { "workspaces",  1, 7,  "overshot",     "slidevert" },
            { "border",      1, 1,  "liner" },
            { "layers",      1, 4,  "bounce",       "slidevert right" },
            { "borderangle", 1, 30, "liner",        "loop" },
        },
    },
})

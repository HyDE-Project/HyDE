--[[
    Animation preset: Diablo-2
    Credit: https://github.com/Itz-Abhishek-Tiwari
    Select with: doorwayde-shell animations --select
--]]

hl.config({
    animations = {
        enabled = true,
        bezier = {
            { "default", 0.05, 0.9,  0.1,  1.05 },
            { "wind",    0.05, 0.9,  0.1,  1.05 },
            { "overshot", 0.13, 0.99, 0.29, 1.08 },
            { "liner",   1,    1,    1,    1    },
        },
        animation = {
            { "windows",      1, 7,  "wind",    "popin" },
            { "windowsIn",    1, 7,  "overshot", "popin" },
            { "windowsOut",   1, 5,  "overshot", "popin" },
            { "windowsMove",  1, 6,  "overshot", "slide" },
            { "layers",       1, 5,  "default",  "popin" },
            { "fadeIn",       1, 10, "default" },
            { "fadeOut",      1, 10, "default" },
            { "fadeSwitch",   1, 10, "default" },
            { "fadeShadow",   1, 10, "default" },
            { "fadeDim",      1, 10, "default" },
            { "fadeLayers",   1, 10, "default" },
            { "workspaces",   1, 7,  "overshot", "slidevert" },
            { "border",       1, 1,  "liner" },
            { "borderangle",  1, 30, "liner",    "loop" },
        },
    },
})

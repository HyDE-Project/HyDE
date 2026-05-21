--[[
    Animation preset: Moving
    Credit: https://github.com/mylinuxforwork/dotfiles
    Select with: doorwayde-shell animations --select
--]]

hl.config({
    animations = {
        enabled = true,
        bezier = {
            { "overshot",  0.05, 0.9,  0.1,  1.05 },
            { "smoothOut", 0.5,  0,    0.99, 0.99 },
            { "smoothIn",  0.5,  -0.5, 0.68, 1.5  },
        },
        animation = {
            { "windows",     1, 5, "overshot",  "slide" },
            { "windowsOut",  1, 3, "smoothOut" },
            { "windowsIn",   1, 3, "smoothOut" },
            { "windowsMove", 1, 4, "smoothIn",  "slide" },
            { "border",      1, 5, "default" },
            { "fade",        1, 5, "smoothIn" },
            { "fadeDim",     1, 5, "smoothIn" },
            { "workspaces",  1, 6, "default" },
        },
    },
})

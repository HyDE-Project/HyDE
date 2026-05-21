--[[
    Animation preset: Ja
    Credit: https://github.com/JaKooLit/Hyprland-Dots
    Select with: doorwayde-shell animations --select
--]]

hl.config({
    animations = {
        enabled = true,
        bezier = {
            { "wind",      0.05, 0.9,  0.1,  1.05 },
            { "winIn",     0.1,  1.1,  0.1,  1.1  },
            { "winOut",    0.3,  -0.3, 0,    1    },
            { "liner",     1,    1,    1,    1    },
            { "overshot",  0.05, 0.9,  0.1,  1.05 },
            { "smoothOut", 0.5,  0,    0.99, 0.99 },
            { "smoothIn",  0.5,  -0.5, 0.68, 1.5  },
        },
        animation = {
            { "windows",       1, 6, "wind",      "slide" },
            { "windowsIn",     1, 5, "winIn",     "slide" },
            { "windowsOut",    1, 3, "smoothOut", "slide" },
            { "windowsMove",   1, 5, "wind",      "slide" },
            { "border",        1, 1, "liner" },
            { "fade",          1, 3, "smoothOut" },
            { "workspaces",    1, 5, "overshot" },
            { "workspacesIn",  1, 5, "winIn",     "slide" },
            { "workspacesOut", 1, 5, "winOut",    "slide" },
        },
    },
})

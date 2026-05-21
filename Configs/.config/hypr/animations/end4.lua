--[[
    Animation preset: End4
    Credit: https://github.com/end-4/dots-hyprland
    Select with: doorwayde-shell animations --select
--]]

hl.config({
    animations = {
        enabled = true,
        bezier = {
            { "linear",        0,    0,    1,    1    },
            { "md3_standard",  0.2,  0,    0,    1    },
            { "md3_decel",     0.05, 0.7,  0.1,  1    },
            { "md3_accel",     0.3,  0,    0.8,  0.15 },
            { "overshot",      0.05, 0.9,  0.1,  1.1  },
            { "crazyshot",     0.1,  1.5,  0.76, 0.92 },
            { "hyprnostretch", 0.05, 0.9,  0.1,  1.0  },
            { "menu_decel",    0.1,  1,    0,    1    },
            { "menu_accel",    0.38, 0.04, 1,    0.07 },
            { "easeInOutCirc", 0.85, 0,    0.15, 1    },
            { "easeOutCirc",   0,    0.55, 0.45, 1    },
            { "easeOutExpo",   0.16, 1,    0.3,  1    },
            { "softAcDecel",   0.26, 0.26, 0.15, 1    },
            { "md2",           0.4,  0,    0.2,  1    },
        },
        animation = {
            { "windows",          1, 3,   "md3_decel",  "popin 60%" },
            { "windowsIn",        1, 3,   "md3_decel",  "popin 60%" },
            { "windowsOut",       1, 3,   "md3_accel",  "popin 60%" },
            { "border",           1, 10,  "default" },
            { "fade",             1, 3,   "md3_decel" },
            { "layersIn",         1, 3,   "menu_decel", "slide" },
            { "layersOut",        1, 1.6, "menu_accel" },
            { "fadeLayersIn",     1, 2,   "menu_decel" },
            { "fadeLayersOut",    1, 4.5, "menu_accel" },
            { "workspaces",       1, 7,   "menu_decel", "slide" },
            { "specialWorkspace", 1, 3,   "md3_decel",  "slidevert" },
        },
    },
})

--[[
    ▀█▀ █░█ █▀▀ █▀▄▀█ █▀▀
    ░█░ █▀█ ██▄ █░▀░█ ██▄

    Theme Settings
    https://wiki.hypr.land/Configuring/Variables/

    DOORwayDE Controlled content — DO NOT EDIT.
    Edit themes in the DOORwayDE theme directory.
    Run 'doorwayde-shell themeselect' to switch themes.
--]]

-- Theme metadata (read by DOORwayDE wallbash scripts)
local GTK_THEME      = "Catppuccin-Mocha"
local ICON_THEME     = "Tela-circle-dracula"
local COLOR_SCHEME   = "prefer-dark"

--------------------------------------------------------------------------------
-- Layout and Borders
--------------------------------------------------------------------------------

hl.config({
    general = {
        gaps_in        = 3,
        gaps_out       = 8,
        border_size    = 2,
        col = {
            active_border   = "rgba(ca9ee6ff) rgba(f2d5cfff) 45deg",
            inactive_border = "rgba(b4befecc) rgba(6c7086cc) 45deg",
        },
        layout          = "dwindle",
        resize_on_border = true,
    },
})

--------------------------------------------------------------------------------
-- Group Borders
--------------------------------------------------------------------------------

hl.config({
    group = {
        col = {
            border_active          = "rgba(ca9ee6ff) rgba(f2d5cfff) 45deg",
            border_inactive        = "rgba(b4befecc) rgba(6c7086cc) 45deg",
            border_locked_active   = "rgba(ca9ee6ff) rgba(f2d5cfff) 45deg",
            border_locked_inactive = "rgba(b4befecc) rgba(6c7086cc) 45deg",
        },
    },
})

--------------------------------------------------------------------------------
-- Decoration and Blur
--------------------------------------------------------------------------------

hl.config({
    decoration = {
        rounding = 10,
        shadow   = { enabled = false },
        blur     = {
            enabled           = true,
            size              = 6,
            passes            = 3,
            new_optimizations = true,
            ignore_opacity    = true,
            xray              = false,
        },
    },
})

--------------------------------------------------------------------------------
-- Layer Rules
--------------------------------------------------------------------------------

hl.layer_rule({
    match = { namespace = "waybar" },
    blur  = true,
})

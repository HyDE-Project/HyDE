--!          ░▒▓
--!        ░▒▒░▓▓
--!      ░▒▒▒░░░▓▓           ___________
--!    ░░▒▒▒░░░░░▓▓        //___________/
--!   ░░▒▒▒░░░░░▓▓     _   _ _    _ _____
--!   ░░▒▒░░░░░▓▓▓▓▓▓ | | | | |  | |  __/
--!    ░▒▒░░░░▓▓   ▓▓ | |_| | |_/ /| |___
--!     ░▒▒░░▓▓   ▓▓   \__  |____/ |____/  █░█░█ █▀▀ ▀█ ▀█▀ █▀▀ █▀█ █▀▄▀█
--!       ░▒▓▓   ▓▓  //____/               ▀▄▀▄▀ ██▄ █▄  ░█░ ██▄ █▀▄ █░▀░█

-- HyDE's WezTerm defaults.
--
-- This file is replaced on update. Put your own settings in wezterm.lua,
-- which HyDE never overwrites.

local wezterm = require("wezterm")

local M = {}

-- Written by wallbash on every theme change. Absent until the first one runs,
-- so a missing file is not an error.
local function wallbash_colors()
    local ok, colors = pcall(require, "colors")
    if ok and type(colors) == "table" then
        return colors
    end
    return nil
end

--- Returns HyDE's defaults as a config table.
---
--- Merge your own settings on top of it:
---
---     local config = require("hyde").config()
---     config.font_size = 12
---     return config
function M.config()
    local config = wezterm.config_builder()

    config.colors = wallbash_colors()

    config.font = wezterm.font_with_fallback({
        "JetBrainsMono Nerd Font",
        "mononoki Nerd Font",
        "monospace",
    })
    config.font_size = 11

    config.window_background_opacity = 0.8
    config.window_decorations = "NONE"
    config.window_padding = {left = 8, right = 8, top = 8, bottom = 8}

    config.use_fancy_tab_bar = false
    config.hide_tab_bar_if_only_one_tab = true
    config.tab_bar_at_bottom = false

    config.scrollback_lines = 10000
    config.enable_scroll_bar = false

    config.audible_bell = "Disabled"
    config.check_for_updates = false

    -- The session already runs under Wayland, and letting WezTerm pick keeps
    -- it working when it is started from an X11 session instead.
    config.enable_wayland = true

    return config
end

return M

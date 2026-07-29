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

local config_dir = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/wezterm"

--- Returns HyDE's defaults as a config table.
---
--- Merge your own settings on top of it:
---
---     local config = require("hyde").config()
---     config.font_size = 12
---     return config
function M.config()
    local config = wezterm.config_builder()

    -- wallbash writes hyde.toml here as a native colour scheme named
    -- "wallbash". Watching that file means a theme switch reloads WezTerm on
    -- its own, with nothing to signal and no need to touch the entry point.
    --
    -- The scheme is only selected once the file exists: naming a scheme that is
    -- not there makes WezTerm log an error on every start, which is what a
    -- fresh install looks like before the first theme switch runs.
    local palette = config_dir .. "/hyde.toml"
    wezterm.add_to_config_reload_watch_list(palette)

    local handle = io.open(palette, "r")
    if handle then
        handle:close()
        config.color_scheme_dirs = {config_dir}
        config.color_scheme = "wallbash"
    end

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

    return config
end

return M

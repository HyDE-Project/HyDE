--[[
    DOORwayDE dynamic.lua — runtime theme settings, groupbar config,
    post-load exec. Originally dynamic.conf (hyprlang).

    KNOWN GAP — wallbash integration: Hyprland 0.55.1's lua API has no
    equivalent of hl.source(). Confirmed via `Hyprland --verify-config`:
    none of hl.source / hl.include / hl.load / hl.parse exist. The
    wallbash pipeline writes hyprlang colors.conf files, which means
    the wallbash-driven theming cannot be re-applied from lua at this
    time. The pcall-wrapped try_source(...) calls below are no-ops
    that exist as placeholders until wallbash is refactored to emit a
    colors.lua module (see TODO.md).

    Groupbar therefore uses the Hyprland default color palette; visual
    parity with the wallbash theme will return once wallbash-lua lands.
--]]

local vars = require("variables")

-- // █▀ █▀█ █░█ █▀█ █▀▀ █▀▀
-- // ▄█ █▄█ █▄█ █▀▄ █▄▄ ██▄

local home        = os.getenv("HOME")
local xdg_config  = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
local xdg_state   = os.getenv("XDG_STATE_HOME")  or (home .. "/.local/state")
local hypr_config = xdg_config .. "/hypr"

-- Screen shader compiled cache is handled by ~/.config/hypr/shaders.lua;
-- the conditional `decoration:screen_shader` lives there now.

-- Placeholder for the future wallbash-lua sourcing call. Currently a no-op
-- because hl.source is nil; the pcall keeps the line non-fatal so that
-- a future drop-in replacement can re-enable theming without code changes.
local function try_source(path)
    if hl.source then pcall(function() hl.source(path) end) end
end

try_source(hypr_config .. "/themes/colors.conf")    -- wallbash colors (no-op)

-- // █▀▀ █▀█ █▀█ █░█ █▀█ █▄▄ ▄▀█ █▀█
-- // █▄█ █▀▄ █▄█ █▄█ █▀▀ █▄█ █▀█ █▀▄

try_source(hypr_config .. "/themes/theme.conf")     -- theme-specific (no-op)
try_source(hypr_config .. "/themes/wallbash.conf")  -- post-sanitize (no-op)

-- Remaining legacy sources from dynamic.conf. Same no-op story until lua
-- ports exist.
try_source(hypr_config .. "/nvidia.conf")
try_source(hypr_config .. "/doorwayde.conf")
try_source(xdg_state    .. "/doorwayde/hyprland.conf")  -- from config.toml

-- // █▀▀ █▀█ █▄░█ ▀█▀
-- // █▀░ █▄█ █░▀█ ░█░

-- Groupbar — structural config only; colors rely on Hyprland defaults
-- until wallbash → lua port (see header comment + TODO.md).
hl.config({
    group = {
        groupbar = {
            enabled              = true,
            gradients            = 1,
            render_titles        = 1,
            font_weight_inactive = "normal",
            font_weight_active   = "semibold",
            blur                 = true,
            font_size            = vars.FONT_SIZE,
            font_family          = vars.GROUPBAR_FONT,
        },
    },
    misc = {
        font_family = vars.FONT,
    },
})

-- // █▀█ █▀█ █▀▀ █▀█
-- // █▀▀ █▀▄ ██▄ █▀▀

-- $XDG_* references stay literal so hyprland resolves them at exec time.
local mkdir_cmd = "mkdir -p $XDG_RUNTIME_DIR/doorwayde "
               .. "$XDG_CACHE_HOME/doorwayde/wallbash "
               .. "$XDG_CONFIG_HOME/doorwayde "
               .. "$XDG_DATA_HOME/doorwayde "
               .. "$(dirname $XDG_DATA_HOME)/state/doorwayde"

local keybinds_hint_cmd = 'bash -c \'eval "$(doorwayde-shell init)" && '
                       .. '$LIB_DIR/doorwayde/keybinds/hint-hyprland.py '
                       .. '--format rofi > $XDG_RUNTIME_DIR/doorwayde/keybinds_hint.rofi\''

hl.config({
    exec = {
        mkdir_cmd .. " & " .. keybinds_hint_cmd,
    },
})

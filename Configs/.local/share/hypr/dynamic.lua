--[[
    DOORwayDE dynamic.lua — runtime theme/colour sourcing, groupbar config,
    post-load exec. Originally dynamic.conf (hyprlang).

    Theme .conf files are still sourced as hyprlang because they're emitted
    by the wallbash script and depend on hyprlang variable substitution
    ($wallbash_*). The user's lua chain may not cover them in this load
    order, so we re-source defensively. Missing files are tolerated via
    pcall — equivalent to the original `# hyprlang noerror true` guards.
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

-- noerror equivalent: silently skip files that haven't been generated yet
local function try_source(path)
    pcall(function() hl.source(path) end)
end

try_source(hypr_config .. "/themes/colors.conf")    -- wallbash colors

-- // █▀▀ █▀█ █▀█ █░█ █▀█ █▄▄ ▄▀█ █▀█
-- // █▄█ █▀▄ █▄█ █▄█ █▀▀ █▄█ █▀█ █▀▄

-- col.active values reference $wallbash_* vars defined in colors.conf above.
-- hl.keyword preserves the literal string so hyprlang resolves it at runtime.
hl.keyword("group:groupbar:enabled", true)
hl.keyword("group:groupbar:gradients", 1)
hl.keyword("group:groupbar:render_titles", 1)
hl.keyword("group:groupbar:font_weight_inactive", "normal")
hl.keyword("group:groupbar:font_weight_active", "semibold")
hl.keyword("group:groupbar:col.active",          "rgba($wallbash_pry3ee)")
hl.keyword("group:groupbar:col.inactive",        "rgba($wallbash_pry1ee)")
hl.keyword("group:groupbar:col.locked_active",   "rgba($wallbash_pry2ee)")
hl.keyword("group:groupbar:col.locked_inactive", "rgba($wallbash_pry4ee)")
hl.keyword("group:groupbar:text_color",          "rgba($wallbash_txt3ee)")
hl.keyword("group:groupbar:text_color_inactive", "rgba($wallbash_txt1ee)")
hl.keyword("group:groupbar:blur", true)

try_source(hypr_config .. "/themes/theme.conf")     -- theme-specific settings
try_source(hypr_config .. "/themes/wallbash.conf")  -- post-sanitize fallbacks

-- Remaining legacy sources from dynamic.conf. nvidia/doorwayde-fallback and
-- the toml-parser state file have no lua equivalents yet, so source them.
-- animations.conf and shaders.conf are already covered by the user's
-- ~/.config/hypr/*.lua chain — sourcing them again is harmless (last write wins).
try_source(hypr_config .. "/nvidia.conf")
try_source(hypr_config .. "/doorwayde.conf")
try_source(xdg_state    .. "/doorwayde/hyprland.conf")  -- from config.toml

-- // █▀▀ █▀█ █▄░█ ▀█▀
-- // █▀░ █▄█ █░▀█ ░█░

-- Groupbar font is theme-driven (lives in variables.lua, not in colors.conf).
hl.keyword("group:groupbar:font_size",   vars.FONT_SIZE)
hl.keyword("group:groupbar:font_family", vars.GROUPBAR_FONT)

hl.config({
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

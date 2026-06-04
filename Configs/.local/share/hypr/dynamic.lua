--[[
    DOORwayDE dynamic.lua — runtime theme settings, groupbar config,
    post-load exec. Originally dynamic.conf (hyprlang).

    Colors: matugen writes ~/.local/share/matugen/hyprland-colors.lua
    on every wallpaper change (doorwayde-matugen-watcher.service).
    dynamic.lua dofiles it if present; hyprctl reload propagates the change.
    Groupbar colors follow suit once the file exists.
--]]

local vars = require("variables")

-- // █▀ █▀█ █░█ █▀█ █▀▀ █▀▀
-- // ▄█ █▄█ █▄█ █▀▄ █▄▄ ██▄

local home = os.getenv("HOME")

-- Screen shader compiled cache is handled by ~/.config/hypr/shaders.lua;
-- the conditional `decoration:screen_shader` lives there now.

-- Matugen-generated colors (Material You palette from current wallpaper).
-- Written to XDG_DATA_HOME/matugen/ by doorwayde-matugen-watcher.service
-- on every wallpaper change; hyprctl reload picks them up from here.
-- pcall swallows both "file missing" (first boot before matugen ran) and
-- any future hl.config() key changes in the generated output.
do
    local xdg_data = os.getenv("XDG_DATA_HOME") or (home .. "/.local/share")
    local colors_file = xdg_data .. "/matugen/hyprland-colors.lua"
    local f = io.open(colors_file, "r")
    if f then
        f:close()
        pcall(dofile, colors_file)
    end
end

-- // █▀▀ █▀█ █▀█ █░█ █▀█ █▄▄ ▄▀█ █▀█
-- // █▄█ █▀▄ █▄█ █▄█ █▀▀ █▄█ █▀█ █▀▄

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

-- Runtime side-effects: `exec` is not an HL.ConfigKey, so call hl.exec_cmd
-- directly. Re-fires on every config (re)load — matches hyprlang `exec`
-- semantics; mkdir is idempotent and re-generating the keybinds hint on
-- reload is the desired behaviour.
hl.exec_cmd(mkdir_cmd .. " & " .. keybinds_hint_cmd)

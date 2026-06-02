--[[
    DOORwayDE shared variable module.

    All Phase 6 core files (dynamic, startup, finale) that need shared state
    do `local vars = require("variables")` to access these values.

    lua's require() caches modules, so requiring this from multiple files
    returns the same table — no re-evaluation.

    Originally `variables.conf` (hyprlang). Hyprland 0.55+ lua migration.
--]]

local M = {
    -- Modifier
    mainMod = "SUPER",
    MOD     = "SUPER",

    -- App commands (mirror hyprlang $VAR names so keybindings.lua can read them)
    QUICKAPPS  = "",
    BROWSER    = "doorwayde-shell open --fall firefox web-browser",
    EDITOR     = "doorwayde-shell open --fall code-oss text-editor",
    EXPLORER   = "doorwayde-shell open --fall dolphin file-manager",
    TERMINAL   = "doorwayde-shell app -T",
    LOCKSCREEN = "hyprlock",
    KILLACTIVE = 'hyprctl dispatch killactive ""',

    -- GTK / colour scheme
    GTK_THEME     = "Wallbash-Gtk",
    ICON_THEME    = "Tela-dracula",
    COLOR_SCHEME  = "prefer-dark",
    BUTTON_LAYOUT = "",

    -- Cursor
    CURSOR_THEME = "oreo_spark_pink_cursors",
    CURSOR_SIZE  = 24,

    -- Fonts
    FONT                = "Cantarell",
    FONT_SIZE           = 10,
    DOCUMENT_FONT       = "Cantarell",
    DOCUMENT_FONT_SIZE  = 10,
    MONOSPACE_FONT      = "CaskaydiaCove Nerd Font Mono",
    MONOSPACE_FONT_SIZE = 9,
    NOTIFICATION_FONT   = "Mononoki Nerd Font Mono",
    BAR_FONT            = "JetBrainsMono Nerd Font",
    MENU_FONT           = "JetBrainsMono Nerd Font",
    GROUPBAR_FONT       = "JetBrainsMono Nerd Font",
    FONT_ANTIALIASING   = "rgba",
    FONT_HINTING        = "",

    -- Extras
    CODE_THEME = "",
    SDDM_THEME = "",

    -- Note: the historical `start` table (per-service exec strings for the HyDE-era
    -- launch-unit.sh + app() pattern) was removed in Pass 7+ once every entry was
    -- migrated to declarative systemd.user.services in flake.nix (Passes 2-6.5) or
    -- to system-level NixOS modules (gnome-keyring → services.gnome.gnome-keyring
    -- in HALLway). See TODO.md Phase 9 for the migration history.
}

return M

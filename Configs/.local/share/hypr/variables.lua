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
    ICON_THEME    = "Tela-circle-dracula",
    COLOR_SCHEME  = "prefer-dark",
    BUTTON_LAYOUT = "",

    -- Cursor
    CURSOR_THEME = "Bibata-Modern-Ice",
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

    -- Startup commands (used by startup.lua)
    start = {
        -- AUTH_DIALOGUE: declarative (systemd.user.services.doorwayde-polkit-auth).
        -- TODO Pass 7+: gnome-keyring → cross-flake migration. HALLway needs
        -- `services.gnome.gnome-keyring.enable = true` (system-level for PAM
        -- auto-unlock). Until that lands, keep this runtime daemon launch.
        GNOME_KEYRING        = "gnome-keyring-daemon --start --daemonize --components=secrets,pkcs11,ssh",

        -- All other historical entries (BAR, NOTIFICATIONS, WALLPAPER, BATTERY_NOTIFY,
        -- TEXT/IMAGE_CLIPBOARD, APPLET_*, IDLE_DAEMON, BLUE_LIGHT_FILTER, XDG_PORTAL_RESET,
        -- AUTH_DIALOGUE, CLIPBOARD_PERSIST) are now declarative systemd.user.services in
        -- flake.nix or removed. See TODO.md Phase 9 Passes 2-7 for the audit trail.
    },
}

return M

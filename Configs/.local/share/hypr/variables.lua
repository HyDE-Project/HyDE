--[[
    DOORwayDE shared variable module.

    All Phase 6 core files (dynamic, startup, finale) that need shared state
    do `local vars = require("variables")` to access these values.

    lua's require() caches modules, so requiring this from multiple files
    returns the same table — no re-evaluation.

    Originally `variables.conf` (hyprlang). Hyprland 0.55+ lua migration.
--]]

local home = os.getenv("HOME")
local scrPath = home .. "/.local/lib/doorwayde"

-- Session desktop is used to build systemd unit names (doorwayde-Hyprland-*)
local session_desktop = os.getenv("XDG_SESSION_DESKTOP") or "Hyprland"
local unt = "doorwayde-" .. session_desktop

-- Environment list propagated to dbus/systemd for XDG portal handoff
local list_environment = "WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP XDG_CONFIG_HOME QT_QPA_PLATFORMTHEME"

-- Unit helper: `app -u doorwayde-Hyprland-<name>.<type> -t <type> -- `
-- Absolute path avoids PATH-resolution failures in Hyprland's exec-once environment.
local function app(name, type)
    return home .. "/.local/bin/doorwayde-shell app -u " .. unt .. "-" .. name .. "." .. type .. " -t " .. type .. " -- "
end

local M = {
    -- Modifier
    mainMod = "SUPER",
    MOD     = "SUPER",

    -- Script path
    scrPath = scrPath,

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
        DBUS_SHARE_PICKER    = "dbus-update-activation-environment --systemd " .. list_environment,
        SYSTEMD_SHARE_PICKER = "systemctl --user import-environment " .. list_environment,
        XDG_PORTAL_RESET     = home .. "/.local/bin/doorwayde-shell resetxdgportal.sh",
        AUTH_DIALOGUE        = home .. "/.local/bin/doorwayde-shell app -t service -- polkitkdeauth.sh",

        IDLE_DAEMON              = app("idle", "service") .. "hypridle",
        BLUE_LIGHT_FILTER_DAEMON = app("blue-light-filter", "service") .. "hyprsunset",
        TEXT_CLIPBOARD           = app("text-clipboard", "service") .. "wl-paste --type text --watch cliphist store",
        IMAGE_CLIPBOARD          = app("image-clipboard", "service") .. "wl-paste --type image --watch cliphist store",
        CLIPBOARD_PERSIST        = app("clipboard-persist", "service") .. "wl-clip-persist --clipboard regular",

        WALLPAPER      = app("wallpaper", "service") .. "wallpaper.sh --start --global",
        BAR            = app("bar", "scope") .. "waybar.py --watch",
        NOTIFICATIONS  = app("notifications", "service") .. "dunst",
        BATTERY_NOTIFY = app("battery-notify", "service") .. "batterynotify.sh",

        APPLET_NETWORK_MANAGER  = app("network-manager-applet", "service") .. "nm-applet --indicator",
        APPLET_REMOVABLE_MEDIA  = app("removable-media-applet", "service") .. "udiskie --no-automount --smart-tray",
        APPLET_BLUETOOTH        = app("bluetooth-applet", "service") .. "blueman-applet",
    },
}

return M

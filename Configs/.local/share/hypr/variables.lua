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
    return home .. "/.local/lib/doorwayde/launch-unit.sh -u " .. unt .. "-" .. name .. "." .. type .. " -t " .. type .. " -- "
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
        -- Env propagation: defensive duplication. UWSM (HALLway's session entry)
        -- already does this before Hyprland starts; keeping this call covers
        -- non-UWSM session entry (TTY login, debugging). See TODO.md Pass 6.
        SYSTEMD_SHARE_PICKER = "systemctl --user import-environment " .. list_environment,
        -- XDG_PORTAL_RESET, AUTH_DIALOGUE: declarative
        -- (systemd.user.services.doorwayde-{xdg-portal-reset,polkit-auth})
        -- TODO Pass 6.5/7: gnome-keyring → cross-flake migration. HALLway needs
        -- `services.gnome.gnome-keyring.enable = true` (system-level for PAM
        -- auto-unlock). Until that lands, keep this runtime daemon launch.
        GNOME_KEYRING        = "gnome-keyring-daemon --start --daemonize --components=secrets,pkcs11,ssh",

        -- IDLE_DAEMON, BLUE_LIGHT_FILTER_DAEMON: declarative
        -- (systemd.user.services.doorwayde-{idle,blue-light-filter} in flake.nix)
        -- TEXT_CLIPBOARD, IMAGE_CLIPBOARD: declarative
        -- (systemd.user.services.doorwayde-{text,image}-clipboard in flake.nix)
        CLIPBOARD_PERSIST        = app("clipboard-persist", "service") .. "wl-clip-persist --clipboard regular",

        -- BAR, WALLPAPER, NOTIFICATIONS, BATTERY_NOTIFY: all declarative
        -- (systemd.user.services.doorwayde-{waybar,wallpaper,notifications,battery-notify})
        -- See TODO.md Phase 9 Passes 2 & 4 for the migration rationale.

        -- APPLET_NETWORK_MANAGER, APPLET_REMOVABLE_MEDIA, APPLET_BLUETOOTH:
        -- declarative (systemd.user.services.doorwayde-{network-manager,removable-media,bluetooth}-applet)
    },
}

return M

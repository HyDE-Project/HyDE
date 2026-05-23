--[[
    DOORwayDE startup.lua — exec-once autostart chain.
    Originally startup.conf (hyprlang).

    Order matters: exec-once entries fire sequentially as declared, so
    portal setup precedes any GUI client that talks to xdg-desktop-portal.
--]]

local home = os.getenv("HOME")
local vars = require("variables")

-- // █░░ ▄▀█ █░█ █▄░█ █▀▀ █░█
-- // █▄▄ █▀█ █▄█ █░▀█ █▄▄ █▀█

hl.config({
    exec_once = {
        -- Core: hardcoded fallback runs first in case the curated picker fails
        "dbus-update-activation-environment --systemd --all",
        vars.start.DBUS_SHARE_PICKER,
        vars.start.SYSTEMD_SHARE_PICKER,
        vars.start.XDG_PORTAL_RESET,

        vars.start.AUTH_DIALOGUE,

        vars.start.BAR,
        vars.start.NOTIFICATIONS,
        vars.start.WALLPAPER,

        vars.start.TEXT_CLIPBOARD,
        vars.start.IMAGE_CLIPBOARD,
        -- vars.start.CLIPBOARD_PERSIST,  -- Tends to hang wl-clipboard

        vars.start.APPLET_NETWORK_MANAGER,
        vars.start.APPLET_REMOVABLE_MEDIA,
        vars.start.APPLET_BLUETOOTH,
        vars.start.BATTERY_NOTIFY,

        vars.start.IDLE_DAEMON,
        vars.start.BLUE_LIGHT_FILTER_DAEMON,

        -- doorwayde/config.toml parser daemon
        home .. "/.local/bin/doorwayde-shell app -t service doorwayde-config --no-startup",

        -- Cursor must be set after the theme is resolved
        "hyprctl setcursor " .. vars.CURSOR_THEME .. " " .. tostring(vars.CURSOR_SIZE),
    },
})

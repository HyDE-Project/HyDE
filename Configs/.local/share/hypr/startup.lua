--[[
    DOORwayDE startup.lua — exec-once autostart chain.

    Hyprland 0.55+ lua API: exec-once is not a `hl.config` key. The schema
    in /nix/store/.../hyprland-0.55.2/share/hypr/stubs/hl.meta.lua accepts
    only declarative section keys; unknown keys are silently dropped.
    Side-effects ride lifecycle events instead.

    `hyprland.start` fires once IPC is ready, matching hyprlang exec-once.
--]]

local home = os.getenv("HOME")
local vars = require("variables")

hl.on("hyprland.start", function()
    -- Portal/dbus handoff must run before any GUI client opens
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd(vars.start.DBUS_SHARE_PICKER)
    hl.exec_cmd(vars.start.SYSTEMD_SHARE_PICKER)
    hl.exec_cmd(vars.start.XDG_PORTAL_RESET)

    hl.exec_cmd(vars.start.AUTH_DIALOGUE)
    hl.exec_cmd(vars.start.GNOME_KEYRING)

    hl.exec_cmd(vars.start.BAR)
    hl.exec_cmd(vars.start.NOTIFICATIONS)
    hl.exec_cmd(vars.start.WALLPAPER)

    hl.exec_cmd(vars.start.TEXT_CLIPBOARD)
    hl.exec_cmd(vars.start.IMAGE_CLIPBOARD)
    -- hl.exec_cmd(vars.start.CLIPBOARD_PERSIST)  -- Tends to hang wl-clipboard

    hl.exec_cmd(vars.start.APPLET_NETWORK_MANAGER)
    hl.exec_cmd(vars.start.APPLET_REMOVABLE_MEDIA)
    hl.exec_cmd(vars.start.APPLET_BLUETOOTH)
    hl.exec_cmd(vars.start.BATTERY_NOTIFY)

    hl.exec_cmd(vars.start.IDLE_DAEMON)
    hl.exec_cmd(vars.start.BLUE_LIGHT_FILTER_DAEMON)

    hl.exec_cmd(home .. "/.local/lib/doorwayde/launch-unit.sh -u " .. unt .. "-doorwayde-config.service -t service -- doorwayde-config --no-startup")

    -- Cursor: must run inside hyprland.start so hyprctl IPC is reachable
    hl.exec_cmd("hyprctl setcursor " .. vars.CURSOR_THEME .. " " .. tostring(vars.CURSOR_SIZE))
end)

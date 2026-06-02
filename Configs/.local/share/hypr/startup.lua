--[[
    DOORwayDE startup.lua — exec-once autostart chain.

    Hyprland 0.55+ lua API: exec-once is not a `hl.config` key. The schema
    in /nix/store/.../hyprland-0.55.2/share/hypr/stubs/hl.meta.lua accepts
    only declarative section keys; unknown keys are silently dropped.
    Side-effects ride lifecycle events instead.

    `hyprland.start` fires once IPC is ready, matching hyprlang exec-once.
--]]

local vars = require("variables")

hl.on("hyprland.start", function()
    -- Cursor: must run inside hyprland.start so hyprctl IPC is reachable.
    -- Everything else is declarative (flake.nix systemd.user.services.*);
    -- UWSM handles env propagation before Hyprland starts; HALLway-side
    -- services.gnome.gnome-keyring.enable handles the keyring daemon + PAM.
    hl.exec_cmd("hyprctl setcursor " .. vars.CURSOR_THEME .. " " .. tostring(vars.CURSOR_SIZE))
end)

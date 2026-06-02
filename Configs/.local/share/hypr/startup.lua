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
    -- gnome-keyring cross-flake migration deferred — HALLway must provide
    -- services.gnome.gnome-keyring.enable for PAM auto-unlock before this
    -- runtime daemon launch can be removed safely.
    hl.exec_cmd(vars.start.GNOME_KEYRING)

    -- Cursor: must run inside hyprland.start so hyprctl IPC is reachable.
    hl.exec_cmd("hyprctl setcursor " .. vars.CURSOR_THEME .. " " .. tostring(vars.CURSOR_SIZE))

    -- Everything else is declarative — see flake.nix systemd.user.services.*
    -- and TODO.md Phase 9. UWSM handles env propagation before Hyprland starts.
end)

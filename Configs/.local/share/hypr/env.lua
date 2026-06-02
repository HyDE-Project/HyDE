--[[
    DOORwayDE environment variables for Hyprland-spawned processes.

    Hyprland 0.55+ lua API: env vars are set via the top-level hl.env(K, V)
    function, not via hl.config({ env = ... }). The latter is silently
    dropped because `env` is not a valid HL.ConfigKey.

    See https://wiki.hypr.land/Configuring/Environment-variables/

    Qt/Wayland/toolkit vars (QT_*, MOZ_*, GDK_*, ELECTRON_*) were moved to
    home.sessionVariables in flake.nix in Pass 11 — they're now set session-wide
    by Home Manager before UWSM starts. The XDG vars and PATH below remain here
    as a defensive layer so Hyprland-spawned child processes always see the
    correct environment even if the session init chain changes upstream.
--]]

local home = os.getenv("HOME")
local existing_path = os.getenv("PATH") or ""

local envs = {
    -- XDG desktop identity (Hyprland-child env; UWSM preloads these too)
    {"XDG_CURRENT_DESKTOP", "Hyprland"},
    {"XDG_SESSION_TYPE",    "wayland"},
    {"XDG_SESSION_DESKTOP", "Hyprland"},

    -- DOORwayDE: user bin + script library on PATH
    {"PATH", home .. "/.local/bin:" .. home .. "/.local/lib/doorwayde:" .. existing_path},

    -- XDG dirs (defensive; Home Manager + PAM set these at login)
    {"XDG_CONFIG_HOME", home .. "/.config"},
    {"XDG_CACHE_HOME",  home .. "/.cache"},
    {"XDG_DATA_HOME",   home .. "/.local/share"},
    {"XDG_STATE_HOME",  home .. "/.local/state"},
}

for _, e in ipairs(envs) do
    hl.env(e[1], e[2])
end

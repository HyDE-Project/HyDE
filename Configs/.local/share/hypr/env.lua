--[[
    DOORwayDE environment variables.

    Hyprland 0.55+ lua API: env vars are set via the top-level hl.env(K, V)
    function, not via hl.config({ env = ... }). The latter is silently
    dropped because `env` is not a valid HL.ConfigKey.

    See https://wiki.hypr.land/Configuring/Environment-variables/

    Most of these are redundant with uwsm preloading + home.sessionPath in
    flake.nix — the rebuild already exports the same XDG/PATH values into
    the systemd user environment. We set them again here so that the
    Hyprland-spawned process environment matches the curated set even if
    uwsm changes upstream.
--]]

local home = os.getenv("HOME")
local existing_path = os.getenv("PATH") or ""

local envs = {
    -- XDG Spec
    {"XDG_CURRENT_DESKTOP", "Hyprland"},
    {"XDG_SESSION_TYPE",    "wayland"},
    {"XDG_SESSION_DESKTOP", "Hyprland"},

    -- Qt
    {"QT_AUTO_SCREEN_SCALE_FACTOR",        "1"},
    {"QT_QPA_PLATFORM",                    "wayland;xcb"},
    {"QT_WAYLAND_DISABLE_WINDOWDECORATION", "1"},
    {"QT_QPA_PLATFORMTHEME",               "qt6ct"},

    -- Wayland / toolkit
    {"MOZ_ENABLE_WAYLAND",          "1"},
    {"GDK_SCALE",                   "1"},
    {"ELECTRON_OZONE_PLATFORM_HINT", "auto"},

    -- DOORwayDE: user bin + script library on PATH
    {"PATH", home .. "/.local/bin:" .. home .. "/.local/lib/doorwayde:" .. existing_path},

    -- XDG dirs
    {"XDG_CONFIG_HOME", home .. "/.config"},
    {"XDG_CACHE_HOME",  home .. "/.cache"},
    {"XDG_DATA_HOME",   home .. "/.local/share"},
    {"XDG_STATE_HOME",  home .. "/.local/state"},
}

for _, e in ipairs(envs) do
    hl.env(e[1], e[2])
end

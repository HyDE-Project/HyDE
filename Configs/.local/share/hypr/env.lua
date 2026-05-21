--[[
    DOORwayDE environment variables.

    Originally `env.conf` (hyprlang). Hyprland 0.55+ lua migration.

    The hyprlang source distinguished between `$env.X = ...` lua-style
    variables (used only for in-config interpolation) and real `env = K,V`
    declarations. Only the latter survive translation — actual env exports.

    The `# hyprlang if !VAR` guards were defensive against pre-set values;
    hyprland's `env` keyword overrides anyway, so they're emitted
    unconditionally here.

    See https://wiki.hypr.land/Configuring/Environment-variables/
--]]

local home = os.getenv("HOME")
local existing_path = os.getenv("PATH") or ""

-- DOORwayDE PATH: prefix user bin and the doorwayde script library.
-- Originally built from $scrPath in variables.conf; hardcoded here to keep
-- env.lua self-contained (it loads before variables.lua is required).
local doorwayde_path = "PATH,"
    .. home .. "/.local/bin:"
    .. home .. "/.local/lib/doorwayde:"
    .. existing_path

hl.config({
    env = {
        -- // █▀▀ █▄░█ █░█
        -- // ██▄ █░▀█ ▀▄▀

        -- XDG Spec
        "XDG_CURRENT_DESKTOP,Hyprland",
        "XDG_SESSION_TYPE,wayland",
        "XDG_SESSION_DESKTOP,Hyprland",

        -- Qt
        "QT_AUTO_SCREEN_SCALE_FACTOR,1",
        "QT_QPA_PLATFORM,wayland;xcb",
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1",
        "QT_QPA_PLATFORMTHEME,qt6ct",

        -- Wayland / toolkit
        "MOZ_ENABLE_WAYLAND,1",
        "GDK_SCALE,1",
        "ELECTRON_OZONE_PLATFORM_HINT,auto",

        -- DOORwayDE
        doorwayde_path,

        -- XDG dirs
        "XDG_CONFIG_HOME," .. home .. "/.config",
        "XDG_CACHE_HOME," .. home .. "/.cache",
        "XDG_DATA_HOME," .. home .. "/.local/share",
        "XDG_STATE_HOME," .. home .. "/.local/state",
    },
})

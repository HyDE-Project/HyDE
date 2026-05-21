--[[
    █▀▄▀█ █▀█ █▄░█ █ ▀█▀ █▀█ █▀█ █▀
    █░▀░█ █▄█ █░▀█ █ ░█░ █▄█ █▀▄ ▄█

    Monitor Configuration
    https://wiki.hypr.land/Configuring/Monitors/

    Edit this file to configure your displays.
--]]

--------------------------------------------------------------------------------
-- Monitor Setup
--------------------------------------------------------------------------------
-- Format: hl.monitor({ output, mode, position, scale })
--
-- Examples:
--   hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "0x0", scale = "1" })
--   hl.monitor({ output = "DP-1", mode = "2560x1440@144", position = "1920x0", scale = "1" })
--   hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
--
-- To find your monitor names: hyprctl monitors
--------------------------------------------------------------------------------

-- Atari VCS 800 - 1080p @ 100Hz
hl.monitor({
    output   = "HDMI-A-1",
    mode     = "1920x1080@100",
    position = "0x0",
    scale    = "1",
})

-- Uncomment to add additional monitors:
-- hl.monitor({
--     output   = "DP-1",
--     mode     = "preferred",
--     position = "auto",
--     scale    = "auto",
-- })

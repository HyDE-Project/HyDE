--[[
    DOORwayDE core orchestrator (lua).

    Loaded from the user's ~/.config/hypr/hyprland.lua via dofile().
    Sets up package.path so subsequent require()s can find sibling
    modules under ~/.local/share/hypr/.

    Original chain — see ~/.local/share/doorwayde/hyprland.conf (hyprlang).
--]]

local home = os.getenv("HOME")
local xdg_data = os.getenv("XDG_DATA_HOME") or (home .. "/.local/share")
local xdg_config = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
local hypr_data = xdg_data .. "/hypr"
local hypr_config = xdg_config .. "/hypr"

-- Add ~/.local/share/hypr/ to package.path so require("env") etc. resolve there
package.path = hypr_data .. "/?.lua;" .. package.path

-- Environment first so child processes inherit
require("env")

-- Shared variable module — other files require this too, lua caches it
require("variables")

-- Defaults (monitor fallback, decoration, animations, input, layouts)
require("defaults")

-- Core DOORwayDE window rules
require("windowrules")

-- Dynamic theming (sources colors/theme/wallbash, groupbar config)
require("dynamic")

-- Startup daemons (exec_once)
require("startup")

-- Workflows preset (user config — already in package.path via hyprland's default)
-- Loaded here so it overrides defaults/dynamic at the right point
require("workflows")

-- Finale: doorwayde:* custom keywords for fast hyprctl queries (must be last)
require("finale")

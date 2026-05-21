--[[
    ░▒▒▒░░░▓▓           ___________
  ░░▒▒▒░░░░░▓▓        //___________/
 ░░▒▒▒░░░░░▓▓     ___   ___   ___  ___
 ░░▒▒░░░░░▓▓▓▓▓▓ |   \ / _ \ / _ \| _ \__ __ ____ _ _  _ ___  ___
  ░▒▒░░░░▓▓   ▓▓ | |) | (_) | (_) |   /\ V  V / _` | || |   \| __|
   ░▒▒░░▓▓   ▓▓  |___/ \___/ \___/|_|_\ \_/\_/\__,_|\_, |___/|___|
     ░▒▓▓   ▓▓                                      |__/

    DOORwayDE - Hyprland Desktop Environment for HALLway OS
    https://github.com/MarkusBitterman/DOORwayDE

    Configuration: hyprland.lua (Hyprland 0.55+ lua format)

    You can freely edit this file!
    See https://wiki.hypr.land/Configuring/Start/ for documentation.
--]]

-- DOORwayDE marker (prevents file overwrite by scripts)
DOORWAYDE_HYPRLAND = true

--------------------------------------------------------------------------------
-- XDG Directories
--------------------------------------------------------------------------------

local home = os.getenv("HOME")
local xdg_data = os.getenv("XDG_DATA_HOME") or (home .. "/.local/share")

--------------------------------------------------------------------------------
-- User Configuration
-- Edit these files to customize your setup
--------------------------------------------------------------------------------

require("monitors")      -- Monitor configuration
require("userprefs")     -- User preferences (keyboard, input settings)
require("windowrules")   -- Custom window rules
require("keybindings")   -- Keyboard shortcuts

--------------------------------------------------------------------------------
-- DOORwayDE core orchestrator
-- Loads env, variables, defaults, core-windowrules, dynamic, startup,
-- workflows, and finale in the canonical order.
--------------------------------------------------------------------------------

local doorwayde_data = xdg_data .. "/doorwayde"
dofile(doorwayde_data .. "/hyprland.lua")

--[[
    Migration Progress — see TODO.md for full tracking.
    Phases 1–6 complete. Phase 7 (cleanup: deploy .lua via flake, remove .conf files) pending.
--]]

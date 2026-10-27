-- Luacheck config for HyDE's Hyprland Lua configs.
--
-- These files run inside Hyprland's Lua host, which injects globals that
-- luacheck cannot see. Declaring them here is what keeps the pre-commit
-- luacheck hook from flagging every line of config.lua.
--
--   hl             Hyprland's API table, injected by the host
--   hyde           HyDE's own namespace, set up in hyde.lua / hyde/utils.lua
--   check_require  hyde.utils.check_require, exposed globally by utils.lua
--   _F             shared bind-options table reused across key_binds/layouts
globals = { "hl", "hyde", "check_require", "_F" }

-- Hyprland's Lua files are not a library: they are loaded for side effects and
-- legitimately leave globals behind.
unused_args = false

-- Long lines are fine in the config trees; keep the check for everything else.
max_line_length = false

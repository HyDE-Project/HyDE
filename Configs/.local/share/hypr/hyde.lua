--!      ░▒▒▒░░░▓▓           ___________
--!    ░░▒▒▒░░░░░▓▓        //___________/
--!   ░░▒▒▒░░░░░▓▓     _   _ _    _ _____
--!   ░░▒▒░░░░░▓▓▓▓▓▓ | | | | |  | |  __/
--!    ░▒▒░░░░▓▓   ▓▓ | |_| | |_/ /| |___
--!     ░▒▒░░▓▓   ▓▓   \__  |____/ |____/
--!       ░▒▓▓   ▓▓  //____/

-- // ██████╗░░█████╗░  ███╗░░██╗░█████╗░████████╗  ███████╗██████╗░██╗████████╗
-- // ██╔══██╗██╔══██╗  ████╗░██║██╔══██╗╚══██╔══╝  ██╔════╝██╔══██╗██║╚══██╔══╝
-- // ██║░░██║██║░░██║  ██╔██╗██║██║░░██║░░░██║░░░  █████╗░░██║░░██║██║░░░██║░░░
-- // ██║░░██║██║░░██║  ██║╚████║██║░░██║░░░██║░░░  ██╔══╝░░██║░░██║██║░░░██║░░░
-- // ██████╔╝╚█████╔╝  ██║░╚███║╚█████╔╝░░░██║░░░  ███████╗██████╔╝██║░░░██║░░░
-- // ╚═════╝░░╚════╝░  ╚═╝░░╚══╝░╚════╝░░░░╚═╝░░░  ╚══════╝╚═════╝░╚═╝░░░╚═╝░░░

-- Hyprland builds the Lua search path from the directory of the config it was
-- started with and prepends nothing else, so a module shipped beside this file
-- is reachable by name only while this file is that config. Since v26.8.1 the
-- entry point is the user's hyprland.lua, which anchors the search path at
-- ~/.config/hypr and leaves nothing here within reach.
--
-- The resolver is therefore loaded by path, and with dofile rather than
-- require. Hyprland wraps require: a module that fails for any reason other
-- than "not found" is logged and answered with an empty table, which would
-- reach the session as an unresolved path several modules later instead of as
-- an error on the line that caused it. The config directory is prepended to
-- the search path as well, so a file the user happens to keep at
-- hypr/hyde/path.lua would answer to the name first. Neither can happen to a
-- dofile of a path this file resolved itself, and registering the result under
-- the name the rest of the tree uses keeps a later require on the same table.
--
-- Everything below loads by name, from the search path this block sets.
local root =
	assert(
		debug.getinfo(1, "S").source:match("^@(.*)/"),
		"HyDE's entry point was not loaded from a file, so it cannot reach the modules shipped beside it"
	)

hyde = hyde or {}
hyde.path = dofile(root .. "/lua/hyde/path.lua")
package.loaded["hyde.path"] = hyde.path

local pkg_paths = {
	hyde.path.state .. "/hyde/?.lua", -- Lua state
	hyde.path.lib .. "/hyde/?.lua", -- lib scripts
	hyde.path.lib .. "/hyde/luautils/?.lua", -- lib scripts
	hyde.path.share .. "/hypr/lua/?.lua",
	hyde.path.state .. "/hyde/lua_env/share/lua/5.5/?.lua", -- virtual env for lua
	hyde.path.state .. "/hyde/lua_env/share/lua/5.5/?/init.lua", -- virtual env for lua
	hyde.path.config .. "/hypr/?.lua", -- expose main users config
	root .. "/lua/?.lua" -- the tree shipped beside this file, whichever prefix it was installed under
}

package.path = package.path .. ";" .. table.concat(pkg_paths, ";") .. ";"
package.cpath = package.cpath .. ";" .. hyde.path.state .. "/hyde/lua_env/lib/lua/5.5/?.so" -- virtual env shared objects

-- Let's call it early so we can use it in other files
require("hyde.utils")
require("hyde.env")
require("hyde.config")
require("hyde.binds")
require("hyde.dispatcher")
require("hyde.handlers")

-- * Variables
require("variables")
-- * Default values
require("defaults")
--* Window rules
require("window_rules")
--* Layer rules
require("layer_rules")
-- * Environment variable Setup
require("env")
--* Dynamic Stuff example theming and variable handlings
require("dynamic")
-- * Binds
require("key_binds")
-- * Event handlers for more DE like experience
require("events")
--* HyDE's startup overridable too!
require("start_up")
-- --* user now can have this file
check_require("hyprland")
-- --* workflows configuration overrides everything
check_require("lua_state.workflows")

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

-- Hyprland anchors require() at the directory of the config it was started
-- with, and nowhere else, so a module shipped beside this file is reachable by
-- name only while this file is that config. Since v26.8.1 the entry point is
-- the user's hyprland.lua, which anchors the search path at ~/.config/hypr and
-- puts nothing here within reach. The bootstrap therefore comes off this
-- file's own path; everything after it loads by name from the search path this
-- block sets, so this is the only place that may not rely on one.
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

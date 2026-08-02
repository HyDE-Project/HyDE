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

hyde = hyde or {}
hyde.path = require("lua.hyde.path")

local pkg_paths = {
	hyde.path.state .. "/hyde/?.lua", -- Lua state
	hyde.path.lib .. "/hyde/?.lua", -- lib scripts
	hyde.path.lib .. "/hyde/luautils/?.lua", -- lib scripts
	hyde.path.share .. "/hypr/lua/?.lua",
	hyde.path.state .. "/hyde/lua_env/share/lua/5.5/?.lua", -- virtual env for lua
	hyde.path.state .. "/hyde/lua_env/share/lua/5.5/?/init.lua", -- virtual env for lua
	hyde.path.config .. "/hypr/?.lua" -- expose main users config
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

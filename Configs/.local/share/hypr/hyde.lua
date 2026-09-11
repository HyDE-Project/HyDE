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

-- require() resolves against the directory of the config Hyprland was started
-- with, which since v26.8.1 is the user's hyprland.lua, not this file. The
-- resolver is therefore loaded by its own path; everything below loads by name
-- from the search path it sets.
local root = assert(debug.getinfo(1, "S").source:match("^@(.*)/"), "not loaded from a file")

---@module "hyde"
hyde = hyde or {}
---@diagnostic disable-next-line: inject-field
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
	root .. "/lua/?.lua" -- this file's own tree, whatever prefix it sits under
}

package.path = package.path .. ";" .. table.concat(pkg_paths, ";") .. ";"
package.cpath = package.cpath
	.. ";"
	.. hyde.path.state
	.. "/hyde/lua_env/lib/lua/5.5/?.so" -- virtual env shared objects

-- Let's call it early so we can use it in other files
local utils = require("hyde.utils")
require("hyde.env")
require("hyde.config")
require("hyde.binds")
require("hyde.dispatcher")
require("hyde.handlers")

local check_require = utils.check_require

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
-- * Binds
require("key_binds")
--* Dynamic Stuff example theming and variable handlings
require("dynamic")
-- * Event handlers for more DE like experience
require("events")
--* HyDE's startup overridable too!
require("start_up")
-- * Automatically load generated monitor configs (e.g., from nwg-displays)
check_require("monitors")
-- --* user now can have this file
check_require("hyprland")
-- --* workflows configuration overrides everything
check_require("lua_state.workflows")

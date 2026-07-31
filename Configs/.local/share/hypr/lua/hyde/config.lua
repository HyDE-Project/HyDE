-- config.lua

-- Main Hyprland Lua config file
-- This is loaded before any other files
-- Users can declare their config in ~/.config/hypr/hyprland.lua

_G.hyde = _G.hyde or {}
hyde.config = hyde.config or {}

-- ! Experimental! !
hyde.get_config = hyde.get_config or {}
function hyde.get_config(path)
	local cur = hyde.config
	for part in path:gmatch("[^.]+") do
		cur = cur[part]
	end
	return cur
end

function hyde.config.get(path)
	return function()
		return hyde.get_config(path)
	end
end

-- We use this to make hyde.config reactive in binds and handlers
-- this is not so cheap , but useful if we want to respect `hyde.config...  = values otf
-- without redeclaring binds and handlers, so we can change behavior on the fly by just changing config values!
-- This is analoggus to `hyde.dsp.exec_cmd`
function hyde.config.exec(path)
	return function()
		local cmd = hyde.get_config(path)
		if type(cmd) ~= "string" or cmd == "" then
			return
		end
		if type(hl.notification.create) == "function" then
			hl.notification.create(
				{
					text = "Launching " .. cmd,
					timeout = 1000
				}
			)
		end
		if type(hl.dsp.exec_cmd) == "function" then
			hl.dispatch(hl.dsp.exec_cmd(cmd))
		end
	end
end

-- * Stable *

local function merge_config(dest, src, opts)
	for k, v in pairs(src) do
		if type(v) == "table" and type(dest[k]) == "table" then
			merge_config(dest[k], v, opts)
		elseif opts and opts.skip_empty and (v == "" or v == nil) then
			-- preserve existing destination value when source is empty
		else
			dest[k] = v
		end
	end
end

function hyde.config.apply(cfg, opts)
	if type(cfg) ~= "table" then
		return hyde.config
	end
	merge_config(hyde.config, cfg, opts)
	return hyde.config
end

setmetatable(
	hyde.config,
	{
		__call = function(t, cfg, opts)
			return hyde.config.apply(cfg, opts)
		end
	}
)

-- * config.toml
local ok, toml = pcall(check_require, "toml")
if not ok then
	local message = "[HyDE] Hyprland does not detect TOML parser! Run: hyde-shell luainit"
	if type(hl.exec_cmd) == "function" then
		hl.exec_cmd("hyprctl seterror 'rgba(c79bf0ff)' " .. message)
	end
	toml = nil
end

function hyde.config.load_toml(filename)
	if type(toml) ~= "table" or type(toml.parse) ~= "function" then
		-- error("TOML parser not available")
		return -- Silent failure if TOML parser is not available, as this is an optional feature
	end
	local ok, data = pcall(toml.parse, filename)
	if not ok then
		error("Failed to parse TOML: " .. tostring(data))
	end

	if type(data) ~= "table" then
		return hyde.config
	end

	local desktop = data.desktop
	if type(desktop) == "table" then
		if type(desktop.apps) == "table" and desktop.app == nil then
			desktop.app = desktop.apps
		end
		hyde.config.apply(desktop)
	end

	local hyprland = data.hyprland
	if type(hyprland) == "table" then
		hyde.config.apply(hyprland)
	end

	return hyde.config
end

local default_config = {
	ui = {
		hyde_theme = nil,
		-- gtk
		gtk_theme = nil,
		icon_theme = nil,
		color_scheme = nil,
		button_layout = nil,
		-- Cursor
		cursor_theme = nil,
		cursor_size = nil,
		-- Fonts
		font = nil,
		font_size = nil,
		document_font = nil,
		document_font_size = nil,
		monospace_font = nil,
		monospace_font_size = nil,
		notification_font = nil,
		bar_font = nil,
		menu_font = nil,
		font_antialiasing = nil,
		font_hinting = nil,
		-- Extra Themes
		code_theme = nil,
		sddm_theme = nil
	},
	wallbash = {
		mode = "theme"
	},
	window = {
		float_size_bounds = {
			enabled = true,
			scale = 0.95,
			force_center = false
		},
		float_follow_cursor = {
			enabled = true,
			mode = "default"
		}
	},
	monitor = {
		edge_margin = {0.01}
	},
	anim = {
		duration_scale = 1.0
	}
}

hyde.config(default_config)
hyde.config.ui = hyde.config.ui or {}
hyde.config.wallbash = hyde.config.wallbash or {}
hyde.config.window = hyde.config.window or {}
hyde.config.window.float = hyde.config.window.float or {}
hyde.config.monitor = hyde.config.monitor or {}
hyde.config.anim = hyde.config.anim or {}
hyde.config.app = hyde.config.app or {}
hyde.config.modifiers = hyde.config.modifiers or {}
hyde.config.start = hyde.config.start or {}

-- Example usage:
--
-- Direct table assignment:
-- hyde.config.ui.groupbar_font = "JetBrainsMono Nerd Font"
-- hyde.config.anim.duration_scale = 0.9
-- hyde.config.window.float_follow_cursor.enabled = true
--
-- Merge a config block safely:
-- hyde.config({
--     ui = {
--         groupbar_font = "JetBrainsMono Nerd Font",
--         icon_theme = "Tela-circle-dracula",
--     },
--     anim = {
--         duration_scale = 0.9,
--     },
--     other = {
--         added = "some other config",
--     },
-- })s
--
-- Bad: do not reassign hyde.config to a new table.
-- This file establishes defaults and merge behavior, so keep the table object intact.
-- Devs! Defualts are in `variables.lua`! Do not set defaults here, only in `variables.lua`! This file is for merge behavior and helper functions!

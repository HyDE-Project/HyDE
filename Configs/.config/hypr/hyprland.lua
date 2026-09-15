-- Hyprland loads this file when it is started without a config, and it prefers
-- it over hyprland.conf. HyDE loads it too, last, as the override layer below.
-- The block keeps the two apart: hyde.lua sets `hyde` on its first line, so it
-- runs only when this file is the entry point and HyDE has not been loaded.
-- Removing it leaves a session with a cursor and nothing else.
if not hyde then
	local share = os.getenv("XDG_DATA_HOME") or (os.getenv("HOME") .. "/.local/share")
	local entry = share .. "/hypr/hyde.lua"
	local handle = io.open(entry, "r")
	if not handle then
		error("HyDE is not installed at " .. entry .. ". Run install.sh -r, or point Hyprland at your own config.")
	end
	handle:close()
	dofile(entry)
end

-- Your Hyprland configuration. HyDE never overwrites this file.
--
-- It loads after HyDE's own binds, so settings here take precedence. Replacing
-- a bind needs more than that: see below. HyDE's defaults live in
-- ~/.local/share/hypr/lua/ and are overwritten on every update, so edits there
-- do not survive.
--
-- Adding a keybind:
--
--     hl.bind("SUPER + SPACE", hl.dsp.exec_cmd(hyde.sh.gamelauncher()), {
--         description = "[Utilities] game launcher",
--     })
--
-- Replacing one of HyDE's: bind the same combination again and yours takes
-- over, but copy its flags across as well. A bind counts as the same one only
-- when its flags match, and `description` is not a flag — miss one and both
-- binds stay live on that combination. Copy the whole options table from
-- ~/.local/share/hypr/lua/key_binds.lua and change only what you need:
--
--     hl.bind("F9", hl.dsp.exec_cmd(hyde.sh.volumecontrol("-o", "m")), {
--         locked = true,
--         description = "[Hardware Controls|Audio] un/mute output",
--     })
--
-- Press SUPER + / to see what is actually loaded, your own binds included.
-- The full reference is KEYBINDINGS.md in the HyDE repository.
--
-- Other Lua files next to this one can be pulled in with require("name").

-- Per-monitor scaling: keep the laptop readable without the aggressive auto 1.5 scale.
hl.monitor({
	output = "eDP-1",
	mode = "preferred",
	position = "0x0",
	scale = 1.25,
})

hl.monitor({
	output = "desc:LG Electronics LG ULTRAGEAR 506NTFAF3659",
	mode = "preferred",
	position = "1536x0",
	scale = 1,
})

-- Solid-first spacing and depth: keep windows opaque and use only small alpha
-- values on the user-owned surfaces (Waybar islands, Rofi and Kitty). Blur is
-- intentionally disabled because the diffuse backdrop is uncomfortable to use.
hl.config({
	cursor = {
		-- Use the native Future-cyan Hyprcursor build; XCursor remains the fallback.
		enable_hyprcursor = true,
	},
	input = {
		-- Spanish (Spain) primary, Latin American Spanish secondary.
		-- Toggle between them with SUPER + K (see key_binds.lua) or the
		-- grp:alt_shift_toggle chord below.
		kb_layout = "es,latam",
		kb_variant = "",
		kb_options = "grp:alt_shift_toggle",
	},
	general = {
		border_size = 2,
		gaps_in = 2,
		-- Top edge: a hairline under the bar, which already sits 3px below the
		-- screen edge. The other edges keep a small, symmetric margin.
		gaps_out = { top = 3, left = 4, right = 4, bottom = 4 },
	},
	decoration = {
		rounding = 8,
		-- 2.0 is a circle and 4.0 a squircle; 2.4 keeps corners soft, not squared.
		rounding_power = 2.4,
		active_opacity = 1,
		inactive_opacity = 1,
		fullscreen_opacity = 1,
		blur = {
			enabled = false,
			popups = false,
			special = false,
			input_methods = false,
		},
		-- Palette-driven depth without a diffuse backdrop.
		shadow = {
			enabled = true,
			range = 22,
			render_power = 3,
			offset = { 0, 6 },
			color = "rgba(061b2b47)",
			color_inactive = "rgba(061b2b26)",
		},
		glow = {
			enabled = false,
		},
	},
})

-- HyDE enables blur on these layer surfaces by default. Keep their small alpha
-- values for a little transparency, but disable the diffuse backdrop entirely.
hl.layer_rule({
	name = "user_solid_layer_surfaces",
	match = {
		namespace = "^(rofi|notifications|swaync-(notification-window|control-center)|logout_dialog|waybar)$",
	},
	blur = false,
	blur_popups = false,
})

-- Animation timings belong to the selected HyDE preset (SUPER + SHIFT + Y);
-- a global override here would flatten every preset into one speed. Only the
-- border gradient is animated: the theme draws a cyan-to-cobalt 45deg gradient
-- and rotating it slowly is the cheapest premium touch available.
hl.curve("user_linear", { type = "bezier", points = { { 1, 1 }, { 1, 1 } } })
hl.animation({
	leaf = "borderangle",
	enabled = true,
	speed = 60,
	bezier = "user_linear",
	style = "loop",
})

-- Keep the user-selected readable fonts after theme changes and reloads.
local function set_interface_font(key, value)
	if value and value ~= "" then
		hl.exec_cmd(string.format("gsettings set org.gnome.desktop.interface %s %q", key, tostring(value)))
	end
end

set_interface_font("font-name", hyde.config.ui.font .. " " .. hyde.config.ui.font_size)
set_interface_font("document-font-name", hyde.config.ui.document_font .. " " .. hyde.config.ui.document_font_size)
set_interface_font("monospace-font-name", hyde.config.ui.monospace_font .. " " .. hyde.config.ui.monospace_font_size)
set_interface_font("font-antialiasing", hyde.config.ui.font_antialiasing)
set_interface_font("font-hinting", hyde.config.ui.font_hinting)

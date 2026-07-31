local color = check_require("lua_state.colors") or {}

if next(color) then
	hl.config(
		{
			general = {
				col = {
					active_border = {colors = {color._pry4_rgba, color._4xa1_rgba}, angle = 45},
					inactive_border = {colors = {color._pry1_rgba, color._pry2_rgba}, angle = 45}
				}
			},
			group = {
				groupbar = {
					enabled = true,
					gradients = 1,
					render_titles = 1,
					font_weight_inactive = "normal",
					font_weight_active = "semibold",
					col = {
						active = {colors = {color._pry3_rgba}, angle = 45},
						inactive = {colors = {color._pry1_rgba}, angle = 45},
						locked_active = {colors = {color._pry2_rgba}, angle = 45},
						locked_inactive = {colors = {color._pry4_rgba}, angle = 45}
					},
					text_color = "rgba(" .. color._txt3 .. "ee)",
					text_color_inactive = "rgba(" .. color._txt1 .. "ee)",
					blur = true,
					font_size = hyde.config.ui.font_size,
					font_family = hyde.config.ui.groupbar_font or hyde.config.ui.font -- fallback to main font if groupbar_font is not set
				},
				col = {
					border_active = {colors = {color._pry4_rgba, color._pry2_rgba}, angle = 45},
					border_inactive = {colors = {color._pry1_rgba, color._pry3_rgba}, angle = 45},
					border_locked_active = {colors = {color._txt3_rgba, color._txt4_rgba}, angle = 45},
					border_locked_inactive = {colors = {color._txt1_rgba, color._txt2_rgba}, angle = 45}
				}
			},
			misc = {
				font_family = hyde.config.ui.font,
				background_color = color._pry1_rgba
			}
		}
	)
else
	local message = "[HyDE] Hyprland does not detect colors! Run: hyde-shell reload"
	hl.exec_cmd("hyprctl seterror 'rgba(c79bf0ff)' " .. message)
end
--

-- Loads the theme config from lua_state.
-- Note this is translated by hyprquery from hyprlang to lua
local theme_config = check_require("lua_state.hypr_theme") or {}
if type(theme_config) == "table" then
    hl.config(theme_config)
end

-- Load the HyDE's ui config
local state_ui = check_require("lua_state.ui") or {}
hyde.config({ui = state_ui.ui or state_ui, wallbash = state_ui.wallbash or {}}, {skip_empty = true}) -- Merge the config safely and ignore blank strings from state UI

-- Loads the user config if there is one. The directory comes from hyde.path,
-- which leaves it nil rather than building a path out of an unset variable, so
-- a session without XDG_CONFIG_HOME skips the optional file instead of dying
-- on a nil concatenation. The probe closes the handle it opens: this runs on
-- every reload, and a leaked one accumulates for the life of the session.
local user_config_path = hyde.path.config and (hyde.path.config .. "/hyde/config.toml")
if user_config_path then
	local user_config = io.open(user_config_path)
	if user_config then
		user_config:close()
		hyde.config.load_toml(user_config_path)
	end
end

check_require("lua_state.animations")
check_require("lua_state.shaders")
check_require("lua_state.layouts")

hl.config(
	{
		group = {
			groupbar = {
				font_size = hyde.config.ui.font_size,
				font_family = hyde.config.ui.groupbar_font or hyde.config.ui.font -- fallback to main font if groupbar_font is not set
			}
		},
		misc = {
			font_family = hyde.config.ui.font
		}
	}
)

local wallbash_mode = (hyde.config.wallbash and hyde.config.wallbash.mode) or "auto"
if wallbash_mode ~= "theme" and next(color) then
	hl.config(
		{
			general = {
				col = {
					active_border = {colors = {color._pry4_rgba, color._4xa1_rgba}, angle = 45},
					inactive_border = {colors = {color._pry1_rgba, color._pry2_rgba}, angle = 45}
				}
			},
			group = {
				groupbar = {
					col = {
						active = {colors = {color._pry3_rgba}, angle = 45},
						inactive = {colors = {color._pry1_rgba}, angle = 45},
						locked_active = {colors = {color._pry2_rgba}, angle = 45},
						locked_inactive = {colors = {color._pry4_rgba}, angle = 45}
					},
					text_color = "rgba(" .. color._txt3 .. "ee)",
					text_color_inactive = "rgba(" .. color._txt1 .. "ee)"
				},
				col = {
					border_active = {colors = {color._pry4_rgba, color._pry2_rgba}, angle = 45},
					border_inactive = {colors = {color._pry1_rgba, color._pry3_rgba}, angle = 45},
					border_locked_active = {colors = {color._txt3_rgba, color._txt4_rgba}, angle = 45},
					border_locked_inactive = {colors = {color._txt1_rgba, color._txt2_rgba}, angle = 45}
				}
			}
		}
	)
end
-- Handle kb soon
-- # HyDE Preparation
-- $exec.mkdir = mkdir -p $XDG_RUNTIME_DIR/hyde $XDG_CACHE_HOME/hyde/wallbash $XDG_CONFIG_HOME/hyde $XDG_DATA_HOME/hyde $(dirname $XDG_DATA_HOME)/state/hyde # Create HyDE directories
-- # $set.env = printf "\n_SHELL='$SHELL'\n_GDK_BACKEND='$GDK_BACKEND'\n_QT_QPA_PLATFORM='$QT_QPA_PLATFORM'\n_SDL_VIDEODRIVER='$SDL_VIDEODRIVER'\n_CLUTTER_BACKEND='$CLUTTER_BACKEND'\n_XDG_CURRENT_DESKTOP='$XDG_CURRENT_DESKTOP'\n_XDG_SESSION_TYPE='$XDG_SESSION_TYPE'\n_XDG_SESSION_DESKTOP='$XDG_SESSION_DESKTOP'\n_QT_AUTO_SCREEN_SCALE_FACTOR='$QT_AUTO_SCREEN_SCALE_FACTOR'\n_QT_WAYLAND_DISABLE_WINDOWDECORATION='$QT_WAYLAND_DISABLE_WINDOWDECORATION'\n_QT_QPA_PLATFORMTHEME='$QT_QPA_PLATFORMTHEME'\n_HYDE_PATH='$hyde.PATH'\n_MOZ_ENABLE_WAYLAND='$MOZ_ENABLE_WAYLAND'\n_GDK_SCALE='$GDK_SCALE'\n_ELECTRON_OZONE_PLATFORM_HINT='$ELECTRON_OZONE_PLATFORM_HINT'\n_XDG_RUNTIME_DIR='$XDG_RUNTIME_DIR'\n_XDG_CONFIG_HOME='$XDG_CONFIG_HOME'\n_XDG_CACHE_HOME='$XDG_CACHE_HOME'\n_XDG_DATA_HOME='$XDG_DATA_HOME'\n_GTK_THEME='$GTK_THEME'\n_ICON_THEME='$ICON_THEME'\n_COLOR_SCHEME='$COLOR_SCHEME'\n_CURSOR_SIZE='$CURSOR_SIZE'\n_CURSOR_THEME='$CURSOR_THEME'\n_FONT='$FONT'\n_FONT_SIZE='$FONT_SIZE'\n_DOCUMENT_FONT='$DOCUMENT_FONT'\n_DOCUMENT_FONT_SIZE='$DOCUMENT_FONT_SIZE'\n_MONOSPACE_FONT='$MONOSPACE_FONT'\n_MONOSPACE_FONT_SIZE='$MONOSPACE_FONT_SIZE'\n_FONT_ANTIALIASING='$FONT_ANTIALIASING'\n_FONT_HINTING='$FONT_HINTING'\n_HYDE_RUNTIME_DIR='$XDG_RUNTIME_DIR/hyde'\n_HYDE_CONFIG_HOME='$XDG_CONFIG_HOME/hyde'\n_HYDE_CACHE_HOME='$XDG_CACHE_HOME/hyde'\n_HYDE_DATA_HOME='$XDG_DATA_HOME/hyde'\n_HYDE_STATE_HOME='$(dirname $XDG_DATA_HOME)/state/hyde'\nexport _TERMINAL='$(which $TERMINAL)'\nexport _LOCKSCREEN='$LOCKSCREEN'" > "$XDG_RUNTIME_DIR/hyde/environment"

-- # Execute on reload
-- exec = $exec.mkdir & $exec.keybinds_hint
hl.exec_cmd(hyde.sh.keybinds_hint("--reload")) -- Regenerate keybinds hint on reload

hl.exec_cmd("hyprctl setcursor " .. hyde.config.ui.cursor_theme .. " " .. hyde.config.ui.cursor_size) -- Reset cursor

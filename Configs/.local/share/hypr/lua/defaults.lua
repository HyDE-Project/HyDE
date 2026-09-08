-- // █▀▄▀█ █▀█ █▄░█ █ ▀█▀ █▀█ █▀█
-- // █░▀░█ █▄█ █░▀█ █ ░█░ █▄█ █▀▄

-- See https://wiki.hypr.land/Configuring/Monitors/

-- monitor = ,preferred,auto,auto

-- // █▀ █▀█ █▀▀ █▀▀ █ ▄▀█ █░░
-- // ▄█ █▀▀ ██▄ █▄▄ █ █▀█ █▄▄

-- decoration {
--     dim_special = 0.3
--     active_opacity = 0.90
--     inactive_opacity = 0.75
--     fullscreen_opacity = 1
--     blur {
--         special = true
--     }
-- }

hl.config({
	decoration = {
		dim_special = 0.3,
		active_opacity = 0.90,
		inactive_opacity = 0.75,
		fullscreen_opacity = 1,
		blur = {
			special = true,
		},
	},
	input = {
		accel_profile = "flat",
		numlock_by_default = true,
	},
	dwindle = {
		preserve_split = true,
	},
	master = {
		new_status = "master",
	},
	misc = {
		vrr = 0,
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		force_default_wallpaper = 0,
		anr_missed_pings = 5,
		allow_session_lock_restore = true,
	},
	xwayland = {
		force_zero_scaling = true,
	},
	general = {
		snap = {
			enabled = true,
			respect_gaps = true,
			-- window_gap/monitor_gap deliberately not set here: they're a
			-- minimum-pixel proximity threshold, and a fixed pixel count
			-- doesn't scale across HiDPI monitors. HyDE shipping its own
			-- copy of Hyprland's default (previously 1, then 10) also
			-- silently drifts if Hyprland ever changes that default.
			-- Leaving these keys out entirely means Hyprland's own
			-- built-in default applies, un-owned by HyDE (#1917).
		},
	},
})

-- // ▄▀█ █▄░█ █ █▀▄▀█ ▄▀█ ▀█▀ █ █▀█ █▄░█
-- // █▀█ █░▀█ █ █░▀░█ █▀█ ░█░ █ █▄█ █░▀█

-- See https://wiki.hypr.land/Configuring/Animations/

-- Animations (Hyprland 0.55+ Lua API)
-- Disable this and let the default animations run
-- hl.curve("wind",   { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
-- hl.curve("winIn",  { type = "bezier", points = { {0.1, 1.1}, {0.1, 1.1} } })
-- hl.curve("winOut", { type = "bezier", points = { {0.3, -0.3}, {0, 1} } })
-- hl.curve("liner",  { type = "bezier", points = { {1, 1}, {1, 1} } })

-- hl.animation({ leaf = "windows",       enabled = true, speed = 6, bezier = "wind",   style = "slide" })
-- hl.animation({ leaf = "windowsIn",     enabled = true, speed = 6, bezier = "winIn",  style = "slide" })
-- hl.animation({ leaf = "windowsOut",    enabled = true, speed = 5, bezier = "winOut", style = "slide" })
-- hl.animation({ leaf = "windowsMove",   enabled = true, speed = 5, bezier = "wind",   style = "slide" })
-- hl.animation({ leaf = "border",        enabled = true, speed = 1, bezier = "liner" })
-- hl.animation({ leaf = "borderangle",   enabled = true, speed = 30, bezier = "liner", style = "once" })
-- hl.animation({ leaf = "fade",          enabled = true, speed = 10, bezier = "default" })
-- hl.animation({ leaf = "workspaces",    enabled = true, speed = 5, bezier = "wind" })
-- hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 8,    bezier = "default", style = "slide" })
-- hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 8,    bezier = "default", style = "slidevert" })
-- hl.animation({ leaf = "specialWorkspace",    enabled = true,  speed = 8,    bezier = "default", style = "slide" })
-- hl.animation({ leaf = "specialWorkspaceIn",  enabled = true,  speed = 8,    bezier = "default", style = "slide" })
-- hl.animation({ leaf = "specialWorkspaceOut", enabled = true,  speed = 8,    bezier = "default", style = "slide" })
-- hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "default" })
-- hl.animation({ leaf = "monitorAdded",  enabled = true,  speed = 7,    bezier = "default" })

-- You can further customize curves with hl.curve if desired
-- hl.curve("myepiccurve", { type = "bezier", points = { {0.5, 0.9}, {0.1, 1.1} } })

-- // █ █▄░█ █▀█ █░█ ▀█▀
-- // █ █░▀█ █▀▀ █▄█ ░█░

-- input {
--     See https://wiki.hypr.land/Configuring/Variables/#input
--     accel_profile = flat
--     numlock_by_default = true
-- }

-- #See https://wiki.hypr.land/Configuring/Gestures/
-- gesture = 3, horizontal, workspace
-- gesture = 3, pinchin,float,tile
-- gesture = 3, pinchout,float, float

-- // █░░ ▄▀█ █▄█ █▀█ █░█ ▀█▀ █▀
-- // █▄▄ █▀█ ░█░ █▄█ █▄█ ░█░ ▄█

-- See https://wiki.hypr.land/Configuring/Dwindle-Layout/

-- dwindle {
--     pseudotile = yes
--     preserve_split = yes
-- }

-- See https://wiki.hypr.land/Configuring/Master-Layout/

-- master {
--     new_status = master
-- }

-- // █▀▄▀█ █ █▀ █▀▀
-- // █░▀░█ █ ▄█ █▄▄

-- See https://wiki.hypr.land/Configuring/Variables/#misc

-- misc {
--     vrr = 0
--     disable_hyprland_logo = true
--     disable_splash_rendering = true
--     force_default_wallpaper = 0
--     anr_missed_pings = 5
--     allow_session_lock_restore = true
-- }

-- xwayland {
--     force_zero_scaling = true
-- }

-- general {
--     snap { snapping for floating windows
--         enabled = true
--     }
-- }

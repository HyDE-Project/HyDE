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

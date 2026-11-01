local floating_window_boundary = function(win)
	-- HyDE's helper to limit the window size when floating, based on the monitor's usable area.
	-- This prevents windows from opening larger than the screen, eg annoying  dolphin window
	if not win or not win.floating then
		return
	end

	if hyde.handle and hyde.handle.float_size_bounds then
		hyde.handle.float_size_bounds(win)
	end
end

-- spawns floating windows
local floating_window_follow_cursor = function(win)
	if hyde.handle and hyde.handle.float_follow_cursor then
		hyde.handle.float_follow_cursor(win)
	end
end

-- turns the laptop screen back on once the last external monitor is unplugged
local no_screen_left = function()
	if hyde.handle and hyde.handle.no_screen_left then
		hyde.handle.no_screen_left()
	end
end

-- applies the saved layout again once an external monitor is plugged in
local screen_plugged = function()
	if hyde.handle and hyde.handle.screen_plugged then
		hyde.handle.screen_plugged()
	end
end

local exit_handler = function()
	hl.dispatch(hl.dsp.exec_cmd("uwsm stop"))
	hl.dispatch(hl.dsp.exec_cmd("hyprshutdown"))
end

hl.on("window.open", floating_window_boundary)
-- hl.on("window.update_rules", floating_window_boundary)
hl.on("hyprland.shutdown", exit_handler)
-- after a pause: the removed output has gone, and an HDMI monitor that drops out
-- for a moment while it changes mode is back before the check
hl.on("monitor.removed", function()
	hl.timer(no_screen_left, {timeout = 1000, type = "oneshot"})
end)
-- 2s: a monitor that is just plugged in can drop out once while it changes mode,
-- and turning the laptop screen off then would leave no screen at all
hl.on("monitor.added", function()
	hl.timer(screen_plugged, {timeout = 2000, type = "oneshot"})
end)

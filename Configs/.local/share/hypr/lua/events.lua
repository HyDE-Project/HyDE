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

local exit_handler = function()
	hl.dispatch(hl.dsp.exec_cmd("uwsm stop"))
	hl.dispatch(hl.dsp.exec_cmd("hyprshutdown"))
end

hl.on("window.open", floating_window_boundary)
-- hl.on("window.update_rules", floating_window_boundary)
hl.on("hyprland.shutdown", exit_handler)

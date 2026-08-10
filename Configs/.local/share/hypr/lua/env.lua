hyde = hyde or {}
hyde.env.finalize()
hl.env("PATH", (hyde.env("PATH") or "") .. ":" .. hyde.path.lib)
-- ? Isolate dconf
hl.env("DCONF_PROFILE",  ((os.getenv("XDG_CONFIG_HOME") ~= "" and os.getenv("XDG_CONFIG_HOME")) or (os.getenv("HOME") or "" ) .. "/.config") .. "/dconf/profile/hyde_hyprland")

-- NVIDIA hook
-- https://wiki.hypr.land/Nvidia/
-- This is only a bare minimum to get NVIDIA working.
-- User may need to add specific variables for their
-- setup in ~/.config/hypr/hyprland.lua
-- The probe reads two files and never leaves the process. It used to run
-- nvidia-smi, which is what took whole sessions down: Hyprland gives the
-- entire configuration 1500 ms and its watchdog counts VM instructions, so it
-- cannot interrupt a blocked C call. A laptop that has to wake a sleeping
-- discrete GPU to answer spends the budget here, and every module loaded after
-- this one dies with a timeout reported somewhere unrelated.
local function has_nvidia_working()
	local version = io.open("/proc/driver/nvidia/version", "r")
	if not version then
		return false
	end
	version:close()

	-- The module registers /proc as it comes up, so a driver that is still
	-- loading or on its way out is ruled out by its recorded state.
	local initstate = io.open("/sys/module/nvidia/initstate", "r")
	if not initstate then
		return true
	end

	local state = initstate:read("*l")
	initstate:close()

	return state == "live"
end
if has_nvidia_working() then
	hl.env("LIBVA_DRIVER_NAME", "nvidia")
	hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
	hl.env("GBM_BACKEND", "nvidia-drm")
end

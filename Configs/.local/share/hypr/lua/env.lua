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
local function has_nvidia_working()
	local f = io.open("/proc/driver/nvidia/version", "r")
	if not f then
		return false
	end
	f:close()
	local ok, _, code = os.execute("nvidia-smi >/dev/null 2>&1")
	return ok == true or code == 0
end
if has_nvidia_working() then
	hl.env("LIBVA_DRIVER_NAME", "nvidia")
	hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
	hl.env("GBM_BACKEND", "nvidia-drm")
end

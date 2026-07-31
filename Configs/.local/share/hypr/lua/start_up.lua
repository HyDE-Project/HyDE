local hs = hyde.config.start or {}

local function check_exec(cmd)
	if type(cmd) == "string" and cmd ~= "" then
		hl.exec_cmd(cmd)
	end
end

hl.on(
	"hyprland.start",
	function()
		check_exec(hs.dbus_share_picker)
		check_exec(hs.systemd_share_picker)
		check_exec("uwsm finalize") -- * optional
		check_exec(hs.wallpaper)
		check_exec(hs.bar)
		check_exec(hs.blue_light_filter_daemon)
		check_exec(hs.notifications)
		check_exec(hs.auth_dialogue)
		check_exec("hyprctl setcursor " .. hyde.config.ui.cursor_theme .. " " .. hyde.config.ui.cursor_size)
		check_exec(hs.text_clipboard)
		check_exec(hs.image_clipboard)
		check_exec(hs.clipboard_persist)
		check_exec(hs.idle_daemon)
		check_exec(hs.battery_notify)
		check_exec(hs.applet_network_manager)
		check_exec(hs.applet_removable_media)
		check_exec(hs.applet_bluetooth)
		check_exec(hs.hyde_config)
	end
)

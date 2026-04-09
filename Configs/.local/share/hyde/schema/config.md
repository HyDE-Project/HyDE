---
HyDE exposes `xdg_config/hyde/config.toml` file for users to modify. This lets users have the ability to interact the scripts without using command arguments.

Users are encouraged to use an editor that support schema validation to ensure the configuration file is valid.
```toml
"$schema" = "https://raw.githubusercontent.com/HyDE-Project/HyDE/refs/heads/master/Configs/.local/share/hyde/schema/config.toml.json"
```
---
### [battery.notify]

batterynotify.sh configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| dock | Dock status for battery notifications. | true |
| interval | Interval for battery notifications. | 5 |
| notify | Notification threshold. | 1140 |
| timer | Timer for battery notifications. | 120 |

### [battery.notify.execute]

Commands to execute for battery notifications.

| Key | Description | Default |
| --- | ----------- | ------- |
| charging | Command to execute when charging. |  |
| critical | Command to execute when battery is critical. | systemctl suspend |
| discharging | Command to execute when discharging. |  |
| low | Command to execute when battery is low. |  |
| unplug | Command to execute when unplugged. |  |

### [battery.notify.threshold]

Thresholds for battery notifications.

| Key | Description | Default |
| --- | ----------- | ------- |
| critical | Critical battery threshold. | 10 |
| full | Full battery threshold. | 90 |
| low | Low battery threshold. | 20 |
| unplug | Unplug battery threshold. | 100 |

### [brightness]

brightnesscontrol.sh configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| notify | Enable notifications for brightness control. | true |
| steps | Number of steps to increase/decrease brightness. | 5 |

### [cava]

Cava visualizer configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| channels | Audio channels: stereo or mono. | stereo |
| range | Bar sensitivity | 8 |
| reverse | Reverse spectrum movement (0 or 1). | 1 |

### [cava.hyprlock]

'cava.sh hyprlock' configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| bar | Bar characters for cava. | ▁▂▃▄▅▆▇█ |
| bar_array | Bar array for hyprlock preset. | ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"] |
| range | Number of bars minus one. | 7 |
| standby | Standby character for cava. | 🎶 |
| width | Width of the cava output. | 20 |

### [cava.stdout]

'cava.sh stdout' configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| bar | Bar characters for cava. | ▁▂▃▄▅▆▇█ |
| bar_array | Bar array for stdout preset. | ["░", "▒", "▓", "█"] |
| range | Number of bars minus one. | 7 |
| standby | Standby character for cava. | 🎶 |
| width | Width of the cava output. | 20 |

### [cava.waybar]

'cava.sh waybar' configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| bar | Bar characters for cava. | ▁▂▃▄▅▆▇█ |
| bar_array | Bar array for waybar preset. | ["◜", "◝", "◞", "◟", "◠", "◡", "◢", "◣"] |
| range | Number of bars minus one. | 7 |
| standby | Standby character for cava. | 🎶 |
| width | Width of the cava output. | 20 |

### [desktop]

Generic desktop/compositor configuration. Compositor-agnostic counterpart to [hyprland]; use this for cross-compositor support (Hyprland, Sway, niri, etc.).

| Key | Description | Default |
| --- | ----------- | ------- |
| background_path | Lockscreen background path. |  |
| bar | Status bar. | waybar |
| browser | Default browser. | firefox |
| button_layout | Button layout. (gtk only) |  |
| color_scheme | Color scheme. | prefer-dark |
| cursor_size | Cursor size. | 24 |
| cursor_theme | Cursor theme. | Bibata-Modern-Ice |
| document_font_size | Document font size. | 10 |
| editor | Default editor. | code |
| explorer | Default file manager. | dolphin |
| font | Default font. | Canterell |
| font_antialiasing | Font antialiasing. | rgba |
| font_hinting | Font hinting. | full |
| font_size | Font size. | 10 |
| gtk_theme | GTK theme. | Wallbash-Gtk |
| icon_theme | Icon theme. | Tela-circle-dracula |
| lockscreen | Lockscreen command. | lockscreen.sh |
| monospace_font | Monospace font. | CaskaydiaCove Nerd Font Mono |
| monospace_font_size | Monospace font size. | 9 |
| quickapps | Quick apps command. | kitty |
| terminal | Default terminal. | kitty |

### [desktop.start]

Generic desktop autostart configuration. Compositor-agnostic counterpart to [hyprland-start]; use this for cross-compositor support (Hyprland, Sway, niri, etc.).

| Key | Description | Default |
| --- | ----------- | ------- |
| applet_bluetooth | Bluetooth applet. | hyde-shell app -u hyde-$XDG_SESSION_DESKTOP-bluetooth-applet.service -t service -- blueman-applet |
| applet_network_manager | Network manager applet. | hyde-shell app -u hyde-$XDG_SESSION_DESKTOP-network-manager-applet.service -t service -- nm-applet --indicator |
| applet_removable_media | Removable media applet. | hyde-shell app -u hyde-$XDG_SESSION_DESKTOP-removable-media-applet.service -t service -- udiskie --no-automount --smart-tray |
| auth_dialogue | Authentication dialogue. | hyde-shell app -t service -- polkitkdeauth.sh |
| bar | Bar. | hyde-shell app -u hyde-$XDG_SESSION_DESKTOP-bar.scope -t scope -- waybar.py --watch |
| battery_notify | Battery notification script. | hyde-shell app -u hyde-$XDG_SESSION_DESKTOP-battery-notify.service -t service -- batterynotify.sh |
| blue_light_filter_daemon | Blue-light filter daemon. | hyde-shell app -u hyde-$XDG_SESSION_DESKTOP-blue-light-filter.service -t service -- hyprsunset |
| clipboard_persist | Clipboard persist daemon. | hyde-shell app -u hyde-$XDG_SESSION_DESKTOP-clipboard-persist.service -t service wl-clip-persist --clipboard regular |
| dbus_share_picker | DBus share picker (for XDG portal / XDPH). | dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP XDG_CONFIG_HOME QT_QPA_PLATFORMTHEME |
| idle_daemon | Idle daemon. | hyde-shell app -u hyde-$XDG_SESSION_DESKTOP-idle.service -t service -- hypridle |
| image_clipboard | Image clipboard daemon. | hyde-shell app -u hyde-$XDG_SESSION_DESKTOP-image-clipboard.service -t service wl-paste --type image --watch cliphist store |
| notifications | Notification daemon. | hyde-shell app -u hyde-$XDG_SESSION_DESKTOP-notifications.service -t service -- dunst |
| systemd_share_picker | Systemd share picker (for XDG portal / XDPH). | systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP XDG_CONFIG_HOME QT_QPA_PLATFORMTHEME |
| text_clipboard | Text clipboard daemon. | hyde-shell app -u hyde-$XDG_SESSION_DESKTOP-text-clipboard.service -t service wl-paste --type text --watch cliphist store |
| wallpaper | Wallpaper script. | hyde-shell app -u hyde-$XDG_SESSION_DESKTOP-wallpaper.service -t service -- wallpaper.sh --start --global |
| xdg_portal_reset | XDG portal reset script. | hyde-shell resetxdgportal.sh |

### [gtk3]

GTK3 configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| font | GTK3 font. | Canterell |
| font_size | GTK3 font size. | 10 |

### [hyprland]

Hyprland configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| background_path | LockScreen's Background path. |  |
| bar | Bar. | waybar |
| blue_light_filter | Blue-light filter. | hyprsunset |
| browser | Browser. | firefox |
| button_layout | Button layout. (gtk only) |  |
| color_scheme | Color scheme. | prefer-dark |
| cursor_size | Cursor size. | 24 |
| cursor_theme | Cursor theme. | Bibata-Modern-Ice |
| document_font_size | Document font size. | 10 |
| editor | Editor. | code |
| explorer | File manager. | dolphin |
| font | Font. | Canterell |
| font_antialiasing | Font antialiasing. | rgba |
| font_hinting | Font hinting. | full |
| font_size | Font size. | 10 |
| gtk_theme | GTK theme. | Wallbash-Gtk |
| icon_theme | Icon theme. | Tela-circle-dracula |
| lockscreen | Lockscreen. | lockscreen.sh |
| monospace_font | Monospace font. | CaskaydiaCove Nerd Font Mono |
| monospace_font_size | Monospace font size. | 9 |
| quickapps | Quick apps. | kitty |
| terminal | Terminal. | kitty |

### [hyprland-start]

Hyprland start configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| applet_bluetooth | Bluetooth applet. | hyde-shell app -u hyde-$XDG_SESSION_DESKTOP-bluetooth-applet.service -t service -- blueman-applet |
| applet_network_manager | Network manager. | hyde-shell app -u hyde-$XDG_SESSION_DESKTOP-network-manager-applet.service -t service -- nm-applet --indicator |
| applet_removable_media | Removable media manager. | hyde-shell app -u hyde-$XDG_SESSION_DESKTOP-removable-media-applet.service -t service -- udiskie --no-automount --smart-tray |
| auth_dialogue | Authentication dialogue. | hyde-shell app -t service -- polkitkdeauth.sh |
| bar | Bar. | hyde-shell app -u hyde-$XDG_SESSION_DESKTOP-bar.scope -t scope -- waybar.py --watch |
| battery_notify | Battery notification script. | hyde-shell app -u hyde-$XDG_SESSION_DESKTOP-battery-notify.service -t service -- batterynotify.sh |
| blue_light_filter_daemon | Blue-light filter daemon. | hyde-shell app -u hyde-$XDG_SESSION_DESKTOP-blue-light-filter.service -t service -- hyprsunset |
| clipboard_persist | Clipboard persist daemon. | hyde-shell app -u hyde-$XDG_SESSION_DESKTOP-clipboard-persist.service -t service wl-clip-persist --clipboard regular |
| dbus_share_picker | DBus share picker. | dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP XDG_CONFIG_HOME QT_QPA_PLATFORMTHEME |
| idle_daemon | Idle daemon. | hyde-shell app -u hyde-$XDG_SESSION_DESKTOP-idle.service -t service -- hypridle |
| image_clipboard | Image clipboard. | hyde-shell app -u hyde-$XDG_SESSION_DESKTOP-image-clipboard.service -t service wl-paste --type image --watch cliphist store |
| notifications | Notifications. | hyde-shell app -u hyde-$XDG_SESSION_DESKTOP-notifications.service -t service -- dunst |
| systemd_share_picker | Systemd share picker. | systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP XDG_CONFIG_HOME QT_QPA_PLATFORMTHEME |
| text_clipboard | Text clipboard. | hyde-shell app -u hyde-$XDG_SESSION_DESKTOP-text-clipboard.service -t service wl-paste --type text --watch cliphist store |
| wallpaper | Wallpaper script. | hyde-shell app -u hyde-$XDG_SESSION_DESKTOP-wallpaper.service -t service -- wallpaper.sh --start --global |
| xdg_portal_reset | XDG portal reset script. | hyde-shell resetxdgportal.sh |

### [hyprlock]

hyprlock configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| fail_timeout | Milliseconds until the UI resets after a failed auth attempt. | 2000 |
| fractional_scaling | Whether to use fractional scaling. 0: disabled, 1: enabled, 2: auto. | 2 |
| hide_cursor | Hides the cursor instead of making it visible. | false |
| ignore_empty_input | Skips validation when no password is provided. | false |
| immediate_render | Makes hyprlock immediately start to draw widgets. | false |
| screencopy_mode | Selects screencopy mode: 0 gpu accelerated, 1 cpu based (slow). | 0 |
| text_trim | Sets if the text should be trimmed, useful to avoid trailing newline in commands output. | true |

### [mediaplayer]

mediaplayer.py configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| artist_track_separator | Separator symbols to display between artist and track. |    |
| max_length | Max length of song and artist string. | 70 |
| prefix_paused | Prefix for paused media. |    |
| prefix_playing | Prefix for playing media. |  |
| standby_text | To display on standby. |   Music |

### [notification]

Notification script configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| font | Font for notifications. | mononoki Nerd Font |
| font_size | Font size for notifications. | 10 |

### [qt5]

Qt5 configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| font | Qt5 font. | Canterell |
| font_size | Qt5 font size. | 10 |
| monospace_font | Qt5 monospace font. | CaskaydiaCove Nerd Font Mono |
| monospace_font_size | Qt5 monospace font size. | 9 |

### [qt6]

Qt6 configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| font | Qt6 font. | Canterell |
| font_size | Qt6 font size. | 10 |
| monospace_font | Qt6 monospace font. | CaskaydiaCove Nerd Font Mono |
| monospace_font_size | Qt6 monospace font size. | 9 |

### [rofi]

Global rofi configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| scale | Rofi default scaling. | 10 |

### [rofi.animation]

'animation.sh select' configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| scale | Scaling for animation. | 10 |

### [rofi.bookmarks]

hyde-shell rofi.bookmarks.sh configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| args | Additional arguments for bookmarks. | [] |
| font | Font for bookmarks. | JetBrainsMono Nerd Font |
| scale | Scaling for bookmarks. | 10 |
| style | Style for rofi bookmarks. |  |

### [rofi.cliphist]

cliphist.sh configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| scale | Scaling for cliphist. | 10 |

### [rofi.emoji]

emoji-picker.sh configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| args | Additional arguments for emoji picker. | ["-multi-select"] |
| scale | Scaling for emoji picker. | 10 |
| style | Style for emoji picker. | 1 |

### [rofi.glyph]

glyph-picker.sh configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| args | Additional arguments for glyph picker. | ["-multi-select"] |
| scale | Scaling for glyph picker. | 10 |

### [rofi.hyprlock]

'hyde-shell hyprlock select' configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| scale | Scaling for hyprlock. | 10 |

### [rofi.launch]

rofilaunch.sh configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| drun_args | Additional arguments for drun mode. | [] |
| drun_style | Style for drun mode. | style_1 |
| filebrowser_args | Additional arguments for filebrowser mode. | [] |
| filebrowser_style | Style for filebrowser mode. | style_1 |
| run_args | Additional arguments for run mode. | [] |
| run_style | Style for run mode. | style_1 |
| scale | Scaling for launch. | 5 |
| window_args | Additional arguments for window mode. | [] |
| window_style | Style for window mode. | style_1 |

### [rofi.theme]

themeselect.sh configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| column_count | Number of columns for theme selector. | 3 |
| scale | Scaling for theme selector. | 6 |

### [rofi.wallpaper]

wallpaper select configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| column_count | Number of columns for wallpaper selector. | 3 |
| scale | Scaling for wallpaper. | 10 |

### [rofi.websearch]

hyde-shell rofi.websearch.sh configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| args | Additional arguments for websearch. | [] |
| font | Font for websearch. | JetBrainsMono Nerd Font |
| scale | Scaling for websearch. | 10 |
| style | Style for rofi websearch. |  |

### [rofi.keybind.hint]

keybind_hint.sh configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| delimiter | Delimiter for keybind hints. | 	 |
| height | Height for keybind hints. | 40em |
| line | Number of lines for keybind hints. | 16 |
| width | Width for keybind hints. | 40em |

### [screenshot]

screenshot.sh configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| annotation_enabled | Enable or disable annotation feature. | true |
| annotation_post_command | Post command for annotation tool. | [""] |
| annotation_pre_command | Pre command for annotation tool. | [] |
| annotation_tool | Annotation tool for screenshots. | satty |

### [screenshot.ocr]

OCR configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| tesseract_languages | Place desired languages to use for text recognition. To see installed languages run `tesseract --list-langs`. | ["eng"] |

### [sysmonitor]

sysmonlaunch.sh configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| commands | Fallback command options. | [""] |
| execute | Default command to execute. |  |

### [volume]

volumecontrol.sh configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| boost | Enable volume boost. | false |
| boost_limit | Volume boost limit. | 120 |
| notify | Enable notifications for volume control. | true |
| steps | Number of steps to increase/decrease volume. | 5 |

### [wallbash]

wallbash configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| skip_template | Templates to skip when using wallbash. | [""] |

### [wallpaper]

Wallpaper configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| backend | Wallpaper backend, requires 'wallpaper.<backend>.sh' as handler script in $PATH | awww |
| custom_paths | List of paths to search for wallpapers. | [] |

### [wallpaper.awww]

wallpaper select configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| duration | Transition duration. | 1 |
| framerate | Transition framerate. | 60 |
| transition_default | Transition type for default wallpaper. | grow |
| transition_next | Transition type for next wallpaper. | grow |
| transition_prev | Transition type for previous wallpaper. | outer |

### [wallpaper.waydeeper]

waydeeper 3D parallax wallpaper configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| active_delay | Delay (ms) before animation starts after mouse enters wallpaper surface. | 150 |
| animation_speed | Animation speed multiplier. | 0.05 |
| fps | Frame rate (30 or 60). | 60 |
| idle_timeout | Stops animation (ms) after mouse idle. | 5000 |
| invert_depth | Inverts depth interpretation. | false |
| model | ONNX depth model: depth-anything-v3-base, midas-small, depth-pro-q4. | depth-anything-v3-base |
| regenerate | Forces regeneration of depth maps & meshes. | false |
| smooth_animation | Enables smooth easing for animation. | true |
| strength | Sets both X & Y parallax strength. | 0.02 |
| strength_x | X-axis parallax strength. | 0.02 |
| strength_y | Y-axis parallax strength. | 0.02 |

### [waybar]

waybar configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| font | Font for waybar. | JetBrainsMono Nerd Font |
| icon_size | Icon size for waybar. | 10 |
| position | A fallback position of the waybar.   | top |
| scale | Total scaling for waybar. | 10 |

### [weather]

Weather configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| forecast_days | Number of days to show forecast (0-3). | 3 |
| location | Location/coordinates string for the weather output. |  |
| show_icon | Show the weather icon in waybar. | true |
| show_location | Show the location in waybar. | true |
| show_today | Show detailed description of today in tooltip. | true |
| temperature_unit | Temperature unit ('c' or 'f'). | c |
| time_format | Time format ('12h' or '24h'). | 24h |
| windspeed_unit | Windspeed unit ('km/h' or 'mph'). | km/h |

### [wlogout]

wlogout configuration.

| Key | Description | Default |
| --- | ----------- | ------- |
| style | Style for wlogout. | 2 |


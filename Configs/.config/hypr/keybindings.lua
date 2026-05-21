--[[
    █▄▀ █▀▀ █▄█ █▄▄ █ █▄░█ █▀▄ █ █▄░█ █▀▀ █▀
    █░█ ██▄ ░█░ █▄█ █ █░▀█ █▄▀ █ █░▀█ █▄█ ▄█

    Keybindings
    https://wiki.hypr.land/Configuring/Binds/

    Keyboard shortcuts for DOORwayDE.
    The [Group|Subgroup] comments preserve the original grouping system
    for use by keybinds hint and other GUI tools.
--]]

--------------------------------------------------------------------------------
-- Variables
-- App defaults read from environment; fall back to sensible values
--------------------------------------------------------------------------------

local mainMod = "SUPER"
local terminal = os.getenv("TERMINAL") or "kitty"
local editor   = os.getenv("EDITOR")   or "code"
local explorer = os.getenv("EXPLORER") or "dolphin"
local browser  = os.getenv("BROWSER")  or "firefox"
local killactive = 'hyprctl dispatch killactive ""'
local rofiLaunch = "doorwayde-shell rofilaunch"

local moveactivewindow = 'grep -q "true" <<< $(hyprctl activewindow -j | jq -r .floating) && hyprctl dispatch moveactive'

--------------------------------------------------------------------------------
-- Window Management
--------------------------------------------------------------------------------

-- [Window Management]
hl.bind(mainMod .. " + Q",       hl.dsp.exec_cmd(killactive),                          { description = "Window Management: close focused window" })
hl.bind("ALT + F4",              hl.dsp.exec_cmd(killactive),                          { description = "Window Management: close focused window" })
hl.bind(mainMod .. " + Delete",  hl.dsp.exec_cmd("doorwayde-shell logout"),            { description = "Window Management: kill hyprland session" })
hl.bind(mainMod .. " + W",       hl.dsp.toggle_floating(),                             { description = "Window Management: toggle floating" })
hl.bind(mainMod .. " + G",       hl.dsp.toggle_group(),                                { description = "Window Management: toggle group" })
hl.bind("SHIFT + F11",           hl.dsp.fullscreen(),                                  { description = "Window Management: toggle fullscreen" })
hl.bind(mainMod .. " + L",       hl.dsp.exec_cmd("doorwayde-shell lock-session"),      { description = "Window Management: lock screen" })
hl.bind(mainMod .. " SHIFT + F", hl.dsp.exec_cmd("doorwayde-shell window.pin"),        { description = "Window Management: toggle pin on focused window" })
hl.bind("CTRL ALT + Delete",     hl.dsp.exec_cmd("doorwayde-shell logoutlaunch"),      { description = "Window Management: logout menu" })
hl.bind("ALT_R + CTRL_R",        hl.dsp.exec_cmd("doorwayde-shell waybar --hide"),     { description = "Window Management: toggle waybar and reload config" })
hl.bind(mainMod .. " + F5",      hl.dsp.exec_cmd("hyprctl reload"),                    { description = "Window Management: reload Hyprland config" })

-- [Window Management|Group Navigation]
hl.bind(mainMod .. " CTRL + H", hl.dsp.change_group_active("b"), { description = "Window Management|Group Navigation: change active group backwards" })
hl.bind(mainMod .. " CTRL + L", hl.dsp.change_group_active("f"), { description = "Window Management|Group Navigation: change active group forwards" })

-- [Window Management|Change focus]
hl.bind(mainMod .. " + Left",  hl.dsp.focus({ direction = "l" }), { description = "Window Management|Change focus: focus left" })
hl.bind(mainMod .. " + Right", hl.dsp.focus({ direction = "r" }), { description = "Window Management|Change focus: focus right" })
hl.bind(mainMod .. " + Up",    hl.dsp.focus({ direction = "u" }), { description = "Window Management|Change focus: focus up" })
hl.bind(mainMod .. " + Down",  hl.dsp.focus({ direction = "d" }), { description = "Window Management|Change focus: focus down" })
hl.bind("ALT + Tab", hl.dsp.exec_cmd('hyprctl --batch "dispatch cyclenext ; dispatch alterzorder top"'), { description = "Window Management|Change focus: cycle focus" })

-- [Window Management|Resize Active Window]
hl.bind(mainMod .. " SHIFT + Right", hl.dsp.resize_active({ x =  30, y =   0 }), { description = "Window Management|Resize: resize window right", repeat = true })
hl.bind(mainMod .. " SHIFT + Left",  hl.dsp.resize_active({ x = -30, y =   0 }), { description = "Window Management|Resize: resize window left",  repeat = true })
hl.bind(mainMod .. " SHIFT + Up",    hl.dsp.resize_active({ x =   0, y = -30 }), { description = "Window Management|Resize: resize window up",    repeat = true })
hl.bind(mainMod .. " SHIFT + Down",  hl.dsp.resize_active({ x =   0, y =  30 }), { description = "Window Management|Resize: resize window down",  repeat = true })

-- [Window Management|Move active window across workspace]
hl.bind(mainMod .. " SHIFT CTRL + left",  hl.dsp.exec_cmd(moveactivewindow .. " -30 0 || hyprctl dispatch movewindow l"), { description = "Move active window to the left",  repeat = true })
hl.bind(mainMod .. " SHIFT CTRL + right", hl.dsp.exec_cmd(moveactivewindow .. " 30 0 || hyprctl dispatch movewindow r"),  { description = "Move active window to the right", repeat = true })
hl.bind(mainMod .. " SHIFT CTRL + up",    hl.dsp.exec_cmd(moveactivewindow .. " 0 -30 || hyprctl dispatch movewindow u"), { description = "Move active window up",            repeat = true })
hl.bind(mainMod .. " SHIFT CTRL + down",  hl.dsp.exec_cmd(moveactivewindow .. " 0 30 || hyprctl dispatch movewindow d"),  { description = "Move active window down",          repeat = true })

-- [Window Management|Move & Resize with mouse]
hl.bind(mainMod .. " + mouse:272", hl.dsp.move_window(),   { description = "Window Management: hold to move window",   mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.resize_window(), { description = "Window Management: hold to resize window", mouse = true })
hl.bind(mainMod .. " + Z",         hl.dsp.move_window(),   { description = "Window Management: hold to move window",   mouse = true })
hl.bind(mainMod .. " + X",         hl.dsp.resize_window(), { description = "Window Management: hold to resize window", mouse = true })

-- [Window Management]
hl.bind(mainMod .. " + J", hl.dsp.layout_msg("togglesplit"), { description = "Window Management: toggle split" })

--------------------------------------------------------------------------------
-- Launcher
--------------------------------------------------------------------------------

-- [Launcher|Apps]
hl.bind(mainMod .. " + T",         hl.dsp.exec_cmd(terminal),                               { description = "Launcher|Apps: terminal emulator" })
hl.bind(mainMod .. " ALT + T",     hl.dsp.exec_cmd("doorwayde-shell pypr toggle console"),  { description = "Launcher|Apps: dropdown terminal" })
hl.bind(mainMod .. " + E",         hl.dsp.exec_cmd(explorer),                               { description = "Launcher|Apps: file explorer" })
hl.bind(mainMod .. " + C",         hl.dsp.exec_cmd(editor),                                 { description = "Launcher|Apps: text editor" })
hl.bind(mainMod .. " + B",         hl.dsp.exec_cmd(browser),                                { description = "Launcher|Apps: web browser" })
hl.bind("CTRL SHIFT + Escape",     hl.dsp.exec_cmd("doorwayde-shell system.monitor"),       { description = "Launcher|Apps: system monitor" })

-- [Launcher|Rofi menus]
hl.bind(mainMod .. " + A",       hl.dsp.exec_cmd("pkill -x rofi || " .. rofiLaunch .. " d"),   { description = "Launcher|Rofi: application finder" })
hl.bind(mainMod .. " + TAB",     hl.dsp.exec_cmd("pkill -x rofi || " .. rofiLaunch .. " w"),   { description = "Launcher|Rofi: window switcher" })
hl.bind(mainMod .. " SHIFT + E", hl.dsp.exec_cmd("pkill -x rofi || " .. rofiLaunch .. " f"),   { description = "Launcher|Rofi: file finder" })
hl.bind(mainMod .. " + slash",   hl.dsp.exec_cmd("pkill -x rofi || doorwayde-shell keybinds_hint c"),  { description = "Launcher|Rofi: keybindings hint" })
hl.bind(mainMod .. " + comma",   hl.dsp.exec_cmd("pkill -x rofi || doorwayde-shell emoji-picker"),     { description = "Launcher|Rofi: emoji picker" })
hl.bind(mainMod .. " + period",  hl.dsp.exec_cmd("pkill -x rofi || doorwayde-shell glyph-picker"),     { description = "Launcher|Rofi: glyph picker" })
hl.bind(mainMod .. " + V",       hl.dsp.exec_cmd("pkill -x rofi || doorwayde-shell cliphist -c"),      { description = "Launcher|Rofi: clipboard" })
hl.bind(mainMod .. " SHIFT + V", hl.dsp.exec_cmd("pkill -x rofi || doorwayde-shell cliphist"),         { description = "Launcher|Rofi: clipboard manager" })
hl.bind(mainMod .. " SHIFT + A", hl.dsp.exec_cmd("pkill -x rofi || doorwayde-shell rofiselect"),       { description = "Launcher|Rofi: select rofi launcher" })

--------------------------------------------------------------------------------
-- Hardware Controls
--------------------------------------------------------------------------------

-- [Hardware Controls|Audio]
hl.bind("F10",                   hl.dsp.exec_cmd("doorwayde-shell volumecontrol -o m"), { description = "Hardware Controls|Audio: toggle mute output",  locked = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("doorwayde-shell volumecontrol -o m"), { description = "Hardware Controls|Audio: toggle mute output",  locked = true })
hl.bind("F11",                   hl.dsp.exec_cmd("doorwayde-shell volumecontrol -o d"), { description = "Hardware Controls|Audio: decrease volume",      repeat = true, locked = true })
hl.bind("F12",                   hl.dsp.exec_cmd("doorwayde-shell volumecontrol -o i"), { description = "Hardware Controls|Audio: increase volume",      repeat = true, locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("doorwayde-shell volumecontrol -i m"), { description = "Hardware Controls|Audio: un/mute microphone",  locked = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("doorwayde-shell volumecontrol -o d"), { description = "Hardware Controls|Audio: decrease volume",      repeat = true, locked = true })
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("doorwayde-shell volumecontrol -o i"), { description = "Hardware Controls|Audio: increase volume",      repeat = true, locked = true })

-- [Hardware Controls|Media]
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { description = "Hardware Controls|Media: play media",     locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { description = "Hardware Controls|Media: pause media",    locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { description = "Hardware Controls|Media: next media",     locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { description = "Hardware Controls|Media: previous media", locked = true })
hl.bind(mainMod .. " CTRL + M", hl.dsp.exec_cmd("doorwayde-shell window.mute"), { description = "Hardware Controls|Media: toggle mute for active window" })

-- [Hardware Controls|Brightness]
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("doorwayde-shell brightnesscontrol i"), { description = "Hardware Controls|Brightness: increase brightness", repeat = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("doorwayde-shell brightnesscontrol d"), { description = "Hardware Controls|Brightness: decrease brightness", repeat = true, locked = true })

--------------------------------------------------------------------------------
-- Utilities
--------------------------------------------------------------------------------

-- [Utilities]
hl.bind(mainMod .. " + K",       hl.dsp.exec_cmd("doorwayde-shell keyboardswitch"), { description = "Utilities: toggle keyboard layout", locked = true })
hl.bind(mainMod .. " ALT + G",   hl.dsp.exec_cmd("doorwayde-shell gamemode"),       { description = "Utilities: game mode" })
hl.bind(mainMod .. " SHIFT + G", hl.dsp.exec_cmd("doorwayde-shell gamelauncher"),   { description = "Utilities: open game launcher" })

-- [Utilities|Screen Capture]
hl.bind(mainMod .. " SHIFT + P", hl.dsp.exec_cmd("hyprpicker -an"),                       { description = "Utilities|Screen Capture: color picker" })
hl.bind(mainMod .. " + P",       hl.dsp.exec_cmd("doorwayde-shell screenshot s"),          { description = "Utilities|Screen Capture: snip screen" })
hl.bind(mainMod .. " CTRL + P",  hl.dsp.exec_cmd("doorwayde-shell screenshot sf"),         { description = "Utilities|Screen Capture: freeze and snip screen" })
hl.bind(mainMod .. " ALT + P",   hl.dsp.exec_cmd("doorwayde-shell screenshot m"),          { description = "Utilities|Screen Capture: print monitor",      locked = true })
hl.bind("Print",                  hl.dsp.exec_cmd("doorwayde-shell screenshot p"),          { description = "Utilities|Screen Capture: print all monitors", locked = true })

--------------------------------------------------------------------------------
-- Theming and Wallpaper
--------------------------------------------------------------------------------

-- [Theming and Wallpaper]
hl.bind(mainMod .. " ALT + Right", hl.dsp.exec_cmd("doorwayde-shell wallpaper -Gn"),                        { description = "Theming: next global wallpaper" })
hl.bind(mainMod .. " ALT + Left",  hl.dsp.exec_cmd("doorwayde-shell wallpaper -Gp"),                        { description = "Theming: previous global wallpaper" })
hl.bind(mainMod .. " SHIFT + W",   hl.dsp.exec_cmd("pkill -x rofi || doorwayde-shell wallpaper -SG"),       { description = "Theming: select a global wallpaper" })
hl.bind(mainMod .. " ALT + Up",    hl.dsp.exec_cmd("doorwayde-shell wbarconfgen n"),                        { description = "Theming: next waybar layout" })
hl.bind(mainMod .. " ALT + Down",  hl.dsp.exec_cmd("doorwayde-shell wbarconfgen p"),                        { description = "Theming: previous waybar layout" })
hl.bind(mainMod .. " SHIFT + R",   hl.dsp.exec_cmd("pkill -x rofi || doorwayde-shell wallbashtoggle -m"),   { description = "Theming: wallbash mode selector" })
hl.bind(mainMod .. " SHIFT + T",   hl.dsp.exec_cmd("pkill -x rofi || doorwayde-shell themeselect"),         { description = "Theming: select a theme" })
hl.bind(mainMod .. " SHIFT + Y",   hl.dsp.exec_cmd("pkill -x rofi || doorwayde-shell animations --select"), { description = "Theming: select animations" })
hl.bind(mainMod .. " SHIFT + U",   hl.dsp.exec_cmd("pkill -x rofi || doorwayde-shell hyprlock --select"),   { description = "Theming: select hyprlock layout" })

--------------------------------------------------------------------------------
-- Workspaces
--------------------------------------------------------------------------------

-- [Workspaces|Navigation]
hl.bind(mainMod .. " + 1", hl.dsp.workspace(1),  { description = "Workspaces|Navigation: navigate to workspace 1" })
hl.bind(mainMod .. " + 2", hl.dsp.workspace(2),  { description = "Workspaces|Navigation: navigate to workspace 2" })
hl.bind(mainMod .. " + 3", hl.dsp.workspace(3),  { description = "Workspaces|Navigation: navigate to workspace 3" })
hl.bind(mainMod .. " + 4", hl.dsp.workspace(4),  { description = "Workspaces|Navigation: navigate to workspace 4" })
hl.bind(mainMod .. " + 5", hl.dsp.workspace(5),  { description = "Workspaces|Navigation: navigate to workspace 5" })
hl.bind(mainMod .. " + 6", hl.dsp.workspace(6),  { description = "Workspaces|Navigation: navigate to workspace 6" })
hl.bind(mainMod .. " + 7", hl.dsp.workspace(7),  { description = "Workspaces|Navigation: navigate to workspace 7" })
hl.bind(mainMod .. " + 8", hl.dsp.workspace(8),  { description = "Workspaces|Navigation: navigate to workspace 8" })
hl.bind(mainMod .. " + 9", hl.dsp.workspace(9),  { description = "Workspaces|Navigation: navigate to workspace 9" })
hl.bind(mainMod .. " + 0", hl.dsp.workspace(10), { description = "Workspaces|Navigation: navigate to workspace 10" })

-- [Workspaces|Navigation|Relative workspace]
hl.bind(mainMod .. " CTRL + Right", hl.dsp.workspace("r+1"), { description = "Workspaces|Navigation: change active workspace forwards" })
hl.bind(mainMod .. " CTRL + Left",  hl.dsp.workspace("r-1"), { description = "Workspaces|Navigation: change active workspace backwards" })

-- [Workspaces|Navigation]
hl.bind(mainMod .. " CTRL + Down", hl.dsp.workspace("empty"), { description = "Workspaces|Navigation: navigate to nearest empty workspace" })

-- [Workspaces|Move window to workspace]
hl.bind(mainMod .. " SHIFT + 1", hl.dsp.move_to_workspace(1),  { description = "Workspaces: move to workspace 1" })
hl.bind(mainMod .. " SHIFT + 2", hl.dsp.move_to_workspace(2),  { description = "Workspaces: move to workspace 2" })
hl.bind(mainMod .. " SHIFT + 3", hl.dsp.move_to_workspace(3),  { description = "Workspaces: move to workspace 3" })
hl.bind(mainMod .. " SHIFT + 4", hl.dsp.move_to_workspace(4),  { description = "Workspaces: move to workspace 4" })
hl.bind(mainMod .. " SHIFT + 5", hl.dsp.move_to_workspace(5),  { description = "Workspaces: move to workspace 5" })
hl.bind(mainMod .. " SHIFT + 6", hl.dsp.move_to_workspace(6),  { description = "Workspaces: move to workspace 6" })
hl.bind(mainMod .. " SHIFT + 7", hl.dsp.move_to_workspace(7),  { description = "Workspaces: move to workspace 7" })
hl.bind(mainMod .. " SHIFT + 8", hl.dsp.move_to_workspace(8),  { description = "Workspaces: move to workspace 8" })
hl.bind(mainMod .. " SHIFT + 9", hl.dsp.move_to_workspace(9),  { description = "Workspaces: move to workspace 9" })
hl.bind(mainMod .. " SHIFT + 0", hl.dsp.move_to_workspace(10), { description = "Workspaces: move to workspace 10" })

-- [Workspaces]
hl.bind(mainMod .. " CTRL ALT + Right", hl.dsp.move_to_workspace("r+1"), { description = "Workspaces: move window to next relative workspace" })
hl.bind(mainMod .. " CTRL ALT + Left",  hl.dsp.move_to_workspace("r-1"), { description = "Workspaces: move window to previous relative workspace" })

-- [Workspaces|Navigation]
hl.bind(mainMod .. " + mouse_down", hl.dsp.workspace("e+1"), { description = "Workspaces|Navigation: next workspace" })
hl.bind(mainMod .. " + mouse_up",   hl.dsp.workspace("e-1"), { description = "Workspaces|Navigation: previous workspace" })

-- [Workspaces|Navigation|Special workspace]
hl.bind(mainMod .. " SHIFT + S", hl.dsp.move_to_workspace("special"),                   { description = "Workspaces|Special: move to scratchpad" })
hl.bind(mainMod .. " ALT + S",   hl.dsp.move_to_workspace("special", { silent = true }), { description = "Workspaces|Special: move to scratchpad (silent)" })
hl.bind(mainMod .. " + S",       hl.dsp.toggle_special_workspace(),                      { description = "Workspaces|Special: toggle scratchpad" })

-- [Workspaces|Navigation|Move window silently]
hl.bind(mainMod .. " ALT + 1", hl.dsp.move_to_workspace(1,  { silent = true }), { description = "Workspaces: move to workspace 1 (silent)" })
hl.bind(mainMod .. " ALT + 2", hl.dsp.move_to_workspace(2,  { silent = true }), { description = "Workspaces: move to workspace 2 (silent)" })
hl.bind(mainMod .. " ALT + 3", hl.dsp.move_to_workspace(3,  { silent = true }), { description = "Workspaces: move to workspace 3 (silent)" })
hl.bind(mainMod .. " ALT + 4", hl.dsp.move_to_workspace(4,  { silent = true }), { description = "Workspaces: move to workspace 4 (silent)" })
hl.bind(mainMod .. " ALT + 5", hl.dsp.move_to_workspace(5,  { silent = true }), { description = "Workspaces: move to workspace 5 (silent)" })
hl.bind(mainMod .. " ALT + 6", hl.dsp.move_to_workspace(6,  { silent = true }), { description = "Workspaces: move to workspace 6 (silent)" })
hl.bind(mainMod .. " ALT + 7", hl.dsp.move_to_workspace(7,  { silent = true }), { description = "Workspaces: move to workspace 7 (silent)" })
hl.bind(mainMod .. " ALT + 8", hl.dsp.move_to_workspace(8,  { silent = true }), { description = "Workspaces: move to workspace 8 (silent)" })
hl.bind(mainMod .. " ALT + 9", hl.dsp.move_to_workspace(9,  { silent = true }), { description = "Workspaces: move to workspace 9 (silent)" })
hl.bind(mainMod .. " ALT + 0", hl.dsp.move_to_workspace(10, { silent = true }), { description = "Workspaces: move to workspace 10 (silent)" })

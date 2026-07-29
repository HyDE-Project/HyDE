-- * Enable bind deduplication so repeated key combos don't conflict.
-- * This has to run before the first bind below, otherwise the binds in this
-- * file are registered unchecked and only user overrides get deduplicated.
-- * For multiple dispatcher actions, wrap them in one function and bind that.
-- * If you set `hyde.binds.dedup = false`, unbind duplicates manually.
hyde.binds.dedup = true
-- hyde.binds.dedup_fields = {}

-- vars for easy access
local _apps = hyde.config.app
local MOD = hyde.config.modifiers.main
local _F

-- Functions for some multi bind actions

local cycle_fullscreen = function()
    local active_window = assert(hl.get_active_window(), "No active window to toggle fullscreen")
    local current_state = tonumber(active_window.fullscreen) or 0
    local next_state = (current_state + 1) % 3
    hl.dispatch(
        hl.dsp.window.fullscreen_state(
            {
                internal = next_state,
                client = next_state,
                window = active_window
            }
        )
    )
end

local move_window = function(dir, pix)
    local lut = {l = {-1, 0}, r = {1, 0}, u = {0, -1}, d = {0, 1}}
    lut.left, lut.right, lut.up, lut.down = lut.l, lut.r, lut.u, lut.d
    local m = lut[dir]
    return function()
        local args =
            hl.get_active_window().floating and {x = m[1] * pix, y = m[2] * pix, relative = true} or {direction = dir}
        hl.dispatch(hl.dsp.window.move(args))
    end
end

local togglefloating = function()
    -- TODO unused
    -- $ToggleFloatingMax = hyprctl --batch "dispatch togglefloating; dispatch resizeactive exact 85% 85%; dispatch centerwindow"
    hl.dsp.window.float({action = "toggle"})()
    hl.dsp.window.resize({width = "85%", height = "85%"})()
    hl.dsp.window.center()()
end

_F = {description = "[Launcher|Apps] terminal emulator"}
hl.bind(MOD .. " + T", hl.dsp.exec_cmd(_apps.terminal), _F)
_F = {description = "[Launcher|Apps] dropdown terminal"}
hl.bind(MOD .. " + ALT + T", hl.dsp.exec_cmd("hyde-shell pypr toggle console"), _F)
_F = {description = "[Launcher|Apps] file explorer"}
hl.bind(MOD .. " + E", hl.dsp.exec_cmd(_apps.explorer), _F)
_F = {description = "[Launcher|Apps] browser"}
hl.bind(MOD .. " + B", hl.dsp.exec_cmd(_apps.browser), _F)
_F = {description = "[Launcher|Apps] text editor"}
hl.bind(MOD .. " + C", hl.dsp.exec_cmd(_apps.editor), _F)
_F = {description = "[Launcher|Apps] system monitor"}
hl.bind("CTRL + SHIFT + ESCAPE", hl.dsp.exec_cmd("hyde-shell system.monitor.sh"), _F)

local _wm = "Window Management"
_F = {description = "[Window Management] close focused window"}
hl.bind(MOD .. " + Q", hl.dsp.window.close(), _F)
_F = {description = "[Window Management] close focused window"}
hl.bind("ALT + F4", hl.dsp.window.close(), _F)
_F = {description = "[Window Management] kill focused window"}
hl.bind(MOD .. "+ ALT  + F4", hl.dsp.window.kill(), _F)
_F = {description = "[Window Management] exit hyprland session"}
hl.bind(MOD .. " + Delete", hl.dsp.exit(), _F)
_F = {description = "[Window Management] toggle float true"}
hl.bind(MOD .. " + W", hl.dsp.window.float({action = "toggle"}), _F)
_F = {description = "[Window Management] toggle group"}
hl.bind(MOD .. " + G", hl.dsp.group.toggle(), _F)
_F = {description = "[Window Management] set a window’s pseudotiling state"}
hl.bind("ALT + P", hl.dsp.window.pseudo(), _F)

-- bindd = $mainMod, G, $d toggle group,exec, hydectl tabs
_F = {description = "[Window Management] cycle fullscreen"}
hl.bind("SHIFT + F11", cycle_fullscreen, _F)
_F = {description = "[Window Management] toggle pin"}
hl.bind(MOD .. " + SHIFT + F", hl.dsp.exec_cmd(hyde.sh.window.pin()), _F)
_F = {description = "[Window Management] logout menu"}
hl.bind("CTRL + ALT + DELETE", hl.dsp.exec_cmd(hyde.sh.session.logout.launcher()), _F)
-- ALT_R is a keysym, not a modifier: "ALT_R + CONTROL_R" resolves to a bare
-- right Control, so every press of that key hid the bar.
_F = {description = "[Window Management] hide waybar"}
hl.bind(MOD .. " + CTRL + B", hl.dsp.exec_cmd(hyde.sh.waybar("--hide")), _F)
_F = {description = "[Window Management] lock session"}
hl.bind(MOD .. " + L", hl.dsp.exec_cmd(hyde.sh.session.lock()), _F)

_F = {description = "[Window Management|Group Navigation] change active group backwards"}
hl.bind(MOD .. " + CTRL + H", hl.dsp.group.prev(), _F)
_F = {description = "[Window Management|Group Navigation] change active group forwards"}
hl.bind(MOD .. " + CTRL + L", hl.dsp.group.next(), _F)

-- $d=[$wm|Change focus]

_F = {description = "[Window Management|Change focus] focus left"}
hl.bind(MOD .. " + Left", hl.dsp.focus({direction = "left"}), _F)
_F = {description = "[Window Management|Change focus] focus right"}
hl.bind(MOD .. " + Right", hl.dsp.focus({direction = "right"}), _F)
_F = {description = "[Window Management|Change focus] focus up"}
hl.bind(MOD .. " + Up", hl.dsp.focus({direction = "up"}), _F)
_F = {description = "[Window Management|Change focus] focus down"}
hl.bind(MOD .. " + Down", hl.dsp.focus({direction = "down"}), _F)

-- _F = {description = "[Window Management|Change focus] cycle group"}
-- hl.bind("ALT + TAB", hl.dsp.group.next(), _F)

-- Window switcher
-- Handles Alt Tab like Behavior like browser
_F = {description = "[Window Management|alt-tab window switcher] cycle next", transparent = true}
hl.bind("ALT+TAB", hl.dsp.exec_cmd(hyde.sh.altab("--next")), _F)
_F = {description = "[Window Management|alt-tab window switcher] cycle previous", transparent = true}
hl.bind("ALT+SHIFT+TAB", hl.dsp.exec_cmd(hyde.sh.altab("--prev")), _F)
_F = {description = "[Window Management|alt-tab window switcher] switch", release = true, transparent = true}
hl.bind("ALT + ALT_R", hl.dsp.exec_cmd(hyde.sh.altab("--apply")), _F)
hl.bind("ALT + ALT_L", hl.dsp.exec_cmd(hyde.sh.altab("--apply")), _F)

-- # Resize kwindows

_F = {description = "[Window Management|Resize Active Window] resize window right", repeating = true}
hl.bind(MOD .. " + SHIFT + RIGHT", hl.dsp.window.resize({x = 30, y = 0, relative = true}), _F)

_F = {description = "[Window Management|Resize Active Window] resize window left", repeating = true}
hl.bind(MOD .. " + SHIFT + LEFT", hl.dsp.window.resize({x = -30, y = 0, relative = true}), _F)

_F = {description = "[Window Management|Resize Active Window] resize window up", repeating = true}
hl.bind(MOD .. " + SHIFT + UP", hl.dsp.window.resize({x = 0, y = -30, relative = true}), _F)
_F = {description = "[Window Management|Resize Active Window] resize window down", repeating = true}
hl.bind(MOD .. " + SHIFT + DOWN", hl.dsp.window.resize({x = 0, y = 30, relative = true}), _F)

-- TEXT = hl.get_active_window().floating

-- # Move active window around current workspace with mainMod + SHIFT + Control [←→↑↓]

_F = {description = "[Window Management|Move active window] left", repeating = true}
hl.bind(MOD .. " + SHIFT + CONTROL + LEFT", move_window("l", 30), _F)
_F = {description = "[Window Management|Move active window] right", repeating = true}
hl.bind(MOD .. " + SHIFT + CONTROL + RIGHT", move_window("r", 30), _F)
_F = {description = "[Window Management|Move active window] up", repeating = true}
hl.bind(MOD .. " + SHIFT + CONTROL + UP", move_window("u", 30), _F)
_F = {description = "[Window Management|Move active window] down", repeating = true}
hl.bind(MOD .. " + SHIFT + CONTROL + DOWN", move_window("d", 30), _F)

_F = {description = "[Window Management|Drag & Resize with mouse] drag window", mouse = true}
hl.bind(MOD .. " + mouse:272", hl.dsp.window.drag(), _F)
_F = {description = "[Window Management|Drag & Resize with mouse] resize window", mouse = true}
hl.bind(MOD .. " + mouse:273", hl.dsp.window.resize(), _F)
_F = {description = "[Window Management|Drag & Resize with mouse] hold to move window", mouse = true}
hl.bind(MOD .. " + Z", hl.dsp.window.drag(), _F)
_F = {description = "[Window Management|Drag & Resize with mouse] hold to resize window", mouse = true}
hl.bind(MOD .. " + X", hl.dsp.window.resize(), _F)

-- # Toggle focused window split
-- $d=[$wm]

_F = {description = "[Layout Management|Dwindle] toggle split"}
hl.bind(MOD .. " + J", hl.dsp.layout("togglesplit"), _F)

_F = {description = "[Launcher|Rofi menus] application finder"}
hl.bind(MOD .. " + A", hl.dsp.exec_cmd(hyde.sh.menu.apps()), _F)
_F = {description = "[Launcher|Rofi menus] window switcher"}
hl.bind(MOD .. " + TAB", hl.dsp.exec_cmd(hyde.sh.menu.windows()), _F)
_F = {description = "[Launcher|Rofi menus] file finder"}
hl.bind(MOD .. " + SHIFT + E", hl.dsp.exec_cmd(hyde.sh.menu.files()), _F)
_F = {description = "[Launcher|Rofi menus] keybindings hint"}
hl.bind(MOD .. " + slash", hl.dsp.exec_cmd(hyde.sh.menu.binds()), _F)
_F = {description = "[Launcher|Rofi menus] emoji picker"}
hl.bind(MOD .. " + comma", hl.dsp.exec_cmd(hyde.sh.menu.emoji()), _F)
_F = {description = "[Launcher|Rofi menus] glyph picker"}
hl.bind(MOD .. " + period", hl.dsp.exec_cmd(hyde.sh.menu.glyph()), _F)
_F = {description = "[Launcher|Rofi menus] clipboard"}
hl.bind(MOD .. " + V", hl.dsp.exec_cmd(hyde.sh.menu.clipboard()), _F)
_F = {description = "[Launcher|Rofi menus] clipboard manager"}
hl.bind(MOD .. " + SHIFT + V", hl.dsp.exec_cmd(hyde.sh.menu.cliphist()), _F)
_F = {description = "[Launcher|Rofi menus] select rofi launcher"}
hl.bind(MOD .. " + SHIFT + A", hl.dsp.exec_cmd(hyde.sh.menu.launcher()), _F)
_F = {description = "[Launcher|Rofi menus] Calculator"}
hl.bind(MOD .. " + SHIFT + K", hl.dsp.exec_cmd(hyde.sh.menu.calculator()), _F)
_F = {description = "[Launcher|Rofi menus] Web Search"}
hl.bind(MOD .. " + SHIFT + slash", hl.dsp.exec_cmd(hyde.sh.menu.search()), _F)

-- $hc=Hardware Controls
-- $d=[$hc|Audio]

-- # binddl  = , F10, $d toggle mute output , exec, hyde-shell volumecontrol.sh -o m # toggle audio mute
-- # binddel = , F11, $d decrease volume , exec, hyde-shell volumecontrol.sh -o d # decrease volume
-- # binddel = , F12, $d increase volume , exec, hyde-shell volumecontrol.sh -o i # increase volume

_F = {description = "[Hardware Controls|Audio] un/mute output", locked = true}
hl.bind("F10", hl.dsp.exec_cmd(hyde.sh.volumecontrol("-o", "m")), _F)
_F = {description = "[Hardware Controls|Audio] decrease volume", locked = true, repeating = true}
hl.bind("F11", hl.dsp.exec_cmd(hyde.sh.volumecontrol("-o", "d")), _F)
_F = {description = "[Hardware Controls|Audio] increase volume", locked = true, repeating = true}
hl.bind("F12", hl.dsp.exec_cmd(hyde.sh.volumecontrol("-o", "i")), _F)
_F = {description = "[Hardware Controls|Audio] un/mmute output", locked = true}
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(hyde.sh.volumecontrol("-o", "m")), _F)
_F = {description = "[Hardware Controls|Audio] un/mute microphone", locked = true}
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(hyde.sh.volumecontrol("-i", "m")), _F)
_F = {description = "[Hardware Controls|Audio] decrease volume", locked = true, repeating = true}
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(hyde.sh.volumecontrol("-o", "d")), _F)
_F = {description = "[Hardware Controls|Audio] increase volume", locked = true, repeating = true}
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(hyde.sh.volumecontrol("-o", "i")), _F)

_F = {description = "[Hardware Controls|Media] play media", locked = true}
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), _F)
_F = {description = "[Hardware Controls|Media] pause media", locked = true}
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), _F)
_F = {description = "[Hardware Controls|Media] next media", locked = true}
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), _F)
_F = {description = "[Hardware Controls|Media] previous media", locked = true}
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), _F)
_F = {description = "[Hardware Controls|Media] toggle un/mute for active-window"}
hl.bind(MOD .. "+ CONTROL + M", hl.dsp.exec_cmd(hyde.sh.window.mute()), _F)

_F = {description = "[Hardware Controls|Brightness] increase brightness", locked = true, repeating = true}
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(hyde.sh.brightnesscontrol("-i")), _F)
_F = {description = "[Hardware Controls|Brightness] decrease brightness", locked = true, repeating = true}
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(hyde.sh.brightnesscontrol("-d")), _F)

_F = {description = "[Utilities] toggle keyboard layout", locked = true}
hl.bind(MOD .. " + K", hl.dsp.exec_cmd(hyde.sh.kb.switch()), _F)
_F = {description = "[Utilities] game mode", locked = true}
hl.bind(MOD .. " + ALT + G", hl.dsp.exec_cmd(hyde.sh.gamemode()), _F) -- TODO
_F = {description = "[Utilities] game launcher"}
hl.bind(MOD .. " + SHIFT + G", hl.dsp.exec_cmd("hyde-shell gamelauncher"), _F)

_F = {description = "[Utilities] screen capture] color picker", locked = true}
hl.bind(MOD .. " + SHIFT + P", hl.dsp.exec_cmd("hyprpicker -an"), _F)
_F = {description = "[Utilities] partial screenshot capture", locked = true}
hl.bind(MOD .. " + P", hl.dsp.exec_cmd(hyde.sh.screenshot.snip()), _F)
_F = {description = "[Utilities] freeze and snip screen", locked = true}
hl.bind(MOD .. " + CONTROL + P", hl.dsp.exec_cmd(hyde.sh.screenshot.freeze()), _F)
_F = {description = "[Utilities] print monitor", locked = true}
hl.bind(MOD .. " + ALT + P", hl.dsp.exec_cmd(hyde.sh.screenshot.monitor()), _F)
_F = {description = "[Utilities] print all monitors", locked = true}
hl.bind("Print", hl.dsp.exec_cmd(hyde.sh.screenshot.full()), _F)
_F = {description = "[Utilities] OCR scanner", locked = true}
hl.bind(MOD .. " + CONTROL + S", hl.dsp.exec_cmd(hyde.sh.screenshot.ocr()), _F)

_F = {description = "[Theming and Wallpaper] next global wallpaper"}
hl.bind(MOD .. "+ ALT + Right", hl.dsp.exec_cmd(hyde.sh.wallpaper("--next")), _F)
_F = {description = "[Theming and Wallpaper] previous global wallpaper"}
hl.bind(MOD .. "+ ALT + Left", hl.dsp.exec_cmd(hyde.sh.wallpaper("--prev")), _F)
_F = {description = "[Theming and Wallpaper] next Waybar layout"}
hl.bind(MOD .. "+ ALT + Up", hl.dsp.exec_cmd("hyde-shell waybar --next"), _F)
_F = {description = "[Theming and Wallpaper] previous Waybar layout"}
hl.bind(MOD .. "+ ALT + Down", hl.dsp.exec_cmd("hyde-shell waybar --prev"), _F)

_F = {description = "[Theming and Wallpaper] select a global wallpaper"}
hl.bind(MOD .. "+ SHIFT + W", hl.dsp.exec_cmd(hyde.sh.menu.wallpapers()), _F)
_F = {description = "[Theming and Wallpaper] wallbash mode selector"}
hl.bind(MOD .. "+ SHIFT + R", hl.dsp.exec_cmd(hyde.sh.menu.wallbash()), _F)
_F = {description = "[Theming and Wallpaper] select a theme"}
hl.bind(MOD .. "+ SHIFT + T", hl.dsp.exec_cmd(hyde.sh.menu.themes()), _F)
_F = {description = "[Theming and Wallpaper] select animations"}
hl.bind(MOD .. "+ SHIFT + Y", hl.dsp.exec_cmd("hyde-shell animations --select"), _F)
_F = {description = "[Theming and Wallpaper] select Hyprlock layout"}
hl.bind(MOD .. "+ SHIFT + U", hl.dsp.exec_cmd("hyde-shell hyprlock --select"), _F)

-- # TODO Make a main rofi menu for these selectors
-- $rice=Theming and Wallpaper
-- $d=[$rice]
-- # bindd = $mainMod Alt, Right, $d next global wallpaper , exec, hyde-shell wallpaper.sh -Gn # next global wallpaper
-- # bindd = $mainMod Alt, Left, $d previous global wallpaper , exec, hyde-shell wallpaper.sh -Gp # previous global wallpaper
-- bindd = $mainMod SHIFT, W, $d select a global wallpaper , exec, pkill -x rofi || hyde-shell wallpaper.sh -SG # launch wallpaper select menu
-- #! bindd = $mainMod Alt, Up, $d next waybar layout , exec, hyde-shell wbarconfgen.sh n # next waybar mode
-- #! bindd = $mainMod Alt, Down, $d previous waybar layout , exec, hyde-shell wbarconfgen.sh p # previous waybar mode
-- bindd = $mainMod SHIFT, R, $d wallbash mode selector , exec, pkill -x rofi || hyde-shell wallbashtoggle.sh -m # launch wallbash mode select menu
-- bindd = $mainMod SHIFT, T, $d select a theme, exec, pkill -x rofi || hyde-shell themeselect.sh # launch theme select menu

-- Numpad keys for workspaces 11-20. The Lua bind parser has no keycode form,
-- so each key is bound under both keysyms it can emit: the digit while Num
-- Lock is on, the navigation name while it is off.
local kp = {
    [1] = {"KP_1", "KP_End"},
    [2] = {"KP_2", "KP_Down"},
    [3] = {"KP_3", "KP_Next"},
    [4] = {"KP_4", "KP_Left"},
    [5] = {"KP_5", "KP_Begin"},
    [6] = {"KP_6", "KP_Right"},
    [7] = {"KP_7", "KP_Home"},
    [8] = {"KP_8", "KP_Up"},
    [9] = {"KP_9", "KP_Prior"},
    [10] = {"KP_0", "KP_Insert"}
}

for i = 1, 10 do
    _F = {description = "[Workspaces|Navigation] navigate to workspace " .. i}
    hl.bind(MOD .. " + " .. ((i == 10) and 0 or i), hl.dsp.focus({workspace = i}), _F)
end

for i = 1, 10 do
    for _, key in ipairs(kp[i]) do
        hl.bind(
            MOD .. " + " .. key,
            hl.dsp.focus({workspace = tostring(i + 10)}),
            {description = "[Workspaces|Navigation] navigate to workspace " .. (i + 10)}
        )
    end
end

_F = {description = "[Workspaces|Navigation|Relative workspace] change active workspace forwards"}
hl.bind(MOD .. " + CONTROL + RIGHT", hl.dsp.focus({workspace = "r+1"}), _F)
_F = {description = "[Workspaces|Navigation|Relative workspace] change active workspace backwards"}
hl.bind(MOD .. " + CONTROL + LEFT", hl.dsp.focus({workspace = "r-1"}), _F)

_F = {description = "[Workspaces|Navigation] navigate to the nearest empty workspace"}
hl.bind(MOD .. " + CONTROL + DOWN", hl.dsp.focus({workspace = "empty"}), _F)

for i = 1, 10 do
    _F = {description = "[Workspaces|Move window to workspace] move focused window to workspace " .. i}
    hl.bind(MOD .. " + SHIFT + " .. ((i == 10) and 0 or i), hl.dsp.window.move({workspace = i}), _F)
end

for i = 1, 10 do
    for _, key in ipairs(kp[i]) do
        hl.bind(
            MOD .. " + SHIFT + " .. key,
            hl.dsp.window.move({workspace = tostring(i + 10)}),
            {description = "[Workspaces|Move window to workspace] move focused window to workspace " .. (i + 10)}
        )
    end
end

_F = {description = "[Workspaces|Move window to workspace|Relative workspace] move focused window to next workspace"}
hl.bind(MOD .. " + CONTROL + ALT + RIGHT", hl.dsp.window.move({workspace = "r+1"}), _F)
_F = {
    description = "[Workspaces|Move window to workspace|Relative workspace] move focused window to previous workspace"
}
hl.bind(MOD .. " + CONTROL + ALT + LEFT", hl.dsp.window.move({workspace = "r-1"}), _F)

_F = {description = "[Workspaces|Navigation|Mouse] next workspace"}
hl.bind(MOD .. " + mouse_down", hl.dsp.focus({workspace = "e+1"}), _F)
_F = {description = "[Workspaces|Navigation|Mouse] previous workspace"}
hl.bind(MOD .. " + mouse_up", hl.dsp.focus({workspace = "e-1"}), _F)

-- # Move/Switch to special workspace (scratchpad)
_F = {description = "[Workspaces|Navigation|Special workspace] toggle scratchpad"}
hl.bind(MOD .. " + S", hl.dsp.workspace.toggle_special(), _F)
_F = {description = "[Workspaces|Navigation|Special workspace] move focused window to scratchpad"}
hl.bind(MOD .. " + SHIFT + S", hl.dsp.window.move({workspace = "special"}), _F)
_F = {description = "[Workspaces|Navigation|Special workspace] move focused window silently to scratchpad"}
hl.bind(MOD .. " + ALT + S", hl.dsp.window.move({workspace = "special", follow = false}), _F)

--- Move silent
---
for i = 1, 10 do
    _F = {description = "[Workspaces|Move window (Don't follow)] move focused window to workspace " .. i}
    hl.bind(MOD .. " + ALT + " .. ((i == 10) and 0 or i), hl.dsp.window.move({workspace = i, follow = false}), _F)
end

-- Optionals

-- # $bind.Overview.Window = "qs -c Overview2 ipc call Overview2 toggle ||  qs -c Overview2"

-- $d=#! unset the group name

-- unbind = $mainMod, K
-- binddl = $mainMod, K, $d toggle keyboard layout , exec, hyprctl switchxkblayout all next -q # switch keyboard layout

-- unbind = $mainMod, K
-- binddl = $mainMod, K, $d toggle onscreen kb,exec, squeekboard

-- bindd = $mainMod Alt,slash, AI tts,exec, cd ~/AI/Talk && ./main.py --output tts

-- $gemini_bridge=bash $HOME/.scripts/gemini-bridge/gemini-bridge.sh
-- exec-once = $gemini_bridge
-- bindd = $mainMod Alt,P, Push Clipboard to gemini,exec,$gemini_bridge --push

-- bindd = $mainMod SHIFT, X,Inverted Screenshot, exec, $HOME/.local/bin/inverted-screenshot.sh

-- unbind = Alt, Tab
-- binddt = Alt, Tab, Cycle Tabs, exec, hyprctl dispatch submap altab &&  hyde-shell hypr.altab --no-notify
-- binddt = Alt SHIFT, Tab, Cycle Tabs Reversed, exec, hyprctl dispatch submap altab &&  hyde-shell hypr.altab  --prev --no-notify

-- submap = altab
-- binddt = Alt, Tab, Cycle Tabs, exec, hyde-shell hypr.altab
-- binddt = Alt SHIFT, Tab, Cycle Tabs, exec, hyde-shell hypr.altab --prev

-- bindntr = Alt, Alt_L, exec, hyde-shell hypr.altab --apply
-- bindntr = Alt, Alt_R, exec, hyde-shell hypr.altab --apply
-- bindntr = Alt, Alt_L, submap,reset
-- bindntr = Alt, Alt_R, submap,reset
-- bindntr = ,catchall,exec, notify-send "Keybinding Reset" "Exited submap mode"
-- bindntr = ,catchall,exec, hyde-shell hypr.altab --apply
-- bindntr = ,catchall,submap,reset
-- bind = ,catchall,exec, notify-send "Keybinding Reset Second" "Exited submap mode"
-- submap = reset

-- exec-once = hyde-shell app -- wayscriber --daemon
-- bindd = Alt, D, Annotate Screen,exec,pkill -SIGUSR1 wayscriber

-- # $bind.Overview.Window = "qs -c Overview2 ipc call Overview2 toggle ||  qs -c Overview2"

-- unbind = $mainMod,TAB
-- binddtn = $mainMod,Tab, Window Overview,exec, qs -c Overview ipc call Overview2 open ||  qs -c Overview

-- bind = Super ALT, F , exec , notify-send "Hyprland" "Hyprland is awesome!"
-- unbind = SUPER                     ALT , F
-- bindk = Super     ALT, F ,test device, exec , notify-send "Hyprland" "You just pressed Super + F again!"
-- bindk = Super     ALT, F ,test device, exec , notify-send "Hyprland" "You just pressed Super + F again!2"

-- # bindd = Alt, D , [Utilities] Enable Wayscriber ,exec, wayscriber --active

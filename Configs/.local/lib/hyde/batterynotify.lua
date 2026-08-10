#!/usr/bin/env lua
-- batterynotify.lua
-- Use lgi (Gio) to subscribe to UPower DBus updates and read device properties.
-- Notifications via `luautils.global.notify` (lgi/libnotify preferred, else background notify-send).

-- Bootstrap HyDE luautils paths
local root = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = package.path .. ";" .. root .. "?.lua;" .. root .. "?/init.lua;"
require('luautils.init')
local xdg = require('luautils.xdg')
local notify_mod = require('luautils.global.notify')
local notify_send = notify_mod.send

-- optional libs
local lgi_ok, lgi_mod_or_err = pcall(require, 'lgi')
local lgi = nil
local lgi_err = nil
if lgi_ok then
    lgi = lgi_mod_or_err
else
    lgi_err = lgi_mod_or_err
end

local GLib, Gio
local glib_ok, gio_ok = false, false
local glib_err, gio_err = nil, nil
local have_lgi_gio = false
if lgi then
    glib_ok, GLib = pcall(lgi.require, 'GLib')
    if not glib_ok then
        glib_err = GLib; GLib = nil
    end
    gio_ok, Gio = pcall(lgi.require, 'Gio')
    if not gio_ok then
        gio_err = Gio; Gio = nil
    end
    if glib_ok and gio_ok then have_lgi_gio = true end
end
local have_luv, uv = pcall(require, 'luv')
local log = require('luautils.global.log')

-- locals
local io = io
local os = os
local tonumber = tonumber
local tostring = tostring
local string = string
local math = math

-- helpers -----------------------------------------------------------------
local function trim(s)
    if not s then return s end; return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end
local function getenv_bool(name, default)
    local v = os.getenv(name); if not v then return default end; v = v:lower(); return (v == '1' or v == 'true' or v == 'yes' or v == 'on')
end
local function getenv_int(name, default)
    local v = os.getenv(name); if not v then return default end; local n = tonumber(v); if not n then return default end; return
        n
end
local function has_command(cmd)
    local f = io.popen('command -v ' .. cmd .. ' 2>/dev/null')
    if not f then return false end
    local out = f:read('*l'); f:close(); return out and out ~= ''
end
local function run_cmd_shell(cmd)
    if not cmd or cmd == '' then return end
    if GLib then
        pcall(GLib.spawn_command_line_async, cmd); return
    end
    os.execute('sh -c ' .. string.format('%q', cmd .. ' &'))
end

-- GIO/UPower device proxies ------------------------------------------------
local manager = nil
local devices_proxies = {}

local function refresh_gio_devices()
    if not Gio then return end
    if not manager then
        manager = Gio.DBusProxy.new_for_bus_sync(Gio.BusType.SYSTEM, Gio.DBusProxyFlags.NONE, nil,
            'org.freedesktop.UPower', '/org/freedesktop/UPower', 'org.freedesktop.UPower', nil)
        if not manager then return end
    end
    devices_proxies = {}
    local result = manager:call_sync('EnumerateDevices', nil, Gio.DBusCallFlags.NONE, -1, nil)
    if not result then return end
    for i = 1, #result do
        local path = result[i][1]
        if path then
            local proxy = Gio.DBusProxy.new_for_bus_sync(Gio.BusType.SYSTEM, Gio.DBusProxyFlags.NONE, nil,
                'org.freedesktop.UPower', path, 'org.freedesktop.UPower.Device', nil)
            if proxy then devices_proxies[path] = proxy end
        end
    end
end

local function upower_state_to_string(n)
    if not n then return 'Unknown' end
    local i = tonumber(n) or 0
    if i == 1 or i == 5 then return 'Charging' end
    if i == 2 or i == 6 then return 'Discharging' end
    if i == 4 then return 'Full' end
    return 'Unknown'
end

local function get_battery_info_gio()
    if not Gio then return end
    if not manager then refresh_gio_devices() end
    local total, cnt, last_status = 0, 0, 'Unknown'
    for path, proxy in pairs(devices_proxies) do
        if not proxy then goto continue end
        local tvar = proxy:get_cached_property('Type')
        local t = tvar and tvar.value
        local is_battery = (t == 2)
        if not is_battery then
            local np = proxy:get_cached_property('NativePath')
            local npv = np and tostring(np.value)
            if npv and npv:match('BAT') then is_battery = true end
        end
        if is_battery then
            local pv = proxy:get_cached_property('Percentage')
            local sv = proxy:get_cached_property('State')
            local p = pv and pv.value
            local s = sv and sv.value
            if p then
                total = total + tonumber(p); cnt = cnt + 1
            end
            if s then last_status = upower_state_to_string(s) end
        end
        ::continue::
    end
    if cnt == 0 then return end
    return last_status, math.floor(total / cnt)
end

local function get_battery_info()
    local ok, s, p = pcall(get_battery_info_gio)
    if ok and s then return s, p end
    return nil, nil
end

-- Detect whether this machine has a battery / is a laptop
local function is_laptop()
    if not Gio then return false end
    pcall(refresh_gio_devices)
    for _, proxy in pairs(devices_proxies) do
        if not proxy then goto continue end
        local tvar = proxy:get_cached_property('Type')
        local t = tvar and tvar.value
        if t == 2 then return true end -- 2 == Battery
        local np = proxy:get_cached_property('NativePath')
        local npv = np and tostring(np.value)
        if npv and npv:match('BAT') then return true end
        ::continue::
    end
    return false
end

-- config ------------------------------------------------------------------
local conf = {
    battery_full_threshold = getenv_int('BATTERY_NOTIFY_THRESHOLD_FULL', 100),
    battery_critical_threshold = getenv_int('BATTERY_NOTIFY_THRESHOLD_CRITICAL', 5),
    unplug_charger_threshold = getenv_int('BATTERY_NOTIFY_THRESHOLD_UNPLUG', 80),
    battery_low_threshold = getenv_int('BATTERY_NOTIFY_THRESHOLD_LOW', 20),
    timer = getenv_int('BATTERY_NOTIFY_TIMER', 120),
    notify = getenv_int('BATTERY_NOTIFY_NOTIFY', 1140),
    interval = getenv_int('BATTERY_NOTIFY_INTERVAL', 5),
    execute_critical = os.getenv('BATTERY_NOTIFY_EXECUTE_CRITICAL') or 'systemctl suspend',
    execute_low = os.getenv('BATTERY_NOTIFY_EXECUTE_LOW') or '',
    execute_unplug = os.getenv('BATTERY_NOTIFY_EXECUTE_UNPLUG') or '',
    execute_charging = os.getenv('BATTERY_NOTIFY_EXECUTE_CHARGING') or '',
    execute_discharging = os.getenv('BATTERY_NOTIFY_EXECUTE_DISCHARGING') or '',
    dock = getenv_bool('BATTERY_NOTIFY_DOCK', false),
    XDG_CONFIG_HOME = os.getenv('XDG_CONFIG_HOME') or xdg.config,
}
conf.XDG_RUNTIME_DIR = os.getenv('XDG_RUNTIME_DIR') or
    ('/run/user/' .. tostring((os.geteuid and os.geteuid()) or tonumber(os.getenv('UID')) or 0))

local runtime_dir = conf.XDG_RUNTIME_DIR .. '/hyde'

local function show_config()
    io.write('\nModify ' .. conf.XDG_CONFIG_HOME .. '/hyde/config.toml to set options.\n')
    io.write('      STATUS      THRESHOLD    INTERVAL\n')
    io.write(string.format('      Full        %d          %d Minutes\n', conf.battery_full_threshold, conf.notify))
    io.write(string.format("      Critical    %d           %d Seconds then '%s'\n", conf.battery_critical_threshold,
        conf.timer, conf.execute_critical))
    io.write(string.format("      Low         %d           %d Percent    then '%s'\n", conf.battery_low_threshold,
        conf.interval, conf.execute_low))
    io.write(string.format("      Unplug      %d          %d Percent   then '%s'\n\n", conf.unplug_charger_threshold,
        conf.interval, conf.execute_unplug))
    io.write('      Command on Charging: ' .. conf.execute_charging .. '\n')
    io.write('      Command on Discharging: ' .. conf.execute_discharging .. '\n')
    io.write('      Dock Mode: ' .. tostring(conf.dock) .. ' (Will not notify on status change)\n')
end

-- state ------------------------------------------------------------------
local verbose = false
local last_notified_percentage = 0
local prev_status = nil
local last_battery_status = nil
local last_battery_percentage = nil
local lt = os.time()
local executed_low = false
local executed_unplug = false

-- critical countdown ----------------------------------------------------
local crit_source = nil
local crit_remaining = 0
local function start_critical_countdown()
    if crit_source then return end
    crit_remaining = math.max(conf.timer, 60)
    if GLib then
        crit_source = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 1, function()
            local st, pct = get_battery_info()
            if not st or not st:match('^Discharging') then
                crit_source = nil; return false
            end
            local mm = math.floor(crit_remaining / 60); local ss = crit_remaining % 60
            notify_send('Battery Critically Low',
                string.format('%d%% is critically low. Device will execute %s in %d:%02d.', pct, conf.execute_critical,
                    mm, ss), 'critical', 'xfce4-battery-critical')
            crit_remaining = crit_remaining - 1
            if crit_remaining <= 0 then
                run_cmd_shell(conf.execute_critical); crit_source = nil; return false
            end
            return true
        end)
        log.debug('Started critical countdown (glib)')
    elseif have_luv and uv then
        local timer = uv.new_timer()
        timer:start(1000, 1000, function()
            local st, pct = get_battery_info()
            if not st or not st:match('^Discharging') then
                timer:stop(); timer:close(); crit_source = nil; return
            end
            local mm = math.floor(crit_remaining / 60); local ss = crit_remaining % 60
            notify_send('Battery Critically Low',
                string.format('%d%% is critically low. Device will execute %s in %d:%02d.', pct, conf.execute_critical,
                    mm, ss), 'critical', 'xfce4-battery-critical')
            crit_remaining = crit_remaining - 1
            if crit_remaining <= 0 then
                run_cmd_shell(conf.execute_critical); timer:stop(); timer:close(); crit_source = nil
            end
        end)
        crit_source = timer
        log.debug('Started critical countdown (luv)')
    else
        log.debug('No timer facility available to run critical countdown')
    end
end

local function cancel_critical_countdown()
    if not crit_source then return end
    if GLib and type(crit_source) == 'number' then
        GLib.source_remove(crit_source); crit_source = nil; return
    end
    if have_luv and uv and crit_source and crit_source.stop then
        crit_source:stop(); crit_source:close(); crit_source = nil; return
    end
    crit_source = nil
    log.debug('Cancelled critical countdown')
end

-- core logic ------------------------------------------------------------
local function starts_with(s, pre)
    if not s or not pre then return false end; return s:sub(1, #pre) == pre
end

local function handle_update()
    local status, percentage = get_battery_info()
    if status == last_battery_status and percentage == last_battery_percentage then return end
    last_battery_status = status; last_battery_percentage = percentage
    log.debug('Battery %s %d%%', tostring(status), percentage)

    if percentage <= conf.battery_low_threshold and not executed_low then
        if conf.execute_low ~= '' then run_cmd_shell(conf.execute_low) end
        executed_low = true; executed_unplug = false
    end
    if percentage >= conf.unplug_charger_threshold and not executed_unplug then
        if conf.execute_unplug ~= '' then run_cmd_shell(conf.execute_unplug) end
        executed_unplug = true; executed_low = false
    end

    if percentage >= conf.unplug_charger_threshold and not string.find(tostring(status), 'Discharging') and status ~= 'Full' and (percentage - last_notified_percentage) >= conf.interval then
        local steps = math.floor(((percentage + 5) / 10) + 0.00001) * 10
        local icon = 'battery-' .. tostring((steps > 0) and steps or 100) .. '-charging'
        log.debug('Prompt: UNPLUG threshold=%d status=%s percentage=%d steps=%d',
            conf.unplug_charger_threshold, tostring(status), percentage, steps)
        cancel_critical_countdown()
    end

    if percentage <= conf.battery_critical_threshold then
        if starts_with(tostring(status), 'Discharging') then
            start_critical_countdown()
        else
            cancel_critical_countdown()
        end
    else
        cancel_critical_countdown()
    end

    if percentage <= conf.battery_low_threshold and starts_with(tostring(status), 'Discharging') and (last_notified_percentage - percentage) >= conf.interval then
        local steps = math.floor(((percentage + 5) / 10) + 0.00001) * 10
        local icon = 'battery-level-' .. tostring((steps > 0) and steps or 10) .. '-symbolic'
        log.debug('Prompt: LOW threshold=%d status=%s percentage=%d',
            conf.battery_low_threshold, tostring(status), percentage)
        notify_send('Battery Low', string.format('Battery is at %d%%. Connect the charger.', percentage), 'critical', icon)
        last_notified_percentage = percentage
    end

    if not conf.dock then
        if starts_with(tostring(status), 'Discharging') then
            if prev_status ~= 'Discharging' or prev_status == 'Full' then
                prev_status = status
                local urgency = (percentage <= conf.battery_low_threshold) and 'CRITICAL' or 'NORMAL'
                local steps = math.floor(((percentage + 5) / 10) + 0.00001) * 10
                local icon = 'battery-level-' .. tostring((steps > 0) and steps or 10) .. '-symbolic'
                notify_send('Charger Plug Out', string.format('Battery is at %d%%.', percentage), urgency, icon)
                if conf.execute_discharging ~= '' then run_cmd_shell(conf.execute_discharging) end
            end
        elseif starts_with(tostring(status), 'Not') or starts_with(tostring(status), 'Charging') then
            if prev_status == 'Discharging' or (prev_status and starts_with(prev_status, 'Not')) then
                prev_status = status
                local urgency = (percentage >= conf.unplug_charger_threshold) and 'CRITICAL' or 'NORMAL'
                local steps = math.floor(((percentage + 5) / 10) + 0.00001) * 10
                local icon = 'battery-' .. tostring((steps > 0) and steps or 100) .. '-charging'
                notify_send('Charger Plug In', string.format('Battery is at %d%%.', percentage), urgency, icon)
                if conf.execute_charging ~= '' then run_cmd_shell(conf.execute_charging) end
            end
        elseif status == 'Full' then
            if status ~= 'Discharging' then
                local now = os.time()
                local do_notify = false
                if prev_status and string.find(prev_status, 'harging') then do_notify = true end
                if not do_notify and (now - lt) >= (conf.notify * 60) then do_notify = true end
                if do_notify then
                    notify_send('Battery Full', 'Please unplug your Charger', 'critical',
                        'battery-full-charging-symbolic')
                    prev_status = status
                    lt = now
                    if conf.execute_charging ~= '' then run_cmd_shell(conf.execute_charging) end
                end
            end
        else
            local fname = '/tmp/hyde.battery.notify.status.fallback.' ..
                tostring(status or 'unk') .. '-' .. tostring((os.getpid and os.getpid()) or 0)
            local fh = io.open(fname)
            if not fh then
                io.write("Status: '==>> \"" ..
                    tostring(status) .. "\" <<==' Script on Fallback mode,Unknown power supply status.\n")
                local w = io.open(fname, 'w')
                if w then w:close() end
            else
                fh:close()
            end
        end
    end
end

-- main -------------------------------------------------------------------
local function main(argv)
    for i = 1, #argv do
        local a = argv[i]
        if a == '-i' or a == '--info' then
            show_config(); return
        end
        if a == '-v' or a == '--verbose' then verbose = true; log.level = 'debug' end
        if a == '-h' or a == '--help' then
            io.write('Usage: batterynotify.lua [-i] [-v]\n'); return
        end
    end

    if not (GLib and Gio) then
        io.write(
        'ERROR: lgi with GLib/Gio GIR bindings required. Please install lgi and the GIRs for GLib/Gio.\n')
        io.write(string.format('Diagnostics: lgi_ok=%s, lgi_err=%s, glib_ok=%s, glib_err=%s, gio_ok=%s, gio_err=%s\n',
            tostring(lgi_ok), tostring(lgi_err), tostring(glib_ok), tostring(glib_err), tostring(gio_ok),
            tostring(gio_err)))
        io.write('Lua version: ' .. tostring(_VERSION) .. '\n')
        io.write('package.path: ' .. tostring(package.path) .. '\n')
        io.write('package.cpath: ' .. tostring(package.cpath) .. '\n')
        return
    end

    if not is_laptop() then
        io.write('No battery detected. Exiting.\n'); return
    end

    local bs, bp = get_battery_info()
    last_notified_percentage = bp
    prev_status = bs
    last_battery_status = bs
    last_battery_percentage = bp
    lt = os.time()
    log.debug('Initial status=%s percentage=%d', tostring(bs), bp)

    log.debug('Mode: using lgi/Gio DBus UPower')

    local conn = Gio.bus_get_sync(Gio.BusType.SYSTEM)
    local function on_signal(connection, sender, object_path, interface_name, signal_name, parameters)
        -- We don't need to parse parameters: simply update from UPower
        handle_update()
    end
    -- subscribe to UPower signals
    conn:signal_subscribe(nil, 'org.freedesktop.UPower', 'DeviceChanged', nil, nil, Gio.DBusSignalFlags.NONE,
        on_signal)
    conn:signal_subscribe(nil, 'org.freedesktop.UPower', 'DeviceAdded', nil, nil, Gio.DBusSignalFlags.NONE, on_signal)
    conn:signal_subscribe(nil, 'org.freedesktop.UPower', 'DeviceRemoved', nil, nil, Gio.DBusSignalFlags.NONE,
        on_signal)
    -- also listen for property changes on devices
    conn:signal_subscribe(nil, 'org.freedesktop.DBus.Properties', 'PropertiesChanged', nil,
        'org.freedesktop.UPower.Device', Gio.DBusSignalFlags.NONE, on_signal)

    -- run GLib main loop
    local loop = GLib.MainLoop()
    loop:run()
end

main({ ... })

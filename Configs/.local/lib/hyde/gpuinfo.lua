#!/usr/bin/env lua
local root = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = package.path .. ";" .. root .. "?.lua;" .. root .. "?/init.lua;"
require("luautils.init")

local json = require("luautils.json")
local lfs = require("lfs")

local M = {}

--- Path to this gpuinfo instance's state file. `suffix` matches the bash
--- version's "$gpuinfo_file$2" (a per-waybar-module-instance state, set via
--- --use/--startup so e.g. the #amd and #intel waybar modules don't clobber
--- each other's toggle/priority state).
function M.state_path(suffix)
    local runtime_dir = os.getenv("XDG_RUNTIME_DIR") or "/tmp"
    -- UID is a bash shell variable, never exported, so os.getenv("UID") is
    -- always nil here. Stat $HOME instead, so the /tmp fallback (used when
    -- XDG_RUNTIME_DIR is unset -- when it is set it is already per-user)
    -- stays scoped per user rather than colliding on /tmp/hyde-0-gpuinfo.json.
    local uid = lfs.attributes(os.getenv("HOME") or "/", "uid") or 0
    return runtime_dir .. "/hyde-" .. tostring(uid) .. "-gpuinfo" .. (suffix or "") .. ".json"
end

--- Reads the state for `suffix`. Always returns a table -- a missing or
--- corrupt file (a hand-edited or half-written state file, since this runs
--- on every single poll) degrades to {} rather than erroring, so a caller
--- never has to special-case "no state yet" separately from "read failed".
function M.read_state(suffix)
    local f = io.open(M.state_path(suffix), "r")
    if not f then
        return {}
    end
    local content = f:read("*a")
    f:close()
    local ok, decoded = pcall(json.decode, content)
    if ok and type(decoded) == "table" then
        return decoded
    end
    return {}
end

--- Writes the whole state for `suffix` as one JSON object, replacing
--- whatever was there -- no in-place text editing (this is what replaces
--- the bash version's incremental echo>>/sed -i dance).
function M.write_state(suffix, state)
    local f, open_err = io.open(M.state_path(suffix), "w")
    if not f then
        return nil, "failed to open state file for writing: " .. tostring(open_err)
    end
    local ok, write_err = pcall(function()
        f:write(json.encode(state))
    end)
    f:close()
    if not ok then
        return nil, "failed to encode/write state: " .. tostring(write_err)
    end
    return true
end

local PCI_VENDOR_IDS = {["0x10de"] = "nvidia", ["0x1002"] = "amd", ["0x8086"] = "intel"}

local function read_first_line(path)
    local f = io.open(path, "r")
    if not f then
        return nil
    end
    local line = f:read("*l")
    f:close()
    return line
end

local function find_in_path(cmd, path_dirs)
    if cmd:match("^/") then
        -- Absolute path
        if lfs.attributes(cmd, "mode") == "file" then
            return cmd
        end
        return nil
    end
    for _, dir in ipairs(path_dirs) do
        local full_path = dir .. "/" .. cmd
        if lfs.attributes(full_path, "mode") == "file" then
            return full_path
        end
    end
    return nil
end

--- Finds the human-readable device name for a PCI address using the one
--- targeted lspci call this rewrite keeps (see the spec's "what changes"
--- table: reimplementing the PCI ID name database in Lua is out of scope,
--- lspci is the tool built for that -- this call is scoped to one specific
--- address instead of the bash version's three full-bus `lspci | grep` scans).
local function lookup_pci_name(lspci_cmd, addr)
    local handle = io.popen(lspci_cmd .. " -nn -s " .. addr .. " 2>/dev/null")
    if not handle then
        return nil
    end
    local line = handle:read("*l")
    handle:close()
    if not line then
        return nil
    end
    -- "00:02.0 VGA compatible controller [0300]: Intel Corporation Kaby Lake-U GT2 [HD Graphics 620] [8086:5916] (rev 02)"
    -- -> "Kaby Lake-U GT2 [HD Graphics 620]" (drop the vendor prefix, the
    -- trailing [ids] bracket, and the (rev) suffix -- but keep a marketing-
    -- name bracket like "[HD Graphics 620]" or "[GeForce RTX 3060]": that's
    -- the name most people actually know the card by, unlike the bare
    -- codename bash's original `gsub(/ *\[[^\]]*\]/,"")` left behind).
    -- Anchored on "]:" (the class-id's closing bracket), not a bare ":" --
    -- the PCI slot itself ("00:02.0") contains a colon earlier in the line,
    -- and Lua patterns search from the first position that matches, so a
    -- bare ":" anchor grabs everything after the *slot's* colon instead
    -- (verified empirically while writing this plan: a bare ":" pattern
    -- against the example line above returns "02.0 VGA compatible
    -- controller [0300]: Intel Corporation Kaby Lake-U GT2 ..." --  the
    -- slot number leaking into the name -- not the intended match).
    local rest = line:match("%]:%s*(.+)$")
    if not rest then
        return nil
    end
    -- Only the trailing [vendor:device] id bracket is stripped -- it's
    -- always exactly 4 hex digits either side of the colon, which a
    -- marketing-name bracket never is, so this can't misfire on one.
    rest = rest:gsub("%[%x%x%x%x:%x%x%x%x%]", ""):gsub("%(rev%s*%x+%)", "")
    rest = rest:gsub("^%s+", ""):gsub("%s+$", "")
    rest = rest:gsub("^%a+ ?%a*%a* Corporation,? ?", ""):gsub("^Advanced Micro Devices, Inc%.,? ?", "")
    -- pci.ids lists AMD's vendor name as "Advanced Micro Devices, Inc.
    -- [AMD/ATI]" -- that bracket is a vendor alias, not part of the chip's
    -- identity, and unlike a genuine marketing-name bracket it sits before
    -- the codename rather than after it, so it must go even though the
    -- rule above is to keep marketing brackets.
    rest = rest:gsub("^%[AMD/ATI%] ?", "")
    return rest ~= "" and rest or nil
end

--- Detects which GPU vendor(s) are present by scanning /sys/bus/pci/devices
--- directly (pure Lua) instead of the bash version's three separate full-bus
--- `lspci -nn | grep -E "VGA|3D" | grep -i <vendor>` scans per poll.
function M.detect_vendor(opts)
    opts = opts or {}
    local pci_dir = opts.pci_dir or "/sys/bus/pci/devices"
    local modules_file = opts.modules_file or "/proc/modules"
    local lspci_cmd = opts.lspci_cmd or "lspci"
    local path_dirs = opts.path_dirs
    if not path_dirs then
        path_dirs = {}
        for dir in (os.getenv("PATH") or ""):gmatch("[^:]+") do
            path_dirs[#path_dirs + 1] = dir
        end
    end

    -- Resolve lspci command to full path
    local resolved_lspci = find_in_path(lspci_cmd, path_dirs) or lspci_cmd

    local result = {nvidia = false, amd = false, intel = false}
    local nouveau_found = false

    if lfs.attributes(pci_dir, "mode") == "directory" then
        for entry in lfs.dir(pci_dir) do
            if entry ~= "." and entry ~= ".." then
                local dev_dir = pci_dir .. "/" .. entry
                local class_line = read_first_line(dev_dir .. "/class")
                -- Display controller class codes are 0x03xxxx (VGA 0300, 3D
                -- 0302, other-display 0380). A garbage/unreadable class file
                -- is skipped, not treated as a match.
                if class_line and class_line:match("^0x03%x%x%x%x%s*$") then
                    local vendor_line = read_first_line(dev_dir .. "/vendor")
                    local vendor_id = vendor_line and vendor_line:match("^(0x%x+)")
                    local vendor_name = vendor_id and PCI_VENDOR_IDS[vendor_id:lower()]
                    if vendor_name and not result[vendor_name] then
                        result[vendor_name] = true
                        result[vendor_name .. "_addr"] = entry
                        result[vendor_name .. "_gpu"] = lookup_pci_name(resolved_lspci, entry)
                    end
                end
            end
        end
    end

    -- nouveau (open-source nvidia driver): read /proc/modules directly
    -- instead of `lsmod | grep nouveau`.
    local modules_f = io.open(modules_file, "r")
    if modules_f then
        for line in modules_f:lines() do
            if line:match("^nouveau%s") then
                nouveau_found = true
                -- Display-name fallback only, when PCI detection couldn't
                -- resolve one via lspci. Nouveau-ness itself is recorded
                -- separately below -- comparing the name against this
                -- placeholder would misidentify a real PCI-resolved name
                -- as "not nouveau" even when nouveau is the only driver
                -- present (caught in review: cli_main used to do exactly
                -- that comparison, so a nouveau host that also happened to
                -- have a resolvable lspci name took the nvidia-smi path
                -- and got nothing back instead of the generic sensor path).
                result.nvidia_gpu = result.nvidia_gpu or "Linux"
            end
        end
        modules_f:close()
    end
    result.nvidia_nouveau = nouveau_found

    return result
end

local VENDOR_ORDER = {"nvidia", "amd", "intel"}

--- Cycles (or jumps to, if `requested` is set) the enabled GPU vendor,
--- mutating `state` in place. Returns the new vendor name, or (nil, err) if
--- `requested` names a vendor that isn't actually available.
---
--- Availability comes from `state.available`, the list detection records once
--- (the port of the bash version's GPUINFO_AVAILABLE). It deliberately does
--- not come from the `*_enable` keys, in either direction:
---   * `state[v .. "_enable"] ~= nil` (presence) is wrong because cli_main
---     writes all three keys on every detection, explicit `false` included --
---     so every vendor looked available on every machine, one --toggle could
---     select a vendor that was never detected, and every later poll then
---     crashed on its never-populated `*_gpu` name (blank module until
---     --reset).
---   * truthiness alone is wrong because `*_enable` records which vendor is
---     *selected*, and the loop at the bottom of this function sets the others
---     to false -- so after one toggle there would be nothing left to cycle to
---     and --toggle would become a no-op. (Bash avoided this by *commenting
---     out* the losing GPUINFO_*_ENABLE=1 lines, keeping them greppable.)
--- A state with no recorded availability (hand-edited, or a direct API caller)
--- degrades to "whatever is currently enabled".
function M.toggle(state, requested)
    local recorded
    if type(state.available) == "table" and #state.available > 0 then
        recorded = {}
        for _, name in ipairs(state.available) do
            recorded[name] = true
        end
    end

    local available = {}
    for _, vendor in ipairs(VENDOR_ORDER) do
        local is_available
        if recorded then
            is_available = recorded[vendor]
        else
            is_available = state[vendor .. "_enable"]
        end
        if is_available then
            available[#available + 1] = vendor
        end
    end
    if #available == 0 then
        return nil, "no GPU vendor is available"
    end

    local next_vendor
    if requested then
        local found = false
        for _, vendor in ipairs(available) do
            if vendor == requested then
                found = true
                break
            end
        end
        if not found then
            return nil, requested .. " not found in available vendors"
        end
        next_vendor = requested
    else
        local current_index = 1
        for i, vendor in ipairs(available) do
            if vendor == state.priority then
                current_index = i
                break
            end
        end
        next_vendor = available[(current_index % #available) + 1]
    end

    for _, vendor in ipairs(available) do
        state[vendor .. "_enable"] = (vendor == next_vendor)
    end
    state.priority = next_vendor
    return next_vendor
end

--- Reads battery discharge power in watts from /sys/class/power_supply
--- (or `power_supply_dir` in tests), pure Lua -- no awk. Prefers power_now
--- (microwatts); falls back to current_now*voltage_now (microamps *
--- microvolts) when power_now is missing or unreadable/empty, since some
--- laptops' embedded controller answers ENXIO for power_now specifically.
function M.read_battery_discharge(power_supply_dir)
    if lfs.attributes(power_supply_dir, "mode") ~= "directory" then
        return nil
    end
    for entry in lfs.dir(power_supply_dir) do
        if entry:match("^BAT") then
            local bat_dir = power_supply_dir .. "/" .. entry
            local power_raw = read_first_line(bat_dir .. "/power_now")
            local power_now = power_raw and tonumber(power_raw)
            if power_now then
                return power_now * 1e-6
            end
            local current_raw = read_first_line(bat_dir .. "/current_now")
            local voltage_raw = read_first_line(bat_dir .. "/voltage_now")
            local current_now = current_raw and tonumber(current_raw)
            local voltage_now = voltage_raw and tonumber(voltage_raw)
            if current_now and voltage_now then
                return (current_now * voltage_now) / 1e12
            end
        end
    end
    return nil
end

--- Reads current CPU utilization as a percentage, diffed against the
--- previous poll's totals persisted in `state.prev_stat`/`state.prev_idle`.
--- Seeds both to the current reading on the very first call (no prior state),
--- which makes that first call report 0% instead of a division-by-zero or a
--- nonsense diff against zero -- the same cold-start contract #2021/#2022
--- already fixed for the bash version.
function M.read_cpu_utilization(state, stat_file)
    stat_file = stat_file or "/proc/stat"
    -- Degrades like every sibling reader here: a missing or malformed stat
    -- file reads as 0%, it never raises. This runs on every poll, and a raise
    -- would take the whole waybar module's JSON line down with it.
    local f = io.open(stat_file, "r")
    if not f then
        return 0
    end
    local line = f:read("*l")
    f:close()
    local user, nice, system, idle, iowait, irq, softirq = (line or ""):match(
        "^cpu%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)"
    )
    if not softirq then
        return 0
    end
    local curr_stat = tonumber(user) + tonumber(nice) + tonumber(system)
        + tonumber(irq) + tonumber(softirq) + tonumber(iowait)
    local curr_idle = tonumber(idle)

    local prev_stat = tonumber(state.prev_stat)
    local prev_idle = tonumber(state.prev_idle)
    if not prev_stat or not prev_idle then
        prev_stat, prev_idle = curr_stat, curr_idle
    end

    local diff_stat = curr_stat - prev_stat
    local diff_idle = curr_idle - prev_idle
    state.prev_stat = curr_stat
    state.prev_idle = curr_idle

    local total = diff_stat + diff_idle
    local pct = total > 0 and (diff_stat / total) * 100 or 0
    return tonumber(string.format("%.1f", pct))
end

--- Reads current (averaged across policies) and max CPU clock speed in MHz
--- from cpufreq sysfs, pure Lua -- no awk, and guarded existence checks
--- throughout so a host with no cpufreq scaling driver (virtualized/cloud
--- CPUs, some ARM boards, CI runners) reads as (nil, nil) instead of crashing.
function M.read_cpu_clock_speed(cpu_sysfs_dir)
    cpu_sysfs_dir = cpu_sysfs_dir or "/sys/devices/system/cpu"
    local sum, count = 0, 0
    local cpufreq_dir = cpu_sysfs_dir .. "/cpufreq"
    if lfs.attributes(cpufreq_dir, "mode") == "directory" then
        for entry in lfs.dir(cpufreq_dir) do
            if entry:match("^policy") then
                local raw = read_first_line(cpufreq_dir .. "/" .. entry .. "/scaling_cur_freq")
                local khz = raw and tonumber(raw)
                if khz then
                    sum = sum + khz
                    count = count + 1
                end
            end
        end
    end
    local current_mhz = count > 0 and (sum / count / 1000) or nil

    local max_raw = read_first_line(cpu_sysfs_dir .. "/cpu0/cpufreq/cpuinfo_max_freq")
    local max_khz = max_raw and tonumber(max_raw)
    local max_mhz = max_khz and (max_khz / 1000) or nil

    return current_mhz, max_mhz
end

-- Checked in this order for every chip in the sensors -j output: GPU
-- readings before CPU proxies (see spec: "Explicit behavior change").
local TEMPERATURE_LABEL_PRIORITY = {"edge", "junction", "Tctl", "Tdie", "Package id"}

--- Parses `sensors -j` output (passed in as `sensors_json`, so this stays
--- testable without shelling out itself -- Task 11 wires the real
--- `io.popen("sensors -j 2>/dev/null")` call) into (temperature, fan_speed).
--- Malformed/empty input degrades to (nil, nil) rather than raising, since
--- this runs on every single poll.
function M.read_sensors(sensors_json)
    if not sensors_json or sensors_json == "" then
        return nil, nil
    end
    local ok, data = pcall(json.decode, sensors_json)
    if not ok or type(data) ~= "table" then
        return nil, nil
    end

    local temperature
    for _, wanted_label in ipairs(TEMPERATURE_LABEL_PRIORITY) do
        for _, chip in pairs(data) do
            if type(chip) == "table" then
                for label, entry in pairs(chip) do
                    if type(entry) == "table" and label:find(wanted_label, 1, true) then
                        for key, value in pairs(entry) do
                            if key:match("^temp%d+_input$") and type(value) == "number" then
                                temperature = math.floor(value)
                                break
                            end
                        end
                    end
                    if temperature then
                        break
                    end
                end
            end
            if temperature then
                break
            end
        end
        if temperature then
            break
        end
    end

    local fan_speed
    for _, chip in pairs(data) do
        if type(chip) == "table" and not fan_speed then
            for label, entry in pairs(chip) do
                -- Stop at the first match: without this the loop keeps walking
                -- a chip's remaining labels and the reported speed for a
                -- multi-fan chip depends on pairs() iteration order.
                if not fan_speed and type(entry) == "table" and label:match("^fan%d") then
                    for key, value in pairs(entry) do
                        if key:match("^fan%d+_input$") and type(value) == "number" then
                            fan_speed = math.floor(value)
                            break
                        end
                    end
                end
            end
        end
    end

    return temperature, fan_speed
end

local function clamp(value, low, high)
    if value < low then
        return low
    end
    if value > high then
        return high
    end
    return value
end

local locale_fahrenheit

local function locale_uses_fahrenheit()
    if locale_fahrenheit ~= nil then
        return locale_fahrenheit
    end
    local handle = io.popen("locale -k LC_MEASUREMENT 2>/dev/null")
    local line = handle and handle:read("*l") or nil
    if handle then
        handle:close()
    end
    locale_fahrenheit = line and line:match("^measurement=2") ~= nil or false
    return locale_fahrenheit
end

--- Formats a Celsius sensor reading according to LC_MEASUREMENT.
function M.format_temperature(value, fahrenheit)
    if value == nil or tostring(value) == "" or tostring(value) == "[N/A]" then
        return "N/A"
    end
    local numeric = tonumber(value)
    if not numeric then
        return tostring(value)
    end
    if fahrenheit == nil then
        fahrenheit = locale_uses_fahrenheit()
    end
    if fahrenheit then
        return string.format("%.0f°F", numeric * 9 / 5 + 32)
    end
    return string.format("%.0f°C", numeric)
end

--- Ported 1:1 from the bash version's map_floor: given a "threshold:value,
--- threshold:value, ..., default" spec string and a numeric value, returns
--- the value for the highest threshold the number clears, or the default.
function M.map_floor(spec, value)
    local pairs_list = {}
    for piece in (spec .. ","):gmatch("([^,]*),") do
        local trimmed = piece:gsub("^%s+", ""):gsub("%s+$", "")
        if trimmed ~= "" then
            pairs_list[#pairs_list + 1] = trimmed
        end
    end
    local default_val
    if pairs_list[#pairs_list] and not pairs_list[#pairs_list]:find(":") then
        default_val = pairs_list[#pairs_list]
        pairs_list[#pairs_list] = nil
    end
    local num = tonumber(tostring(value):match("^-?%d+"))
    for _, pair in ipairs(pairs_list) do
        local key, val = pair:match("^([^:]*):(.*)$")
        local key_num = key and tonumber(key)
        if num and key_num and num > key_num then
            return val
        end
    end
    return default_val or " "
end

--- Assembles the waybar custom-module JSON object -- text/tooltip/class/
--- percentage/alt -- from whatever fields a vendor branch (Tasks 9-11)
--- populated. Always produces valid JSON, even with no readings at all
--- (waybar's return-type:json reads this line by line; a malformed or empty
--- line breaks the whole module, the #2021/#2022 contract this preserves).
function M.generate_json(fields)
    local emoji = fields.emoji
    local temp_icon_lv = "85:, 65:, 45:, "
    local temp_status_lv = emoji and "85:🌋, 65:🔥, 45:☁️, ❄️" or "85:, 65:, 45:☁, ❄"
    local util_lv = "90:, 60:󰓅, 30:󰾅, 󰾆"
    local speedo_icon = M.map_floor(util_lv, fields.utilization or 0)
    local thermo_icon = M.map_floor(temp_icon_lv, fields.temperature or -999)
    local status_icon = M.map_floor(temp_status_lv, fields.temperature or -999)

    -- tonumber first: nvidia-smi answers "[N/A]" for query fields a card does
    -- not support, and nvidia_query passes raw CSV strings straight through.
    -- math.floor("[N/A]") raises, which would break the "always valid JSON"
    -- contract waybar's return-type:json depends on.
    local function value_or_na(value, suffix)
        local text = value == nil and "" or tostring(value)
        if text == "" or text == "[N/A]" then
            return "N/A"
        end
        return text .. (suffix or "")
    end

    local temp_num = tonumber(fields.temperature)
    local temp_val = temp_num and math.floor(temp_num) or nil
    local temp_clamped = temp_val and clamp(temp_val, 0, 999) or 0
    local temp_bucket = clamp(math.floor(temp_clamped / 5) * 5, 0, 100)
    local temp_class = "temp-" .. temp_bucket

    local util_num = tonumber(fields.utilization)
    local util_val = util_num and math.floor(util_num) or 0
    util_val = clamp(util_val, 0, 100)
    local util_bucket = math.floor(util_val / 10) * 10
    local util_class = "util-" .. util_bucket

    local temp_pct = clamp(temp_val or 0, 0, 100)

    local current_clock = fields.current_clock_speed or fields.core_clock
    local temperature_display = M.format_temperature(temp_val)
    local gpu_label = fields.primary_gpu or "Not found"
    if fields.vendor or fields.family then
        local label_parts = {}
        if fields.vendor then label_parts[#label_parts + 1] = fields.vendor end
        if fields.family then label_parts[#label_parts + 1] = fields.family end
        label_parts[#label_parts + 1] = gpu_label
        gpu_label = table.concat(label_parts, " ")
    end
    local tooltip = status_icon .. " " .. gpu_label
        .. "\n" .. thermo_icon .. " Temperature: " .. temperature_display
        .. "\n" .. speedo_icon .. " Utilization: " .. value_or_na(fields.utilization, "%")
        .. "\n Clock Speed: " .. value_or_na(current_clock) .. "/" .. value_or_na(fields.max_clock_speed) .. " MHz"
        .. "\n󱪉 Power Usage: " .. value_or_na(fields.power_usage) .. "/" .. value_or_na(fields.power_limit) .. " W"
    -- Battery discharge is deliberately excluded: this module reports GPU
    -- metrics, and system battery draw is not GPU-specific.
    return json.encode({
        text = thermo_icon .. " " .. temperature_display,
        tooltip = tooltip,
        class = {temp_class, util_class},
        percentage = temp_pct,
        alt = tostring(temp_bucket),
    })
end

--- NVIDIA vendor branch. Returns (fields, suspended). When `opts.is_nouveau`
--- (the open-source driver, which nvidia-smi cannot query), leaves vendor
--- metrics unavailable rather than substituting CPU or generic sensor data.
function M.nvidia_query(opts)
    local fields = {primary_gpu = "NVIDIA " .. tostring(opts.nvidia_gpu)}

    if opts.is_nouveau then
        return fields, false
    end

    if opts.tired then
        -- detect_vendor stores nvidia_addr straight from the
        -- /sys/bus/pci/devices directory entry name, which is already
        -- domain-qualified ("0000:01:00.0") -- prefixing another "0000:" here
        -- built a path that never exists, so suspend was never detected and
        -- --tired silently woke the GPU on every poll anyway.
        local runtime_status_path = opts.runtime_status_path
            or ((opts.pci_devices_dir or "/sys/bus/pci/devices") .. "/" .. tostring(opts.nvidia_addr) .. "/power/runtime_status")
        local status = read_first_line(runtime_status_path)
        if status and status:find("suspend") then
            return fields, true
        end
    end

    local nvidia_smi_cmd = opts.nvidia_smi_cmd or "nvidia-smi"
    local handle = io.popen(
        nvidia_smi_cmd
            .. " --query-gpu=temperature.gpu,utilization.gpu,clocks.current.graphics,clocks.max.graphics,power.draw,power.limit"
            .. " --format=csv,noheader,nounits 2>/dev/null"
    )
    local line = handle and handle:read("*l")
    if handle then
        handle:close()
    end
    if line then
        local values = {}
        for value in line:gmatch("[^,]+") do
            values[#values + 1] = value:gsub("^%s+", ""):gsub("%s+$", "")
        end
        fields.temperature = values[1]
        fields.utilization = values[2]
        fields.current_clock_speed = values[3]
        fields.max_clock_speed = values[4]
        fields.power_usage = values[5]
        fields.power_limit = values[6]
    end
    return fields, false
end

-- Same helper as #1901/PR #2060's altab.lua/batterynotify.lua/dconf.lua: a
-- lone "'...'" wrap doesn't survive an apostrophe inside the path itself.
local function shell_quote(arg)
    arg = tostring(arg)
    arg = arg:gsub("'", "'\\''")
    return "'" .. arg .. "'"
end

--- AMD vendor branch. Parses amdgpu.py's JSON (see Configs/.local/lib/hyde/
--- amdgpu.py) with luautils.json instead of `jq`+`sed`. Falls back to the
--- no substitute values whenever the output isn't the expected object --
--- covers "No AMD GPUs detected." (amdgpu.py's own
--- explicit no-hardware message) *and* any of amdgpu.py's exception-branch
--- error strings, which the bash version's two-literal-substring check did
--- not (it would have tried to jq-parse those as JSON).
function M.amd_query(opts)
    local fields = {primary_gpu = "AMD " .. tostring(opts.amdgpu_gpu)}

    local ok, decoded = pcall(json.decode, opts.amdgpu_output or "")
    if ok and type(decoded) == "table" and decoded["GPU Temperature"] then
        -- Each key guarded separately: a partial object (only some keys set)
        -- must degrade to a missing field rather than index nil.
        fields.temperature = decoded["GPU Temperature"]:gsub("°C", "")
        fields.utilization = decoded["GPU Load"] and decoded["GPU Load"]:gsub("%%", "") or nil
        fields.core_clock = decoded["GPU Core Clock"]
            and decoded["GPU Core Clock"]:gsub(" GHz", ""):gsub(" MHz", "")
            or nil
        fields.power_usage = decoded["GPU Power Usage"] and decoded["GPU Power Usage"]:gsub(" Watts", "") or nil
        return fields
    end

    return fields
end

--- Parses the normalized JSON emitted by lact_gpuinfo.py. LACT is the sole
--- runtime source for GPU metrics; an unavailable daemon yields empty fields
--- so generate_json renders N/A instead of substituting CPU data.
function M.lact_query(output)
    local ok, decoded = pcall(json.decode, output or "")
    if not ok or type(decoded) ~= "table" or decoded.error then
        return {primary_gpu = "Not found"}
    end
    return decoded
end

local argparse = require("luautils.argparse")

local VENDOR_STAT_KEY = {nvidia = "nvidia_enable", amd = "amd_enable", intel = "intel_enable"}

--- CLI entry point. `opts` (all optional, used by tests to avoid touching
--- the real machine): print_fn, state_suffix_override, detect_vendor_opts,
--- lact_cmd, lact_output, state_suffix_override, detect_vendor_opts.
function M.cli_main(argv, opts)
    opts = opts or {}
    local print_fn = opts.print_fn or print
    -- Separate from print_fn on purpose: a cold start (no state file yet)
    -- reaches both this diagnostic *and* the regular generate_json print
    -- below in the same invocation. Waybar's return-type:json reads stdout
    -- line by line, so mixing the two on one stream is exactly the
    -- #2021/#2022 bug this rewrite must not reintroduce -- this always goes
    -- to stderr, never through print_fn/stdout.
    local warn_fn = opts.warn_fn or function(s) io.stderr:write(s, "\n") end

    local parser = argparse("gpuinfo", "GPU/CPU info for the waybar custom/gpuinfo module")
    parser:option("--use", "Only call the specified GPU"):argname("GPU")
    parser:option("--stat", "Report whether GPU is enabled (amd, intel, nvidia)"):argname("GPU")
    parser:flag("--toggle", "Toggle available GPU")
    parser:flag("--reset", "Remove & restart all detection")
    parser:flag("--tired", "Do not query nvidia-smi if the GPU is in suspend mode")
    parser:flag("--emoji", "Use emoji instead of glyphs")
    parser:flag("--startup", "Set this GPU at startup (used with --use)")
    local args = parser:parse(argv)

    -- Validated before it becomes part of a filesystem path below: an
    -- unchecked --use value (e.g. "../../../home/user/.config/foo") would
    -- otherwise let a cold start read/write an arbitrary JSON file outside
    -- the runtime dir once concatenated into the state suffix.
    if args.use and not VENDOR_STAT_KEY[args.use] then
        print_fn("Error: Invalid argument for --use. Use amd, intel, or nvidia.")
        return 1
    end

    local suffix = opts.state_suffix_override or (args.startup and "" or (args.use and ("_" .. args.use) or ""))
    local state = M.read_state(suffix)

    -- Gated on "has detection ever run", not on "did it find anything": on
    -- hardware with none of the three recognized vendors (a VM's virtio-gpu,
    -- say) all three enables stay false forever, so the old
    -- `not has_any_vendor` condition re-walked /sys/bus/pci/devices, rewrote
    -- the state file and re-emitted the "Initialized:" warning on every poll.
    if args.reset or not state.detected then
        -- --reset starts from a genuinely empty state, matching the bash
        -- version's `rm -fr` of the state file (its --help still advertises
        -- that): stale tired/emoji flags from an earlier invocation must not
        -- survive. Flags passed on *this* invocation are applied just below.
        if args.reset then
            state = {}
        end
        local detected = M.detect_vendor(opts.detect_vendor_opts)
        state.detected = true
        state.nvidia_enable = detected.nvidia
        state.amd_enable = detected.amd
        state.intel_enable = detected.intel
        state.nvidia_gpu = detected.nvidia_gpu
        state.nvidia_nouveau = detected.nvidia_nouveau
        state.amd_gpu = detected.amd_gpu
        state.intel_gpu = detected.intel_gpu
        state.nvidia_addr = detected.nvidia_addr
        state.amd_addr = detected.amd_addr
        state.intel_addr = detected.intel_addr
        -- The set of vendors --toggle/--use may switch between, recorded once
        -- here because the *_enable keys below get overwritten with the
        -- *selection* on every toggle (see M.toggle's note).
        state.available = {}
        for _, vendor in ipairs(VENDOR_ORDER) do
            if detected[vendor] then
                state.available[#state.available + 1] = vendor
            end
        end
        if detected.nvidia then
            state.priority = "nvidia"
        elseif detected.amd then
            state.priority = "amd"
        elseif detected.intel then
            state.priority = "intel"
        end
        M.write_state(suffix, state)
        warn_fn(
            "Initialized: nvidia="
                .. tostring(detected.nvidia)
                .. " amd="
                .. tostring(detected.amd)
                .. " intel="
                .. tostring(detected.intel)
        )
    end

    if args.tired then
        state.tired = true
    end
    if args.emoji then
        state.emoji = true
    end

    if args.toggle then
        local next_vendor, err = M.toggle(state, nil)
        if not next_vendor then
            print_fn("Error: " .. err)
            return 1
        end
        M.write_state(suffix, state)
        print_fn("Sensor: " .. next_vendor .. " GPU")
        return 0
    end

    if args.use then
        local next_vendor, err = M.toggle(state, args.use)
        if not next_vendor then
            print_fn("Error: " .. err)
            M.write_state(suffix, state)
            return 1
        end
        M.write_state(suffix, state)
    end

    if args.stat then
        local key = VENDOR_STAT_KEY[args.stat]
        if not key then
            print_fn("Error: Invalid argument for --stat. Use amd, intel, or nvidia.")
            return 1
        end
        if state[key] then
            print_fn(key .. ": true")
            return 0
        end
        print_fn("GPU not enabled.")
        return 1
    end

    local lact_output = ""
    local skip_lact = false
    if state.tired and state.priority == "nvidia" and state.nvidia_addr then
        local status_path = "/sys/bus/pci/devices/" .. tostring(state.nvidia_addr) .. "/power/runtime_status"
        local runtime_status = read_first_line(status_path)
        skip_lact = runtime_status and runtime_status:find("suspend") ~= nil or false
    end
    if not skip_lact then
        lact_output = opts.lact_output
    end
    if not skip_lact and not lact_output then
        local lact_cmd = opts.lact_cmd or (root .. "lact_gpuinfo.py")
        local vendor = state.priority or ""
        local handle = io.popen(shell_quote(lact_cmd) .. " " .. shell_quote(vendor) .. " 2>/dev/null")
        lact_output = handle and handle:read("*a") or ""
        if handle then
            handle:close()
        end
    end
    local fields = M.lact_query(lact_output)
    fields.emoji = state.emoji

    M.write_state(suffix, state)
    print_fn(M.generate_json(fields))
    return 0
end

local arg_count = #arg
local vararg_count = select("#", ...)
if arg_count == vararg_count and (vararg_count == 0 or select(1, ...) == arg[1]) then
    os.exit(M.cli_main(arg))
end

return M

#!/usr/bin/env lua
-- Standalone LACT Waybar module. Deliberately independent from gpuinfo.sh/
-- gpuinfo.lua: no shared file, no shared state, no require("gpuinfo") --
-- see the architecture note for why (hyde-shell resolves a bare "gpuinfo"
-- command to a *.lua file before *.sh, so shipping any file named
-- gpuinfo.lua here would silently replace the existing, untouched
-- gpuinfo.sh for every custom/gpuinfo* module).
local root = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = package.path .. ";" .. root .. "?.lua;" .. root .. "?/init.lua;"
require("luautils.init")

local json = require("luautils.json")

local M = {}

-- Fixed marker while custom/lact is experimental, so it can run side by side
-- with custom/gpuinfo without the two being mistaken for each other. Remove
-- once LACT is no longer considered a test/comparison module.
local TEST_MARKER = "🧪"

-- Same helper as #1901/PR #2060's altab.lua/batterynotify.lua/dconf.lua: a
-- lone "'...'" wrap doesn't survive an apostrophe inside the path itself.
local function shell_quote(value)
    value = tostring(value)
    value = value:gsub("'", "'\\''")
    return "'" .. value .. "'"
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

--- Path to lact.lua's own state file. Only ever holds the --emoji
--- preference -- there is no vendor/priority state, since generate_json
--- always reports every GPU LACT knows about (no toggling between them).
function M.state_path()
    local runtime_dir = os.getenv("XDG_RUNTIME_DIR")
    if runtime_dir and runtime_dir ~= "" then
        return runtime_dir .. "/hyde-lact.json"
    end
    -- No XDG_RUNTIME_DIR (already user-scoped when set): fall back to /tmp,
    -- scoped by uid so two users on the same machine don't collide.
    local handle = io.popen("id -u 2>/dev/null")
    local uid = handle and handle:read("*l") or "0"
    if handle then
        handle:close()
    end
    return "/tmp/hyde-" .. (uid ~= "" and uid or "0") .. "-lact.json"
end

--- Always returns a table -- a missing or corrupt state file degrades to
--- {} rather than erroring, same contract as gpuinfo.lua's read_state.
function M.read_state()
    local f = io.open(M.state_path(), "r")
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

function M.write_state(state)
    local f = io.open(M.state_path(), "w")
    if not f then
        return false
    end
    f:write(json.encode(state))
    f:close()
    return true
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

--- Formats a Celsius sensor reading according to LC_MEASUREMENT, same as
--- the (never-merged) gpuinfo.lua rewrite's version of this function.
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

--- Ported 1:1 from gpuinfo.lua's map_floor: given a "threshold:value,
--- threshold:value, ..., default" spec string and a numeric value, returns
--- the value for the highest threshold the number clears, or the default.
function M.map_floor(spec, value)
    local items = {}
    for item in spec:gmatch("[^,]+") do
        items[#items + 1] = item:match("^%s*(.-)%s*$")
    end
    local default_val
    if items[#items] and not items[#items]:find(":") then
        default_val = table.remove(items)
    end
    local num = tonumber(value)
    for _, item in ipairs(items) do
        local key, val = item:match("^([^:]+):(.*)$")
        local key_num = key and tonumber(key)
        if num and key_num and num > key_num then
            return val
        end
    end
    return default_val or " "
end

-- GPU-realistic temperature-to-color bands, deliberately not copy-pasted
-- from the CPU scale in styles/classes/cpuinfo.css: modern GPUs commonly
-- run 65-80°C under completely normal load (many NVIDIA cards are designed
-- to sit near ~83-90°C without issue, AMD junction temps can normally reach
-- ~100-110°C), so a scale that turns orange at 60°C (fine for CPUs) would
-- flag routine GPU load as a warning. Colors are applied inline per GPU via
-- Pango markup (same mechanism as sensorsinfo.py/mediaplayer.py already use
-- in this repo) rather than a shared Waybar CSS class, so multiple GPUs in
-- one tooltip/bar can each show their own real temperature color instead of
-- one bucket winning for the whole widget.
local TEMP_COLOR_BANDS = {
    {95, "#8b0000"}, -- critical
    {85, "#ff4500"}, -- hot
    {75, "#ffa500"}, -- warm, still normal for many GPUs
    {45, ""}, -- neutral / normal operating range
}
local TEMP_COLOR_COLD = "#4169e1"

local function temp_color(value)
    local numeric = tonumber(value)
    if not numeric then
        return nil
    end
    for _, band in ipairs(TEMP_COLOR_BANDS) do
        if numeric >= band[1] then
            return band[2]
        end
    end
    return TEMP_COLOR_COLD
end

local function colorize(text, color)
    if color and color ~= "" then
        return "<span color='" .. color .. "'>" .. text .. "</span>"
    end
    return text
end

-- tonumber first: LACT can answer null/missing for a field the driver
-- doesn't expose, and a malformed daemon response could pass a raw string
-- straight through. Never let a bad value break the "always valid JSON"
-- contract waybar's return-type:json depends on.
local function value_or_na(value, suffix)
    local text = value == nil and "" or tostring(value)
    if text == "" or text == "[N/A]" or text == "null" then
        return "N/A"
    end
    return text .. (suffix or "")
end

--- Parses lact_gpuinfo.py's stdout. Always returns a list (possibly empty)
--- of device field-tables -- malformed JSON, a missing/wrong-typed
--- "devices" key, or a non-table entry inside it all degrade to "skip it"
--- rather than raising, so one bad device (or a fully unavailable daemon)
--- never takes down the whole poll.
function M.parse_lact_output(output)
    local ok, decoded = pcall(json.decode, output or "")
    if not ok or type(decoded) ~= "table" or type(decoded.devices) ~= "table" then
        return {}
    end
    local devices = {}
    for _, device in ipairs(decoded.devices) do
        if type(device) == "table" then
            devices[#devices + 1] = device
        end
    end
    return devices
end

--- Assembles the waybar custom/lact JSON object from every GPU LACT
--- reported (Task per the 2026-09-13 "combined display" decision: no
--- toggling between vendors, every detected GPU is shown at once). Always
--- produces valid JSON, even with zero devices or a device missing every
--- field.
function M.generate_json(devices, opts)
    opts = opts or {}
    devices = type(devices) == "table" and devices or {}

    -- Fixed icons, not temperature-mood-varying like gpuinfo's: the color
    -- already signals "how hot" (see TEMP_COLOR_BANDS), so the icon here
    -- only needs to say "this is a temperature/clock/fan reading". Written
    -- as \u{} escapes rather than typed glyphs -- a literal Nerd Font
    -- Private Use Area character in this file's source has silently come
    -- out blank before (caught in review comparing the live tooltip against
    -- what glyph.db says these codepoints render as).
    local thermo_icon_fixed = opts.emoji and "🌡️" or "\u{f050f}" -- md-thermometer
    local chip_icon = "\u{f061a}" -- md-chip
    local fan_icon = "\u{f0210}" -- md-fan
    local util_lv = "90:, 60:󰓅, 30:󰾅, 󰾆"

    if #devices == 0 then
        return json.encode({
            text = TEST_MARKER .. " N/A",
            tooltip = TEST_MARKER .. " LACT (Testphase)\nNo GPU reported by lactd",
            class = {"temp-0", "util-0"},
            percentage = 0,
            alt = "0",
        })
    end

    local bar_parts = {}
    local tooltip_blocks = {}
    local hottest_temp

    for index, fields in ipairs(devices) do
        fields = type(fields) == "table" and fields or {}

        local temp_num = tonumber(fields.temperature)
        local temp_val = temp_num and math.floor(temp_num) or nil
        local temp_display = M.format_temperature(temp_val)
        local color = temp_val and temp_color(clamp(temp_val, -999, 999)) or nil

        bar_parts[#bar_parts + 1] = colorize(temp_display, color)

        if temp_val then
            local temp_clamped = clamp(temp_val, 0, 999)
            if not hottest_temp or temp_clamped > hottest_temp then
                hottest_temp = temp_clamped
            end
        end

        local gpu_label = fields.primary_gpu or ("GPU " .. tostring(index))
        if fields.vendor or fields.family then
            local label_parts = {}
            if fields.vendor then
                label_parts[#label_parts + 1] = tostring(fields.vendor)
            end
            if fields.family then
                label_parts[#label_parts + 1] = tostring(fields.family)
            end
            label_parts[#label_parts + 1] = gpu_label
            gpu_label = table.concat(label_parts, " ")
        end

        local speedo_icon = M.map_floor(util_lv, tonumber(fields.utilization) or 0)
        local current_clock = fields.current_clock_speed or fields.core_clock

        local block = {
            gpu_label,
            thermo_icon_fixed .. " Temperature: " .. colorize(temp_display, color),
            speedo_icon .. " Utilization: " .. value_or_na(fields.utilization, "%"),
            chip_icon .. " Clock Speed: " .. value_or_na(current_clock) .. "/" .. value_or_na(fields.max_clock_speed) .. " MHz",
            "\u{f1a89}" .. " Power Usage: " .. value_or_na(fields.power_usage) .. "/" .. value_or_na(fields.power_limit) .. " W",
        }
        -- Only when the daemon actually reported a fan reading (present but
        -- 0 RPM is a real, meaningful "fan is off" answer on some cards, not
        -- a missing value) -- unlike temperature/clock/power there is no
        -- sensible N/A fallback line to show for a GPU with no fan sensor
        -- at all (blower-less cards, most laptop iGPUs).
        if fields.fan_speed ~= nil then
            block[#block + 1] = fan_icon .. " Fan Speed: " .. value_or_na(fields.fan_speed, " RPM")
        end

        tooltip_blocks[#tooltip_blocks + 1] = table.concat(block, "\n")
    end

    local temp_pct = clamp(hottest_temp or 0, 0, 100)
    local temp_bucket = clamp(math.floor(temp_pct / 5) * 5, 0, 100)

    return json.encode({
        text = TEST_MARKER .. " " .. table.concat(bar_parts, "/"),
        tooltip = TEST_MARKER .. " LACT (Testphase)\n\n" .. table.concat(tooltip_blocks, "\n\n"),
        class = {"temp-" .. temp_bucket},
        percentage = temp_pct,
        alt = tostring(temp_bucket),
    })
end

--- CLI entry point. `opts` (all optional, used by tests to avoid touching
--- the real machine): print_fn, warn_fn, state, lact_cmd, lact_output.
function M.cli_main(argv, opts)
    opts = opts or {}
    local print_fn = opts.print_fn or print
    local warn_fn = opts.warn_fn or function(s) io.stderr:write(s, "\n") end

    local state = opts.state or M.read_state()
    local reset = false
    local emoji_flag = false

    for _, a in ipairs(argv) do
        if a == "--reset" then
            reset = true
        elseif a == "--emoji" then
            emoji_flag = true
        elseif a ~= nil and a ~= "" then
            warn_fn("Unknown argument: " .. tostring(a))
        end
    end

    if reset then
        state = {}
    end
    if emoji_flag then
        state.emoji = true
    end
    if reset or emoji_flag then
        M.write_state(state)
    end

    local lact_output = opts.lact_output
    if not lact_output then
        local lact_cmd = opts.lact_cmd or (root .. "lact_gpuinfo.py")
        local handle = io.popen(shell_quote(lact_cmd) .. " 2>/dev/null")
        lact_output = handle and handle:read("*a") or ""
        if handle then
            handle:close()
        end
    end

    local devices = M.parse_lact_output(lact_output)
    print_fn(M.generate_json(devices, {emoji = state.emoji}))
    return 0
end

local arg_count = #arg
local vararg_count = select("#", ...)
if arg_count == vararg_count and (vararg_count == 0 or select(1, ...) == arg[1]) then
    os.exit(M.cli_main(arg))
end

return M

local root = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = root .. "../../Configs/.local/lib/hyde/?.lua;" .. package.path
local lact = require("lact")
local json = require("luautils.json")

local failures = 0
local function check(condition, message)
    if not condition then
        failures = failures + 1
        print("    fail: " .. message)
    end
end

local work_dir = os.getenv("LACT_TEST_WORK_DIR") or os.getenv("GPUINFO_TEST_WORK_DIR")
assert(work_dir, "LACT_TEST_WORK_DIR must be set by the test wrapper")

-- format_temperature: locale-independent when a fahrenheit flag is passed
-- explicitly (real usage lets it fall back to `locale -k LC_MEASUREMENT`,
-- which these unit tests must not depend on).
check(lact.format_temperature(0, true) == "32°F", "Fahrenheit conversion was incorrect")
check(lact.format_temperature(100, false) == "100°C", "Celsius formatting was incorrect")
check(lact.format_temperature(nil) == "N/A", "a nil temperature did not render as N/A")
check(lact.format_temperature("[N/A]") == "N/A", "a literal [N/A] string did not render as N/A")
check(lact.format_temperature("not-a-number", false) == "not-a-number", "a non-numeric string should pass through unchanged")

-- map_floor: same threshold-selection contract as gpuinfo.lua's version.
check(lact.map_floor("85:hot, 45:mid, cold", 90) == "hot", "map_floor did not pick the highest cleared threshold")
check(lact.map_floor("85:hot, 45:mid, cold", 50) == "mid", "map_floor did not pick the middle threshold")
check(lact.map_floor("85:hot, 45:mid, cold", 0) == "cold", "map_floor did not fall back to the default")
check(lact.map_floor("85:hot, 45:mid, cold", nil) == "cold", "map_floor did not degrade a nil value to the default")

-- parse_lact_output: never raises, always returns a list.
check(#lact.parse_lact_output("") == 0, "empty output did not degrade to zero devices")
check(#lact.parse_lact_output("not json at all") == 0, "garbage output did not degrade to zero devices")
check(#lact.parse_lact_output("null") == 0, "a JSON null did not degrade to zero devices")
check(#lact.parse_lact_output('{"devices": "not-a-list"}') == 0, "a non-list devices field did not degrade to zero devices")
check(#lact.parse_lact_output('{"no_devices_key": true}') == 0, "a missing devices key did not degrade to zero devices")
local mixed = lact.parse_lact_output('{"devices": [{"primary_gpu": "Real GPU"}, "garbage", 42, null]}')
check(#mixed == 1 and mixed[1].primary_gpu == "Real GPU", "a devices list with non-table entries mixed in was not filtered down to the real device(s)")

-- generate_json: zero devices must still be valid, well-formed JSON.
local empty_json = lact.generate_json({})
local ok0, decoded0 = pcall(json.decode, empty_json)
check(ok0, "generate_json with zero devices did not produce valid JSON")
check(ok0 and decoded0.text:find("N/A", 1, true) ~= nil, "zero devices did not render as N/A in the bar text")
check(ok0 and decoded0.tooltip:find("LACT", 1, true) ~= nil, "the experimental-test-phase marker was missing from the tooltip")

-- generate_json: nil/non-table devices argument must degrade the same way,
-- not raise.
local ok_nil, nil_json = pcall(lact.generate_json, nil)
check(ok_nil, "generate_json(nil) raised instead of degrading to zero devices")
local ok0b, decoded0b = pcall(json.decode, ok_nil and nil_json or "")
check(ok0b and decoded0b.percentage == 0, "generate_json(nil) did not produce the zero-device percentage")

-- generate_json: one fully-populated device.
local full = lact.generate_json({
    {
        primary_gpu = "Radeon RX 7800",
        vendor = "AMD",
        family = "RDNA3",
        temperature = 62,
        utilization = 45,
        current_clock_speed = 1800,
        max_clock_speed = 2600,
        power_usage = 180,
        power_limit = 250,
    },
})
local ok1, decoded1 = pcall(json.decode, full)
check(ok1, "generate_json with a full field set did not produce valid JSON")
check(ok1 and decoded1.tooltip:find("AMD RDNA3 Radeon RX 7800", 1, true) ~= nil, "vendor/family/name were not combined in the tooltip label")
check(ok1 and decoded1.tooltip:find("1800/2600 MHz", 1, true) ~= nil, "clock speed segment was missing/wrong")
check(ok1 and decoded1.tooltip:find("180/250 W", 1, true) ~= nil, "power usage segment was missing/wrong")
-- 62°C is normal GPU operating temperature under the recalibrated scale
-- (see the TEMP_COLOR_BANDS comment): it must stay uncolored, not just
-- "any color".
check(ok1 and not decoded1.text:find("<span", 1, true), "62°C (normal GPU load) should not be colorized")
check(ok1 and decoded1.percentage == 62, "percentage did not reflect the single device's temperature")

-- A genuinely hot reading (above the recalibrated "normal" band) must be
-- colorized -- this is the whole point of per-GPU inline Pango coloring.
local hot = lact.generate_json({{primary_gpu = "Toasty GPU", temperature = 90}})
local okh, decodedh = pcall(json.decode, hot)
check(okh, "generate_json for a hot GPU did not produce valid JSON")
check(okh and decodedh.text:find("<span color=", 1, true) ~= nil, "a 90°C GPU (hot under the recalibrated scale) was not colorized")

-- generate_json: missing fields on an otherwise real device must render as
-- N/A, not raise or produce "nil" text.
local sparse = lact.generate_json({{primary_gpu = "Bare GPU"}})
local ok2, decoded2 = pcall(json.decode, sparse)
check(ok2, "generate_json with a mostly-empty device did not produce valid JSON")
check(ok2 and decoded2.tooltip:find("Temperature: N/A", 1, true) ~= nil, "a missing temperature was not rendered as N/A")
check(ok2 and decoded2.tooltip:find("Utilization: N/A", 1, true) ~= nil, "a missing utilization was not rendered as N/A")
check(ok2 and decoded2.tooltip:find("Clock Speed: N/A/N/A MHz", 1, true) ~= nil, "missing clocks were not rendered as N/A")
check(ok2 and decoded2.tooltip:find("Power Usage: N/A/N/A W", 1, true) ~= nil, "missing power values were not rendered as N/A")
check(ok2 and not decoded2.text:find("<span", 1, true), "a device with no real temperature should not be colorized")

-- generate_json: out-of-spec numeric input (negative, absurdly high,
-- non-numeric string) must clamp/degrade instead of raising or producing an
-- invalid percentage.
local bad_ok, bad_json = pcall(lact.generate_json, {
    {primary_gpu = "Glitchy GPU", temperature = -50, utilization = "[N/A]"},
})
check(bad_ok, "a negative temperature raised instead of clamping")
local ok3, decoded3 = pcall(json.decode, bad_ok and bad_json or "")
check(ok3 and decoded3.percentage == 0, "a negative temperature was not clamped to 0%%: got " .. tostring(ok3 and decoded3.percentage))

local huge_ok, huge_json = pcall(lact.generate_json, {
    {primary_gpu = "Absurd GPU", temperature = 999999},
})
check(huge_ok, "an absurdly high temperature raised instead of clamping")
local ok4, decoded4 = pcall(json.decode, huge_ok and huge_json or "")
check(ok4 and decoded4.percentage == 100, "an absurd temperature was not clamped to 100%%: got " .. tostring(ok4 and decoded4.percentage))

local nonnum_ok = pcall(lact.generate_json, {
    {primary_gpu = "Stringy GPU", temperature = "not-a-number"},
})
check(nonnum_ok, "a non-numeric temperature string raised instead of degrading to N/A")

-- generate_json: multiple GPUs are combined, not toggled between -- the
-- 2026-09-13 "combined display" decision this module exists to implement.
local multi = lact.generate_json({
    {primary_gpu = "Hot GPU", temperature = 90},
    {primary_gpu = "Cool GPU", temperature = 35},
})
local ok5, decoded5 = pcall(json.decode, multi)
check(ok5, "generate_json with multiple devices did not produce valid JSON")
check(ok5 and decoded5.text:find("/", 1, true) ~= nil, "multiple GPUs were not joined with a separator in the bar text")
local span_count = 0
if ok5 then
    local _, count = decoded5.text:gsub("<span color=", "")
    span_count = count
end
check(span_count == 2, "each GPU in a multi-GPU bar should carry its own independent color span, got " .. tostring(span_count))
check(ok5 and decoded5.tooltip:find("Hot GPU", 1, true) ~= nil and decoded5.tooltip:find("Cool GPU", 1, true) ~= nil, "both GPUs' names were not present in the tooltip")
check(ok5 and decoded5.percentage == 90, "the hottest GPU should drive the overall percentage/class bucket, got " .. tostring(ok5 and decoded5.percentage))

-- generate_json: a garbage (non-table) entry inside an otherwise valid
-- devices list must be skipped, not crash the whole render.
local garbage_ok, garbage_json = pcall(lact.generate_json, {
    {primary_gpu = "Real GPU", temperature = 50},
    "not-a-device-table",
})
check(garbage_ok, "a non-table device entry raised instead of being skipped")
local ok6 = garbage_ok and pcall(json.decode, garbage_json)
check(ok6, "a devices list with a garbage entry mixed in did not produce valid JSON")

-- cli_main end to end: cold call with a fixed lact_output produces exactly
-- one JSON line, and --emoji/--reset persist/clear across invocations via
-- the real state file (isolated to this test's own XDG_RUNTIME_DIR).
os.remove(lact.state_path())
local lines = {}
local code = lact.cli_main({}, {
    print_fn = function(s) lines[#lines + 1] = s end,
    lact_output = '{"devices":[{"primary_gpu":"Test GPU","temperature":55}]}',
})
check(code == 0, "a normal cli_main call did not return 0")
check(#lines == 1, "cli_main printed something other than exactly one line: " .. tostring(#lines))
local ok7 = pcall(json.decode, lines[1] or "")
check(ok7, "cli_main's single printed line was not valid JSON")

lact.cli_main({"--emoji"}, {print_fn = function() end, lact_output = "{}"})
check(lact.read_state().emoji == true, "--emoji did not persist across invocations")

lact.cli_main({"--reset"}, {print_fn = function() end, lact_output = "{}"})
check(not lact.read_state().emoji, "--reset did not clear a previously-set --emoji flag")

-- An unrecognized flag must warn, not crash the render.
local warn_lines = {}
local unknown_ok = pcall(lact.cli_main, {"--bogus"}, {
    print_fn = function() end,
    warn_fn = function(s) warn_lines[#warn_lines + 1] = s end,
    lact_output = "{}",
})
check(unknown_ok, "an unrecognized CLI flag raised instead of warning and continuing")
check(#warn_lines > 0, "an unrecognized CLI flag was silently ignored instead of warned about")

os.remove(lact.state_path())

os.exit(failures == 0 and 0 or 1)

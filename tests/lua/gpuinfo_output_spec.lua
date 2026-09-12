local root = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = root .. "../../Configs/.local/lib/hyde/?.lua;" .. package.path
local gpuinfo = require("gpuinfo")
local json = require("luautils.json")

local failures = 0
local function check(condition, message)
    if not condition then
        failures = failures + 1
        print("    fail: " .. message)
    end
end

-- generate_json must always produce something json.decode accepts -- this is
-- the exact #2021/#2022 contract (waybar reads this line by line as JSON).
local minimal = gpuinfo.generate_json({primary_gpu = "Not found"})
local ok, decoded = pcall(json.decode, minimal)
check(ok, "generate_json with no readings at all did not produce valid JSON: " .. tostring(minimal))
check(ok and decoded.percentage ~= nil, "percentage was missing/null with no temperature reading")

-- A full set of readings produces the documented tooltip segments.
local full = gpuinfo.generate_json({
    primary_gpu = "AMD Radeon RX 7800",
    temperature = 62,
    utilization = 45.0,
    fan_speed = 1400,
    current_clock_speed = 1800,
    max_clock_speed = 3600,
    power_usage = 120,
    power_limit = 200,
    power_discharge = 15.5,
})
local ok2, decoded2 = pcall(json.decode, full)
check(ok2, "generate_json with a full field set did not produce valid JSON")
check(decoded2.text:find(gpuinfo.format_temperature(62), 1, true), "text field did not include the temperature")
check(decoded2.tooltip:find("45"), "tooltip did not include utilization")
check(decoded2.tooltip:find("1800/3600 MHz"), "tooltip did not include the clock speed segment in the documented format")
check(decoded2.tooltip:find("120/200 W"), "tooltip did not include the power usage/limit segment")
check(not decoded2.tooltip:find("Power Discharge"), "GPU tooltip included non-GPU battery discharge")
check(decoded2.class[1] == "temp-60", "temperature class bucket was wrong: got " .. tostring(decoded2.class[1]))
check(decoded2.class[2] == "util-40", "utilization class bucket was wrong: got " .. tostring(decoded2.class[2]))
check(decoded2.percentage == 62, "percentage did not mirror the temperature")

-- core_clock (the AMD-branch-only single-value clock reading) is a separate
-- tooltip line from current/max clock speed, and the two must not both
-- appear -- mirrors the bash version's two separate tooltip_parts entries
-- under the same key.
local core_clock_only = gpuinfo.generate_json({primary_gpu = "AMD Radeon", core_clock = 1500})
local ok3, decoded3 = pcall(json.decode, core_clock_only)
check(ok3, "generate_json with only core_clock did not produce valid JSON")
check(decoded3.tooltip:find("1500/N/A MHz"), "core_clock alone did not appear in the tooltip")

-- Out-of-spec: a negative or absurd temperature (a sensor glitch) must still
-- clamp into a valid bucket/percentage instead of producing an out-of-range
-- or negative "percentage" waybar can't render sensibly.
local negative = gpuinfo.generate_json({primary_gpu = "x", temperature = -5})
local ok4, decoded4 = pcall(json.decode, negative)
check(ok4, "a negative temperature broke JSON generation")
check(decoded4.percentage == 0, "a negative temperature was not clamped to 0%%: got " .. tostring(decoded4.percentage))

local huge = gpuinfo.generate_json({primary_gpu = "x", temperature = 5000})
local ok5, decoded5 = pcall(json.decode, huge)
check(ok5, "an absurdly high temperature broke JSON generation")
check(decoded5.percentage == 100, "an absurd temperature was not clamped to 100%%: got " .. tostring(decoded5.percentage))

-- Out-of-spec: nvidia-smi answers the literal string "[N/A]" for query fields
-- a card does not support, and nvidia_query passes raw CSV values straight
-- through. math.floor("[N/A]") raises, which would take the whole waybar
-- module's JSON line down -- these have to read as "no reading" instead.
local na_ok, na = pcall(gpuinfo.generate_json, {
    primary_gpu = "NVIDIA GeForce",
    temperature = "[N/A]",
    utilization = "[N/A]",
})
check(na_ok, "a non-numeric nvidia-smi reading raised instead of degrading: " .. tostring(na))
local ok6, decoded6 = pcall(json.decode, na_ok and na or "")
check(ok6, "a non-numeric nvidia-smi reading did not produce valid JSON")
check(ok6 and decoded6.percentage == 0, "a non-numeric temperature did not fall back to 0%%: got " .. tostring(ok6 and decoded6.percentage))
check(ok6 and decoded6.class[2] == "util-0", "a non-numeric utilization did not fall back to the util-0 bucket: got " .. tostring(ok6 and decoded6.class[2]))

-- A numeric *string* (the normal nvidia-smi case) must keep working unchanged.
local str_ok, str_json = pcall(gpuinfo.generate_json, {primary_gpu = "x", temperature = "62", utilization = "45"})
local ok7, decoded7 = pcall(json.decode, str_ok and str_json or "")
check(ok7 and decoded7.percentage == 62, "a numeric-string temperature stopped being read: got " .. tostring(ok7 and decoded7.percentage))
check(gpuinfo.format_temperature(0, true) == "32°F", "Fahrenheit conversion was incorrect")
check(gpuinfo.format_temperature(100, false) == "100°C", "Celsius formatting was incorrect")
local lact = gpuinfo.lact_query('{"primary_gpu":"Intel Arc","vendor":"Intel","family":"Battlemage","temperature":54,"utilization":37,"current_clock_speed":1850,"max_clock_speed":2850,"power_usage":72.4,"power_limit":null}')
check(lact.primary_gpu == "Intel Arc" and lact.family == "Battlemage", "LACT identity was not parsed")
check(lact.utilization == 37 and lact.power_limit == nil, "LACT metrics were not parsed")
local lact_json = gpuinfo.generate_json(lact)
check(lact_json:find("Intel Battlemage Intel Arc"), "LACT vendor and family were not shown")

local missing = gpuinfo.generate_json({primary_gpu = "Intel GPU"})
local ok9, decoded9 = pcall(json.decode, missing)
check(ok9, "missing GPU values did not produce valid JSON")
check(ok9 and decoded9.tooltip:find("Temperature: N/A"), "missing temperature was not rendered as N/A")
check(ok9 and decoded9.tooltip:find("Utilization: N/A"), "missing utilization was not rendered as N/A")
check(ok9 and decoded9.tooltip:find("Clock Speed: N/A/N/A MHz"), "missing clocks were not rendered as N/A")
check(ok9 and decoded9.tooltip:find("Power Usage: N/A/N/A W"), "missing power values were not rendered as N/A")

-- Battery discharge is never part of the GPU tooltip, even when supplied.
local ac = gpuinfo.generate_json({primary_gpu = "x", temperature = 50, power_discharge = 0.0})
local ok8, decoded8 = pcall(json.decode, ac)
check(ok8 and not decoded8.tooltip:find("Power Discharge"), "a zero discharge reading still produced a Power Discharge tooltip line")

os.exit(failures == 0 and 0 or 1)

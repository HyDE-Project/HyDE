local root = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = root .. "../../Configs/.local/lib/hyde/?.lua;" .. package.path
local gpuinfo = require("gpuinfo")

local failures = 0
local function check(condition, message)
    if not condition then
        failures = failures + 1
        print("    fail: " .. message)
    end
end

-- edge (amdgpu GPU) beats Tctl (AMD CPU) beats Package id (Intel CPU) --
-- the explicit priority this rewrite deliberately introduces (see spec:
-- "Explicit behavior change: sensor-match precedence"). Both present at once:
-- edge must win, because a module called "gpuinfo" should prefer an actual
-- GPU reading over a CPU proxy.
local both = [[{
  "k10temp-pci-00c3": {"Tctl": {"temp1_input": 45.0}},
  "amdgpu-pci-0100": {"edge": {"temp1_input": 60.0}}
}]]
local temp1 = gpuinfo.read_sensors(both)
check(temp1 == 60, "edge did not win over Tctl when both are present: got " .. tostring(temp1))

-- Tctl alone (AMD CPU, no amdgpu GPU) still matches.
local tctl_only = [[{"k10temp-pci-00c3": {"Tctl": {"temp1_input": 45.0}}}]]
check(gpuinfo.read_sensors(tctl_only) == 45, "Tctl alone was not picked up")

-- Tdie alone -- a separate alternative from Tctl, both must work
-- independently (a board/driver may only ever expose one of the two).
local tdie_only = [[{"k10temp-pci-00c3": {"Tdie": {"temp1_input": 52.0}}}]]
check(gpuinfo.read_sensors(tdie_only) == 52, "Tdie alone was not picked up")

-- Package id (Intel CPU package) is the last-resort fallback.
local package_only = [[{"coretemp-isa-0000": {"Package id 0": {"temp1_input": 38.0}}}]]
check(gpuinfo.read_sensors(package_only) == 38, "Package id was not picked up as the last-resort fallback")

-- Fan speed: any chip with a "fanN" label and a numeric input.
local with_fan = [[{"nct6775-isa-0290": {"fan1": {"fan1_input": 1200}}}]]
local _, fan = gpuinfo.read_sensors(with_fan)
check(fan == 1200, "fan speed was not extracted: got " .. tostring(fan))

-- Out-of-spec: no matching chip/label at all -- nil, not a crash.
check(gpuinfo.read_sensors("{}") == nil, "empty sensors data did not read as nil temperature")

-- Out-of-spec: `sensors -j` itself produced no output at all (sensors failed
-- or isn't installed) -- also nil, not a JSON-decode crash.
check(gpuinfo.read_sensors("") == nil, "empty string input crashed instead of reading as nil")

-- Out-of-spec: malformed JSON (a `sensors` version that half-writes output,
-- or is interrupted) -- degrades to nil rather than raising.
check(gpuinfo.read_sensors("{ this is not json") == nil, "malformed JSON crashed read_sensors instead of degrading to nil")

os.exit(failures == 0 and 0 or 1)

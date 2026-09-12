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

-- amdgpu.py's real JSON shape (see Configs/.local/lib/hyde/amdgpu.py).
local good_output = '{"GPU Temperature": "62°C", "GPU Load": "45.0%", "GPU Core Clock": "1500 MHz", "GPU Power Usage": "120 Watts"}'
local fields = gpuinfo.amd_query({amdgpu_gpu = "Radeon RX 7800", amdgpu_output = good_output})
check(fields.primary_gpu == "AMD Radeon RX 7800", "primary_gpu was not set: got " .. tostring(fields.primary_gpu))
check(fields.temperature == "62", "temperature suffix (°C) was not stripped: got " .. tostring(fields.temperature))
check(fields.utilization == "45.0", "utilization suffix (%%) was not stripped: got " .. tostring(fields.utilization))
check(fields.core_clock == "1500", "core_clock suffix (MHz) was not stripped: got " .. tostring(fields.core_clock))
check(fields.power_usage == "120", "power_usage suffix (Watts) was not stripped: got " .. tostring(fields.power_usage))

-- "No AMD GPUs detected." falls back to the generic sensors-based query,
-- exactly like the bash version.
local no_gpu_fields = gpuinfo.amd_query({
    amdgpu_gpu = "Radeon",
    amdgpu_output = "No AMD GPUs detected.",
    sensors_json = "{}",
    stat_file = "/proc/stat",
    cpu_sysfs_dir = "/nonexistent",
    power_supply_dir = "/nonexistent",
})
check(no_gpu_fields.primary_gpu == "AMD Radeon", "the fallback path did not still set primary_gpu")
check(no_gpu_fields.core_clock == nil, "the fallback path incorrectly carried over an AMD-specific field")

-- Out-of-spec: amdgpu.py hit one of its own exception branches and printed a
-- plain error string instead of JSON (e.g. "Runtime Error: ..."). The bash
-- version only checked for two specific literal substrings and would have
-- tried to jq-parse this as JSON anyway; this rewrite instead falls back
-- whenever the output doesn't actually decode as the expected object, which
-- also correctly covers this case the bash version didn't.
local error_fields = gpuinfo.amd_query({
    amdgpu_gpu = "Radeon",
    amdgpu_output = "Runtime Error: something unexpected",
    sensors_json = "{}",
    stat_file = "/proc/stat",
    cpu_sysfs_dir = "/nonexistent",
    power_supply_dir = "/nonexistent",
})
check(error_fields.primary_gpu == "AMD Radeon", "a non-JSON error string from amdgpu.py did not fall back cleanly")
check(error_fields.core_clock == nil, "a non-JSON error string was still treated as if it were valid amdgpu.py JSON")

os.exit(failures == 0 and 0 or 1)

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

local function write_file(path, content)
    local f = assert(io.open(path, "w"))
    f:write(content)
    f:close()
end

local work_dir = os.getenv("GPUINFO_TEST_WORK_DIR")
assert(work_dir, "GPUINFO_TEST_WORK_DIR must be set by the test wrapper")

-- A fake nvidia-smi that answers the exact --query-gpu the bash version used.
local fake_bin = work_dir .. "/bin"
os.execute("mkdir -p " .. fake_bin)
write_file(fake_bin .. "/nvidia-smi", [[#!/bin/sh
echo "62, 45, 1800, 3600, 120.00, 200.00"
]])
os.execute("chmod +x " .. fake_bin .. "/nvidia-smi")

local fields = gpuinfo.nvidia_query({
    nvidia_gpu = "GeForce RTX 4070",
    nvidia_smi_cmd = fake_bin .. "/nvidia-smi",
})
check(fields.primary_gpu == "NVIDIA GeForce RTX 4070", "primary_gpu was not set correctly: got " .. tostring(fields.primary_gpu))
check(fields.temperature == "62", "temperature was not parsed from the CSV output: got " .. tostring(fields.temperature))
check(fields.current_clock_speed == "1800", "current_clock_speed was not parsed: got " .. tostring(fields.current_clock_speed))
check(fields.power_limit == "200.00", "power_limit was not parsed: got " .. tostring(fields.power_limit))

-- --tired + suspended: must report suspended rather than calling nvidia-smi
-- at all (a suspended discrete GPU should not be woken just to poll it).
local runtime_status_path = work_dir .. "/runtime_status"
write_file(runtime_status_path, "suspended\n")
local suspend_fields, suspended = gpuinfo.nvidia_query({
    nvidia_gpu = "GeForce RTX 4070",
    tired = true,
    runtime_status_path = runtime_status_path,
    nvidia_smi_cmd = fake_bin .. "/nonexistent-should-not-be-called",
})
check(suspended == true, "a suspended GPU with --tired was not reported as suspended")
check(suspend_fields.primary_gpu == "NVIDIA GeForce RTX 4070", "suspended fields did not still carry primary_gpu")

-- nouveau (is_nouveau=true) uses the generic sensors-based query instead of
-- nvidia-smi (nouveau has no nvidia-smi to call).
local nouveau_fields = gpuinfo.nvidia_query({
    nvidia_gpu = "Linux",
    is_nouveau = true,
    sensors_json = "{}",
    stat_file = "/proc/stat",
    cpu_sysfs_dir = work_dir .. "/no-such-cpufreq-dir",
    power_supply_dir = work_dir .. "/no-such-power-dir",
})
check(nouveau_fields.primary_gpu == "NVIDIA Linux", "nouveau path did not set primary_gpu")

-- The same --tired check, but exercising the *default* runtime_status path
-- construction rather than the full runtime_status_path override above -- the
-- override masked a double "0000:" domain prefix that made the real path never
-- exist, so suspend was never detected on actual hardware. detect_vendor
-- stores nvidia_addr straight from the sysfs directory entry name, which is
-- already domain-qualified, so that is what is passed here.
local pci_devices_dir = work_dir .. "/pci-devices"
os.execute("mkdir -p '" .. pci_devices_dir .. "/0000:01:00.0/power'")
write_file(pci_devices_dir .. "/0000:01:00.0/power/runtime_status", "suspended\n")
local _, default_path_suspended = gpuinfo.nvidia_query({
    nvidia_gpu = "GeForce RTX 4070",
    tired = true,
    nvidia_addr = "0000:01:00.0",
    pci_devices_dir = pci_devices_dir,
    nvidia_smi_cmd = fake_bin .. "/nonexistent-should-not-be-called",
})
check(default_path_suspended == true, "suspend was not detected via the default runtime_status path construction")

-- Out-of-spec: an active GPU, and a missing/unreadable runtime_status file,
-- both have to fall through to the normal query rather than reporting suspend.
write_file(pci_devices_dir .. "/0000:01:00.0/power/runtime_status", "active\n")
local active_fields, active_suspended = gpuinfo.nvidia_query({
    nvidia_gpu = "GeForce RTX 4070",
    tired = true,
    nvidia_addr = "0000:01:00.0",
    pci_devices_dir = pci_devices_dir,
    nvidia_smi_cmd = fake_bin .. "/nvidia-smi",
})
check(active_suspended == false, "an active GPU was reported as suspended")
check(active_fields.temperature == "62", "an active GPU with --tired did not fall through to nvidia-smi")

local _, missing_suspended = gpuinfo.nvidia_query({
    nvidia_gpu = "GeForce RTX 4070",
    tired = true,
    nvidia_addr = "0000:99:00.0",
    pci_devices_dir = pci_devices_dir,
    nvidia_smi_cmd = fake_bin .. "/nvidia-smi",
})
check(missing_suspended == false, "a missing runtime_status file was treated as suspended")

-- Out-of-spec: no nvidia_addr at all (a state file written before the addr was
-- recorded) must not crash on a nil concatenation.
local nil_addr_ok = pcall(gpuinfo.nvidia_query, {
    nvidia_gpu = "GeForce RTX 4070",
    tired = true,
    pci_devices_dir = pci_devices_dir,
    nvidia_smi_cmd = fake_bin .. "/nvidia-smi",
})
check(nil_addr_ok, "a nil nvidia_addr raised instead of degrading to 'not suspended'")

-- Out-of-spec: a nil GPU name (a phantom vendor selected from a state file
-- that never recorded one) must not raise on the primary_gpu concatenation.
local nil_name_ok = pcall(gpuinfo.nvidia_query, {nvidia_smi_cmd = fake_bin .. "/nvidia-smi"})
check(nil_name_ok, "a nil nvidia_gpu name raised on the primary_gpu concatenation")

os.exit(failures == 0 and 0 or 1)

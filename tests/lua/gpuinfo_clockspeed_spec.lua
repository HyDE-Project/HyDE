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

-- A host with no cpufreq scaling driver at all (virtualized/cloud CPUs, some
-- ARM boards, CI runners) has no /sys/devices/system/cpu/cpufreq tree -- must
-- read as nil, not crash (this is the exact #2028 shape, re-derived fresh
-- here rather than needing that bash fix ported, per the spec).
local empty_dir = work_dir .. "/empty"
os.execute("mkdir -p " .. empty_dir)
local cur1, max1 = gpuinfo.read_cpu_clock_speed(empty_dir)
check(cur1 == nil, "a missing cpufreq tree did not read current speed as nil: got " .. tostring(cur1))
check(max1 == nil, "a missing cpufreq tree did not read max speed as nil: got " .. tostring(max1))

-- Two policies average correctly, and max comes from cpu0's own file.
local dir2 = work_dir .. "/two_policy"
os.execute("mkdir -p " .. dir2 .. "/cpufreq/policy0 " .. dir2 .. "/cpufreq/policy1 " .. dir2 .. "/cpu0/cpufreq")
write_file(dir2 .. "/cpufreq/policy0/scaling_cur_freq", "1200000")
write_file(dir2 .. "/cpufreq/policy1/scaling_cur_freq", "2400000")
write_file(dir2 .. "/cpu0/cpufreq/cpuinfo_max_freq", "3600000")
local cur2, max2 = gpuinfo.read_cpu_clock_speed(dir2)
check(cur2 == 1800.0, "two policies (1.2GHz+2.4GHz) did not average to 1800MHz: got " .. tostring(cur2))
check(max2 == 3600.0, "max frequency did not read as 3600MHz: got " .. tostring(max2))

-- Out-of-spec: a non-numeric value in one policy's file (a driver quirk)
-- must be skipped, not crash the average.
local dir3 = work_dir .. "/garbage_policy"
os.execute("mkdir -p " .. dir3 .. "/cpufreq/policy0 " .. dir3 .. "/cpufreq/policy1 " .. dir3 .. "/cpu0/cpufreq")
write_file(dir3 .. "/cpufreq/policy0/scaling_cur_freq", "not-a-number")
write_file(dir3 .. "/cpufreq/policy1/scaling_cur_freq", "2000000")
write_file(dir3 .. "/cpu0/cpufreq/cpuinfo_max_freq", "3000000")
local cur3 = gpuinfo.read_cpu_clock_speed(dir3)
check(cur3 == 2000.0, "a garbage policy reading was not skipped from the average: got " .. tostring(cur3))

os.exit(failures == 0 and 0 or 1)

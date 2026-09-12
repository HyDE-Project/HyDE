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

-- power_now present and readable: microwatts -> watts.
local dir1 = work_dir .. "/ps1"
os.execute("mkdir -p " .. dir1 .. "/BAT0")
write_file(dir1 .. "/BAT0/power_now", "15000000\n")
check(gpuinfo.read_battery_discharge(dir1) == 15.0, "power_now (15000000 uW) did not convert to 15.0 W")

-- No battery at all: nil, not an error.
local dir2 = work_dir .. "/ps2"
os.execute("mkdir -p " .. dir2)
check(gpuinfo.read_battery_discharge(dir2) == nil, "no battery present should read as nil, not a crash or a number")

-- Out-of-spec: power_now exists but the embedded controller answers ENXIO for
-- it on read (some laptops) -- current_now+voltage_now must be used instead,
-- not left empty just because power_now existed. Simulated portably as an
-- existing-but-empty file (io.open succeeds, read returns "").
local dir3 = work_dir .. "/ps3"
os.execute("mkdir -p " .. dir3 .. "/BAT0")
write_file(dir3 .. "/BAT0/power_now", "")
write_file(dir3 .. "/BAT0/current_now", "2000000\n")
write_file(dir3 .. "/BAT0/voltage_now", "12000000\n")
local watts = gpuinfo.read_battery_discharge(dir3)
check(watts and math.abs(watts - 24.0) < 0.001, "current_now*voltage_now fallback did not compute 24.0 W: got " .. tostring(watts))

os.exit(failures == 0 and 0 or 1)

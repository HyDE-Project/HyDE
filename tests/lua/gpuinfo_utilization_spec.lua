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

local work_dir = os.getenv("GPUINFO_TEST_WORK_DIR")
assert(work_dir, "GPUINFO_TEST_WORK_DIR must be set by the test wrapper")
local stat_file = work_dir .. "/stat"

local function write_stat(user, nice, system, idle, iowait, irq, softirq)
    local f = assert(io.open(stat_file, "w"))
    f:write(string.format("cpu  %d %d %d %d %d %d %d 0 0 0\n", user, nice, system, idle, iowait, irq, softirq))
    f:close()
end

-- First-ever call (no prev_stat/prev_idle in state) must seed rather than
-- crash or report a nonsense huge percentage -- mirrors the already-fixed
-- #2021/#2022 cold-start contract: a brand new state reads back as 0%, not
-- a division-by-zero and not garbage from diffing against zero.
write_stat(1000, 0, 500, 8000, 0, 0, 0)
local state = {}
local first = gpuinfo.read_cpu_utilization(state, stat_file)
check(first == 0.0, "first-ever call did not read as 0%%: got " .. tostring(first))
check(state.prev_stat ~= nil and state.prev_idle ~= nil, "first call did not seed prev_stat/prev_idle into state")

-- A second poll with more busy time than idle time reports a real,
-- persisted-across-calls percentage.
write_stat(1100, 0, 550, 8010, 0, 0, 0) -- stat delta=150, idle delta=10 -> 150/160*100 = 93.75 -> "%.1f" = 93.8
local second = gpuinfo.read_cpu_utilization(state, stat_file)
check(math.abs(second - 93.8) < 0.05, "second poll did not compute the expected percentage: got " .. tostring(second))

-- Out-of-spec: a state table that already carries a *string* prev_stat (as
-- it would after a read_state()/write_state() JSON round-trip, since JSON
-- numbers can come back as either type depending on the decoder) must still
-- work -- this is exactly the boundary between this function and Task 1's
-- state module, so it's tested here rather than assumed.
local string_state = {prev_stat = "1500", prev_idle = "8000"}
write_stat(1100, 0, 550, 8010, 0, 0, 0)
local from_strings = gpuinfo.read_cpu_utilization(string_state, stat_file)
check(math.abs(from_strings - 93.8) < 0.05, "a state with string-typed prev_stat/prev_idle was not handled: got " .. tostring(from_strings))

-- Out-of-spec: a missing stat file must degrade like every sibling reader in
-- gpuinfo.lua (read_battery_discharge, read_cpu_clock_speed, read_sensors all
-- return "no reading" rather than raising) -- this runs on every poll, and a
-- raise here takes the whole waybar JSON line down with it.
local missing_ok, missing = pcall(gpuinfo.read_cpu_utilization, {}, work_dir .. "/no-such-stat-file")
check(missing_ok, "a missing stat file raised instead of degrading: " .. tostring(missing))
check(missing_ok and missing == 0, "a missing stat file did not read as 0%%: got " .. tostring(missing))

-- Out-of-spec: malformed content. A cpu line with non-numeric garbage in a
-- field, and a file whose first line isn't a cpu line at all, both have to
-- degrade rather than do arithmetic on a nil capture.
local function write_raw(content)
    local f = assert(io.open(stat_file, "w"))
    f:write(content)
    f:close()
end

write_raw("cpu  1000 0 garbage 8000 0 0 0\n")
local garbage_ok, garbage = pcall(gpuinfo.read_cpu_utilization, {}, stat_file)
check(garbage_ok, "a cpu line with a non-numeric field raised: " .. tostring(garbage))
check(garbage_ok and garbage == 0, "a malformed cpu line did not read as 0%%: got " .. tostring(garbage))

write_raw("this is not /proc/stat at all\n")
local wrong_ok, wrong = pcall(gpuinfo.read_cpu_utilization, {}, stat_file)
check(wrong_ok, "a file with no cpu line raised: " .. tostring(wrong))
check(wrong_ok and wrong == 0, "a file with no cpu line did not read as 0%%: got " .. tostring(wrong))

-- Boundary: a completely empty file (a half-written read) is the same case.
write_raw("")
local empty_ok, empty = pcall(gpuinfo.read_cpu_utilization, {}, stat_file)
check(empty_ok, "an empty stat file raised: " .. tostring(empty))
check(empty_ok and empty == 0, "an empty stat file did not read as 0%%: got " .. tostring(empty))

os.exit(failures == 0 and 0 or 1)

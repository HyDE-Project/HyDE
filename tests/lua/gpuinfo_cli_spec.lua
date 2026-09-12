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

local work_dir = os.getenv("GPUINFO_TEST_WORK_DIR")
assert(work_dir, "GPUINFO_TEST_WORK_DIR must be set by the test wrapper")

-- Every run() points detection at paths that cannot exist, so no case in this
-- file ever reads the real machine's /sys/bus/pci/devices or shells out to the
-- real lspci -- otherwise the assertions below would pass or fail depending on
-- what GPU the CI runner happens to have.
local FAKE_DETECT = {
    pci_dir = work_dir .. "/no-such-pci-dir",
    modules_file = work_dir .. "/no-such-modules",
    path_dirs = {work_dir .. "/no-such-bin-dir"},
}

local function run(argv, extra_opts)
    local lines = {}
    local opts = {
        print_fn = function(s) lines[#lines + 1] = s end,
        state_suffix_override = "_cli_test",
        detect_vendor_opts = FAKE_DETECT,
        lact_output = '{"primary_gpu":"Test GPU","temperature":62,"utilization":45,"current_clock_speed":1800,"max_clock_speed":3600,"power_usage":120,"power_limit":200}',
    }
    for k, v in pairs(extra_opts or {}) do
        opts[k] = v
    end
    local code = gpuinfo.cli_main(argv, opts)
    return code, table.concat(lines, "\n")
end

-- Cold start (no state file yet, no vendor detected on this fake sysfs) must
-- still produce exactly-one-JSON-object-per-line output on stdout (captured
-- here via print_fn), never a diagnostic banner mixed in -- the #2021/#2022
-- contract this rewrite must not regress just because the implementation
-- language changed. The "Initialized: ..." diagnostic goes through the
-- separate warn_fn (stderr in real usage), captured to its own buffer here
-- specifically so a regression that routed it back through print_fn would
-- show up as a line the loop below rejects.
os.remove(gpuinfo.state_path("_cli_test"))
local warn_lines = {}
local code1, out1 = run({}, {
    warn_fn = function(s) warn_lines[#warn_lines + 1] = s end,
})
check(#warn_lines > 0, "the cold-start 'Initialized: ...' diagnostic did not go through warn_fn at all")
for line in out1:gmatch("[^\n]+") do
    local ok = pcall(json.decode, line)
    check(ok or line:match("^Error"), "a cold-start stdout line was neither valid JSON nor the documented error message: " .. line)
end

-- --stat <vendor> reports "GPU not enabled." and a nonzero exit for a vendor
-- that was never detected -- matches the bash version's contract exactly
-- (waybar's exec-if uses this to decide whether to show that module at all).
local code2, out2 = run({"--stat", "nvidia"})
check(code2 ~= 0, "--stat for an undetected vendor did not exit non-zero")
check(out2:find("GPU not enabled%."), "--stat for an undetected vendor did not print the documented message")

-- --stat with an invalid vendor name reports the documented usage error.
local code3, out3 = run({"--stat", "bogus"})
check(code3 ~= 0, "--stat with an invalid vendor name did not exit non-zero")
check(out3:find("Invalid argument for %-%-stat"), "--stat with an invalid vendor name did not print the documented error")

-- --use is rejected the same way *before* it becomes part of the state
-- suffix -- an unchecked value would otherwise let a cold start read/write
-- a JSON file outside the runtime dir once concatenated into a path
-- (caught in review: --use "../../../etc/passwd"-shaped input reached
-- M.state_path unvalidated).
local code4, out4 = run({"--use", "bogus"})
check(code4 ~= 0, "--use with an invalid vendor name did not exit non-zero")
check(out4:find("Invalid argument for %-%-use"), "--use with an invalid vendor name did not print the documented error")

local traversal_suffix = "_../../outside-runtime-dir"
local code5 = run({"--use", "../../outside-runtime-dir"})
check(code5 ~= 0, "--use with a path-traversal-shaped value did not exit non-zero")
check(
    not gpuinfo.read_state(traversal_suffix).detected,
    "a rejected --use value still reached the state path and got written"
)

-- Detection must run once and stay run, even when it finds nothing: on
-- hardware with none of the three recognized vendors every *_enable stays
-- false forever, and a "did we find anything" gate re-walked sysfs and
-- re-emitted the "Initialized: ..." diagnostic on every single poll (~5s
-- forever), defeating the rewrite's whole fewer-subprocess-calls point.
os.remove(gpuinfo.state_path("_cli_test"))
local first_warns, second_warns = {}, {}
run({}, {warn_fn = function(s) first_warns[#first_warns + 1] = s end})
run({}, {warn_fn = function(s) second_warns[#second_warns + 1] = s end})
check(#first_warns > 0, "the first poll on a machine with no supported GPU did not run detection at all")
check(#second_warns == 0, "detection re-ran on the second poll even though it had already run: " .. table.concat(second_warns, " | "))

-- --reset clears stale flags, matching the bash version's `rm -fr` of the
-- state file that its own --help still advertises -- but a flag passed on the
-- same invocation as --reset must survive it.
run({"--tired", "--emoji"})
local after_tired = gpuinfo.read_state("_cli_test")
check(after_tired.tired == true and after_tired.emoji == true, "--tired/--emoji were not persisted")

run({"--reset"})
local after_reset = gpuinfo.read_state("_cli_test")
check(not after_reset.tired, "--reset did not clear a stale tired flag")
check(not after_reset.emoji, "--reset did not clear a stale emoji flag")
check(after_reset.detected == true, "--reset did not re-run detection")

run({"--reset", "--tired"})
local reset_with_flag = gpuinfo.read_state("_cli_test")
check(reset_with_flag.tired == true, "--reset wiped a --tired flag passed on the same invocation")

os.remove(gpuinfo.state_path("_cli_test"))

os.exit(failures == 0 and 0 or 1)

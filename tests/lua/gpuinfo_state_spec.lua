-- Exercises gpuinfo.lua's state persistence in isolation, before any CLI
-- wiring exists. Requiring the file must not run the CLI (see the
-- open.lua-style auto-run guard gpuinfo.lua ends with) -- Task 1 has no
-- guard yet, so this also proves requiring it has no side effects.

local root = debug.getinfo(1, "S").source:match("^@(.*/)") or "./"
package.path = root .. "../../Configs/.local/lib/hyde/?.lua;" .. package.path

local runtime_dir = os.getenv("XDG_RUNTIME_DIR")
assert(runtime_dir, "XDG_RUNTIME_DIR must be set by the test wrapper")

local gpuinfo = require("gpuinfo")

local failures = 0
local function check(condition, message)
    if not condition then
        failures = failures + 1
        print("    fail: " .. message)
    end
end

-- A missing state file reads back as an empty table, not nil or an error.
os.remove(gpuinfo.state_path(""))
local empty = gpuinfo.read_state("")
check(type(empty) == "table", "read_state on a missing file did not return a table")
check(next(empty) == nil, "read_state on a missing file returned a non-empty table")

-- Writing then reading round-trips arbitrary fields.
local ok, err = gpuinfo.write_state("", {nvidia_enable = true, priority = "GPUINFO_AMD_ENABLE"})
check(ok == true, "write_state failed: " .. tostring(err))
local round_tripped = gpuinfo.read_state("")
check(round_tripped.nvidia_enable == true, "nvidia_enable did not round-trip")
check(round_tripped.priority == "GPUINFO_AMD_ENABLE", "priority did not round-trip")

-- A suffix (per-waybar-instance state, matching --use/--startup's "$2") is a
-- separate file from the unsuffixed default.
gpuinfo.write_state("_amd", {amd_enable = true})
check(gpuinfo.read_state("").nvidia_enable == true, "suffixed write clobbered the default state file")
check(gpuinfo.read_state("_amd").amd_enable == true, "suffixed state did not persist")

-- Out-of-spec: a corrupt (non-JSON) state file must degrade to an empty
-- table, not crash the caller -- this runs on every single poll, so a
-- hand-edited or half-written state file must never take the whole module
-- down.
local corrupt_path = gpuinfo.state_path("_corrupt")
local f = assert(io.open(corrupt_path, "w"))
f:write("{ this is not json")
f:close()
local corrupt_read = gpuinfo.read_state("_corrupt")
check(type(corrupt_read) == "table", "a corrupt state file crashed read_state instead of degrading to {}")

os.remove(gpuinfo.state_path(""))
os.remove(gpuinfo.state_path("_amd"))
os.remove(corrupt_path)

os.exit(failures == 0 and 0 or 1)

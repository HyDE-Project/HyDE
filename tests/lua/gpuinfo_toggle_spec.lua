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

-- Cycling with no explicit request steps to the next available vendor, in a
-- stable order, and wraps around. `available` is what detection records once
-- (cli_main writes it); the *_enable keys carry the current *selection*, which
-- this function rewrites, so cycling must not be derived from them -- the
-- second toggle below is what proves that.
local state = {available = {"amd", "intel"}, amd_enable = true, intel_enable = true, priority = "amd"}
local next1 = gpuinfo.toggle(state, nil)
check(next1 == "intel", "cycling from amd with only amd/intel available did not land on intel: got " .. tostring(next1))
check(state.priority == "intel", "priority was not updated to the new vendor")
check(state.amd_enable == false, "the previous vendor was not disabled")
check(state.intel_enable == true, "the new vendor was not enabled")

local next2 = gpuinfo.toggle(state, nil)
check(next2 == "amd", "cycling wrapped incorrectly, expected amd: got " .. tostring(next2))

-- An explicit request ("--use amd") jumps directly to that vendor regardless
-- of cycle order, as long as it's actually available.
local state2 = {available = {"amd", "intel"}, amd_enable = true, intel_enable = true, priority = "intel"}
local requested = gpuinfo.toggle(state2, "amd")
check(requested == "amd", "an explicit --use request was not honored: got " .. tostring(requested))
check(state2.amd_enable == true, "the explicitly requested vendor was not enabled")
check(state2.intel_enable == false, "the previously active vendor was not disabled after an explicit request")

-- Out-of-spec: requesting a vendor that was never detected as available must
-- not silently "succeed" with a nonsense enabled vendor -- it has to report
-- the failure so the caller (Task 11's CLI dispatch) can print the same
-- "Error: ... not found" message the bash version does, instead of leaving
-- state in an inconsistent shape (some vendor enabled that isn't really there).
local state3 = {available = {"amd"}, amd_enable = true, priority = "amd"}
local unavailable, err = gpuinfo.toggle(state3, "nvidia")
check(unavailable == nil, "requesting an unavailable vendor did not return nil")
check(type(err) == "string" and err:match("nvidia"), "requesting an unavailable vendor did not name it in the error: got " .. tostring(err))
check(state3.amd_enable == true, "state was mutated even though the requested vendor was unavailable")

-- Out-of-spec (the shape cli_main actually persists): every detection writes
-- all three *_enable keys, including an explicit `false` for vendors that are
-- not present. "Available" therefore has to mean truthy, not merely present --
-- a presence check made every vendor look available on every machine, so one
-- --toggle click could land on a vendor whose *_gpu name was never populated,
-- and every subsequent poll crashed on the nil name.
local persisted = {nvidia_enable = false, amd_enable = false, intel_enable = true, priority = "intel"}
local only_intel = gpuinfo.toggle(persisted, nil)
check(only_intel == "intel", "cycling a persisted state with only intel truthy left intel: got " .. tostring(only_intel))
check(persisted.nvidia_enable == false, "an undetected vendor was enabled by a toggle")
check(persisted.amd_enable == false, "an undetected vendor was enabled by a toggle")

local persisted2 = {nvidia_enable = false, amd_enable = false, intel_enable = true, priority = "intel"}
local phantom, phantom_err = gpuinfo.toggle(persisted2, "nvidia")
check(phantom == nil, "--use named a vendor that was detected as absent and was not rejected")
check(type(phantom_err) == "string" and phantom_err:match("nvidia"), "the rejection did not name the vendor: got " .. tostring(phantom_err))

-- The same, in the shape cli_main really persists (an `available` list plus
-- the three enables): a vendor that is not in `available` must stay
-- unreachable no matter how many times the user clicks, and a vendor that *is*
-- must stay reachable after its enable key has been flipped to false by an
-- earlier toggle.
local recorded = {available = {"amd", "intel"}, nvidia_enable = false, amd_enable = true, intel_enable = false, priority = "amd"}
check(gpuinfo.toggle(recorded, nil) == "intel", "first toggle did not step amd -> intel")
check(gpuinfo.toggle(recorded, nil) == "amd", "second toggle did not wrap intel -> amd (availability was read out of the selection keys)")
check(gpuinfo.toggle(recorded, nil) == "intel", "third toggle did not step amd -> intel again")
check(recorded.nvidia_enable == false, "an undetected vendor got enabled somewhere in the cycle")
local no_nvidia, no_nvidia_err = gpuinfo.toggle(recorded, "nvidia")
check(no_nvidia == nil and tostring(no_nvidia_err):match("nvidia"), "--use nvidia was accepted on a machine whose available list has no nvidia")

-- Boundary: nothing detected at all (all three explicitly false) is "no vendor
-- available", not "all three available".
local none_state = {nvidia_enable = false, amd_enable = false, intel_enable = false}
local none, none_err = gpuinfo.toggle(none_state, nil)
check(none == nil, "toggling with no vendor available returned a vendor: got " .. tostring(none))
check(type(none_err) == "string" and none_err:find("no GPU vendor is available"), "the no-vendor error message was not the documented one: got " .. tostring(none_err))
check(none_state.priority == nil, "state was mutated even though no vendor was available")

os.exit(failures == 0 and 0 or 1)

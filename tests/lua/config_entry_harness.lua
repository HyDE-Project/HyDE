-- Loads the shipped Hyprland entry point the way Hyprland loads it, and checks
-- that it can still reach the modules shipped beside it.
--
-- Hyprland builds package.path from the directory of the config it was started
-- with and prepends nothing else, so which files a bare require() can see
-- depends entirely on which file the session was pointed at. HyDE is reachable
-- through two of them: hyde.lua directly, which is what HYPRLAND_CONFIG names,
-- and the user's hyprland.lua, which is what Hyprland picks on its own. Only
-- the first puts the shipped tree on the search path, so the bootstrap has to
-- resolve it without one.
--
-- Usage:
--   lua config_entry_harness.lua <entry> <anchor> <root>
--
--   entry   config file to load, as Hyprland would
--   anchor  directory Hyprland would anchor the search path at
--   root    directory the shipped Lua tree has to be reachable under

local entry = assert(arg[1], "entry point is not set")
local anchor = assert(arg[2], "anchor directory is not set")
local root = assert(arg[3], "shipped root is not set")

package.path = anchor .. "/?.lua;" .. anchor .. "/?/init.lua;" .. package.path

-- Only the bootstrap is under test. Everything the entry point pulls in after
-- it wants a live compositor, so the first require issued once the search path
-- is in place ends the load and records where it got to. A run that never
-- reaches one is a run that stopped earlier, which is the defect this case
-- exists for.
--
-- Extending the search path is what separates the two: anything required
-- before that is the bootstrap resolving itself, and has to succeed on its own
-- terms rather than be answered by this harness.
local STOP = "stopped-at:"
local bootstrap_path = package.path
local real_require = require
local stopped_at

_G.require = function(name)
    if package.path == bootstrap_path then
        return real_require(name)
    end

    stopped_at = name
    error(STOP .. name, 0)
end

local failures = 0

local function check(condition, message)
    if not condition then
        failures = failures + 1
        print("    fail: " .. message)
    end
end

local ok, err = pcall(dofile, entry)

check(not ok, "the entry point loaded past its first require without a compositor")
check(
    stopped_at ~= nil,
    string.format("%s stopped before the first require: %s", entry, tostring(err))
)
check(
    stopped_at == "hyde.utils",
    string.format(
        "the bootstrap did not complete: the load stopped at %q instead of the first module after it",
        tostring(stopped_at)
    )
)

-- The resolver is what every later path is built from, so an entry point that
-- reaches it but leaves it half filled is no better than one that never did.
check(type(hyde) == "table" and type(hyde.path) == "table", "hyde.path was not populated")

if type(hyde) == "table" and type(hyde.path) == "table" then
    for _, field in ipairs({"config", "state", "data", "share", "lib"}) do
        check(type(hyde.path[field]) == "string", string.format("hyde.path.%s was not resolved", field))
    end

    check(
        package.loaded["hyde.path"] == hyde.path,
        "the resolver was not registered as a module, so requiring it by name loads a second copy"
    )
end

check(
    package.path:find(root .. "/lua/?.lua", 1, true) ~= nil,
    string.format("%s/lua is not on the search path, the modules below the entry point cannot load", root)
)

if failures > 0 then
    os.exit(1)
end

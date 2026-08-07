-- Loads the shipped entry point with the search path Hyprland would give it,
-- and checks it can still reach the modules beside it. Only one of the two
-- entry points puts that tree on the search path, so the bootstrap has to
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

-- Only the bootstrap is under test: the rest wants a live compositor. A
-- require issued once the search path is in place ends the load; one issued
-- before that is the bootstrap resolving itself and has to succeed on its own.
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

-- Every later path is built from the resolver, so reaching it half filled is
-- no better than never reaching it.
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

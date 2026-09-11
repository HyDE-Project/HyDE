-- Tests the hl.bind()/hl.dsp.exec_cmd() interception hyde/binds.lua adds for
-- #1996 (hyde.binds._commands and its cache file), in isolation from the
-- real key_binds.lua -- tests/lua/bind_harness.lua already covers that the
-- shipped binds themselves are well-formed; this only covers the new
-- capture/persist mechanism, against small synthetic binds chosen to hit
-- each case on purpose.

local repo_root = assert(os.getenv("REPO_ROOT"), "REPO_ROOT is not set")
local lua_root = repo_root .. "/Configs/.local/share/hypr/lua"
local work_dir = assert(os.getenv("BIND_COMMANDS_TEST_WORK_DIR"), "BIND_COMMANDS_TEST_WORK_DIR is not set")

local failures = 0
local function check(condition, message)
    if not condition then
        failures = failures + 1
        print("    fail: " .. message)
    end
end

-- Same callable-table shape as the real native hl.dsp.* dispatchers and the
-- one tests/lua/bind_harness.lua already uses -- exercising this instead of
-- a plain Lua function is the whole point: type(x) == "function" alone
-- would miss it.
local function dsp_proxy(prefix)
    return setmetatable(
        {},
        {
            __index = function(_, key)
                return dsp_proxy(prefix == "" and key or prefix .. "." .. key)
            end,
            __call = function(_, ...)
                return {dispatcher = prefix, args = {...}}
            end
        }
    )
end

_G.hl = {
    dsp = dsp_proxy(""),
    on = function() end
}
_G.hl.bind = function(combo, action, opts)
end
_G.hl.unbind = function()
end

_G.hyde = {
    config = {modifiers = {main = "SUPER"}}
}

dofile(lua_root .. "/hyde/binds.lua")

-- 1. Two distinct exec_cmd binds must be paired with their own command, not
-- with each other's.
hl.bind("SUPER + T", hl.dsp.exec_cmd("kitty"), {description = "terminal"})
hl.bind("SUPER + E", hl.dsp.exec_cmd("dolphin"), {description = "explorer"})
check(hyde.binds._commands["SUPER + T"] == "kitty", "SUPER + T was not paired with its own command")
check(hyde.binds._commands["SUPER + E"] == "dolphin", "SUPER + E was not paired with its own command")

-- A delayed exec_cmd action must survive an unrelated bind and still pair
-- with its own command when that exact action is eventually registered.
local delayed_action = hl.dsp.exec_cmd("delayed")
hl.bind("SUPER + D", hl.dsp.window.close(), {description = "unrelated"})
check(hyde.binds._commands["SUPER + D"] == nil, "an unrelated bind consumed a delayed command")
hl.bind("SUPER + Y", delayed_action, {description = "delayed"})
check(hyde.binds._commands["SUPER + Y"] == "delayed", "a delayed matching action lost its command")

-- 2. A native dispatcher called directly (no exec_cmd) must not be recorded,
-- and must not pick up a command left over from an unrelated earlier bind.
hl.bind("SUPER + Q", hl.dsp.window.close(), {description = "close"})
check(hyde.binds._commands["SUPER + Q"] == nil, "a native-dispatcher bind was recorded as if it were exec_cmd")

-- 3. A plain Lua closure (no exec_cmd, no native dispatcher table at all)
-- must not be recorded either, and must not leak a stale pending command
-- into the *next* bind.
hl.bind("SUPER + F", hl.dsp.exec_cmd("should-not-leak"), {description = "leftover"})
local noop = function()
end
hl.bind("SUPER + G", noop, {description = "toggle group"})
check(hyde.binds._commands["SUPER + G"] == nil, "a plain-function bind was recorded")
hl.bind("SUPER + H", hl.dsp.window.close(), {description = "close2"})
check(
    hyde.binds._commands["SUPER + H"] == nil,
    "a stale pending command leaked past an intervening non-exec_cmd bind"
)

-- 4. Re-registering the same canonical combo (a config reload re-running the
-- whole file) must end up with the *last* command, not the first.
hl.bind("SUPER + V", hl.dsp.exec_cmd("first"), {description = "v1"})
hl.bind("SUPER + V", hl.dsp.exec_cmd("second"), {description = "v2"})
check(hyde.binds._commands["SUPER + V"] == "second", "re-registering a combo did not overwrite the older command")

-- 4b. Replacing an exec_cmd bind with a native dispatcher must clear the
-- stale command so it does not leak into the keybind-hint menu.
hl.bind("SUPER + R", hl.dsp.exec_cmd("refresh"), {description = "r1"})
check(hyde.binds._commands["SUPER + R"] == "refresh", "exec_cmd did not store its command")
hl.bind("SUPER + R", hl.dsp.window.close(), {description = "r2"})
check(hyde.binds._commands["SUPER + R"] == nil, "native-dispatcher rebound did not clear the stale command")

-- 4c. Replacing an exec_cmd bind with a plain Lua function must also clear
-- the stale command.
hl.bind("SUPER + M", hl.dsp.exec_cmd("maximize"), {description = "m1"})
check(hyde.binds._commands["SUPER + M"] == "maximize", "exec_cmd did not store its command for M")
local function toggle_float()
end
hl.bind("SUPER + M", toggle_float, {description = "m2"})
check(hyde.binds._commands["SUPER + M"] == nil, "plain-function rebound did not clear the stale command")

-- 5. Modifier order/spelling must canonicalize the same way _active already
-- does -- this is a different table, computed at a different point in
-- hl.bind, so it is not automatically guaranteed just because _active works.
hl.bind("SUPER + CONTROL + B", hl.dsp.exec_cmd("via-control"), {description = "b1"})
hl.bind("CTRL + SUPER + B", hl.dsp.exec_cmd("via-ctrl"), {description = "b2"})
check(
    hyde.binds._commands["CTRL + SUPER + B"] == "via-ctrl",
    "two spellings of the same combo did not collapse to one canonical key"
)
check(hyde.binds._commands["SUPER + CONTROL + B"] == nil, "an alias spelling was kept as its own separate key")

-- 6. A plain key with no modifiers at all (modmask 0 on the Hyprland side).
hl.bind("F10", hl.dsp.exec_cmd("mute"), {description = "mute", locked = true})
check(hyde.binds._commands["F10"] == "mute", "a no-modifier bind was not recorded under its bare key")

-- Out-of-spec inputs to hl.bind itself must not error out of the wrapper.
local ok_nil_combo = pcall(hl.bind, nil, hl.dsp.exec_cmd("x"), {description = "y"})
check(ok_nil_combo, "a nil keycombo raised instead of being ignored like normalize() already treats it")

local ok_no_opts = pcall(hl.bind, "SUPER + Z", hl.dsp.exec_cmd("z"), nil)
check(ok_no_opts, "a nil opts argument raised")
check(hyde.binds._commands["SUPER + Z"] == "z", "a bind with nil opts was still not recorded")

print(string.format("    %d command(s) captured", (function()
    local n = 0
    for _ in pairs(hyde.binds._commands) do
        n = n + 1
    end
    return n
end)()))

-- Cache file: missing hyde.path (or a non-string .cache) must degrade
-- silently, never raise -- this runs inside Hyprland's own config load, and
-- crashing here would take the whole session down.
hyde.path = nil
local ok_no_path = pcall(hyde.binds._write_commands_cache)
check(ok_no_path, "writing with hyde.path entirely absent raised")

hyde.path = {}
local ok_no_cache_field = pcall(hyde.binds._write_commands_cache)
check(ok_no_cache_field, "writing with hyde.path.cache unset raised")

hyde.path = {cache = 42}
local ok_wrong_type = pcall(hyde.binds._write_commands_cache)
check(ok_wrong_type, "writing with a non-string hyde.path.cache raised")

-- A cache directory that doesn't exist: this module deliberately never
-- creates it (no os.execute/mkdir -- Hyprland budgets the whole config load
-- at 1500ms and does not want a forked shell counted against it), so the
-- write must fail closed, not raise.
hyde.path = {cache = work_dir .. "/no-such-dir"}
local ok_missing_dir = pcall(hyde.binds._write_commands_cache)
check(ok_missing_dir, "writing to a missing cache directory raised instead of failing closed")

local function read_file(path)
    local f = io.open(path, "r")
    if not f then
        return nil
    end
    local content = f:read("a")
    f:close()
    return content
end

check(
    read_file(work_dir .. "/no-such-dir/hyde/lua_bind_commands.json") == nil,
    "a file appeared under a cache directory that was never created"
)

-- The real, existing directory: the write must succeed and produce JSON
-- python's own json module accepts, with every captured pair intact --
-- verified out-of-process since hint-hyprland.py is what actually reads it.
os.execute("mkdir -p '" .. work_dir .. "/real/hyde'")
hyde.path = {cache = work_dir .. "/real"}
hyde.binds._write_commands_cache()

local cache_content = read_file(work_dir .. "/real/hyde/lua_bind_commands.json")
check(cache_content ~= nil, "the cache file was not written to an existing directory")

if cache_content then
    -- Round-tripped through a temp file rather than piped to python's
    -- stdin: io.popen only gives one direction (read *or* write) per handle
    -- portably, and a file keeps this a single, ordinary syscall path.
    local tmp_json = work_dir .. "/roundtrip.json"
    local out = io.open(tmp_json, "w")
    out:write(cache_content)
    out:close()

    local py = io.popen(
        "python3 -c \"import json; d=json.load(open('"
            .. tmp_json
            .. "')); "
            .. "assert d['SUPER + T'] == 'kitty', d; assert d['SUPER + V'] == 'second', d; "
            .. "assert 'SUPER + Q' not in d, d; assert d['SUPER + Z'] == 'z', d; print('ok')\" 2>&1"
    )
    local result = py and py:read("a") or ""
    if py then
        py:close()
    end
    check(result:match("^ok"), "python could not parse the written cache as valid JSON with the right content: " .. result)
end

-- Empty table: still valid, parseable JSON, not an empty string or a crash.
hyde.binds._commands = {}
hyde.binds._write_commands_cache()
local empty_content = read_file(work_dir .. "/real/hyde/lua_bind_commands.json")
check(empty_content == "{}", "an empty _commands table did not serialize to '{}': got " .. tostring(empty_content))

os.exit(failures == 0 and 0 or 1)

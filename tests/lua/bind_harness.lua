-- Loads the shipped Lua keybinds against a stubbed Hyprland API and checks
-- them for defects that Hyprland itself accepts silently.
--
-- Everything Hyprland exposes as `hl` is replaced with a recorder, so no
-- compositor is needed and nothing is dispatched. `REPO_ROOT` selects the
-- tree to check, which lets the same harness run against any checkout.

local repo_root = assert(os.getenv("REPO_ROOT"), "REPO_ROOT is not set")
local lua_root = repo_root .. "/Configs/.local/share/hypr/lua"
local lib_root = repo_root .. "/Configs/.local/lib/hyde"

-- Modifiers Hyprland accepts in front of the key. Anything else in that
-- position is silently dropped, which turns the combo into a different bind.
local MODIFIERS = {
    SUPER = true,
    CTRL = true,
    CONTROL = true,
    SHIFT = true,
    ALT = true,
    CAPS = true,
    WIN = true,
    LOGO = true,
    MOD1 = true,
    MOD2 = true,
    MOD3 = true,
    MOD4 = true,
    MOD5 = true
}

local ALIASES = {CONTROL = "CTRL", WIN = "SUPER", LOGO = "SUPER", MOD1 = "ALT", MOD4 = "SUPER"}

local function trim(str)
    return (str:match("^%s*(.-)%s*$"))
end

local function split(combo)
    local tokens = {}
    for token in combo:gmatch("[^+]+") do
        tokens[#tokens + 1] = trim(token)
    end
    return tokens
end

-- Reduces a combo to what Hyprland matches on. Modifiers are a set, so
-- spelling, order and case carry no meaning: "SUPER + CTRL + Left" and
-- "SUPER + CONTROL + LEFT" are the same bind.
local function canonical(combo)
    local tokens = split(combo)
    local key = table.remove(tokens) or ""

    for i, token in ipairs(tokens) do
        local upper = token:upper()
        tokens[i] = ALIASES[upper] or upper
    end
    table.sort(tokens)

    tokens[#tokens + 1] = key:upper()
    return table.concat(tokens, " + ")
end

local function file_exists(path)
    local handle = io.open(path, "r")
    if handle then
        handle:close()
        return true
    end
    return false
end

-- Subcommands hyde-shell implements itself, declared as "# @cmd: name" in its
-- header. They resolve without a matching file in the script directories.
local function builtin_commands()
    local builtins = {}
    local handle = io.open(repo_root .. "/Configs/.local/bin/hyde-shell", "r")
    if not handle then
        return builtins
    end

    for line in handle:lines() do
        local name = line:match("^#%s*@cmd:%s*([%w%._-]+)")
        if name then
            builtins[name] = true
        end
    end
    handle:close()

    return builtins
end

local BUILTINS = builtin_commands()

-- hyde-shell resolves a command name against these extensions, in this order.
local function command_resolves(name)
    if BUILTINS[name] then
        return true
    end
    if file_exists(lib_root .. "/" .. name) then
        return true
    end
    for _, extension in ipairs({".sh", ".lua", ".py"}) do
        if file_exists(lib_root .. "/" .. name .. extension) then
            return true
        end
    end
    return false
end

local binds = {}
local gestures = {}

-- Values Hyprland accepts, taken from what it rejects at config load:
-- an unknown direction or action is reported as a config error, but a
-- duplicate pair is not, and that is the one that silently wins or loses.
local GESTURE_DIRECTIONS = {
    horizontal = true,
    vertical = true,
    left = true,
    right = true,
    up = true,
    down = true,
    pinchin = true,
    pinchout = true,
    swipe = true
}

local GESTURE_ACTIONS = {
    workspace = true,
    move = true,
    close = true,
    fullscreen = true,
    float = true,
    special = true,
    resize = true
}

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
    dispatch = function()
    end,
    get_active_window = function()
        return {fullscreen = 0, floating = false}
    end,
    notification = {
        create = function()
        end
    }
}

_G.hl.bind = function(combo, action, opts)
    binds[#binds + 1] = {combo = combo, action = action, opts = opts}
end

_G.hl.gesture = function(spec)
    gestures[#gestures + 1] = spec
end

_G.hl.unbind = function(combo)
    for index = #binds, 1, -1 do
        if binds[index].combo == combo then
            table.remove(binds, index)
            return
        end
    end
end

_G.hyde = {
    config = {
        app = {
            terminal = "kitty",
            explorer = "dolphin",
            browser = "firefox",
            editor = "code"
        },
        modifiers = {main = "SUPER"}
    }
}

dofile(lua_root .. "/hyde/dispatcher.lua")
dofile(lua_root .. "/hyde/binds.lua")
dofile(lua_root .. "/key_binds.lua")

local failures = 0

local function check(condition, message)
    if not condition then
        failures = failures + 1
        print("    fail: " .. message)
    end
end

local seen = {}
local by_combo = {}
for _, bind in ipairs(binds) do
    local id = canonical(bind.combo)
    local previous = seen[id]

    check(
        previous == nil,
        string.format("combo %s is bound twice, as %q and %q", id, tostring(previous), bind.combo)
    )
    seen[id] = bind.combo
    by_combo[id] = bind

    local tokens = split(bind.combo)
    local key = table.remove(tokens)

    check(
        not key:match("^[Cc][Oo][Dd][Ee]:"),
        string.format("%q uses a keycode, which the Lua bind parser does not accept", bind.combo)
    )

    for _, token in ipairs(tokens) do
        check(
            MODIFIERS[token:upper()] ~= nil,
            string.format("%q holds %q where a modifier is expected", bind.combo, token)
        )
    end

    check(
        type(bind.opts) == "table" and type(bind.opts.description) == "string" and bind.opts.description ~= "",
        string.format("%q has no description", bind.combo)
    )
end

-- The Lua migration must preserve the public keymap documented in
-- KEYBINDINGS.md. Structural checks alone cannot catch a valid bind moving to
-- an unexpected key or pointing at the wrong helper.
local required_defaults = {
    "SUPER + SHIFT + G",
    "SUPER + SHIFT + P",
    "SUPER + CTRL + S",
    "SUPER + SHIFT + W",
    "SUPER + SHIFT + R",
    "SUPER + SHIFT + T",
    "SUPER + ALT + T",
    "ALT + F4",
    "SUPER + DELETE",
    "SHIFT + F11",
    "SUPER + SHIFT + F",
    "SUPER + CTRL + H",
    "SUPER + CTRL + L",
    "SUPER + SHIFT + RIGHT",
    "SUPER + SHIFT + LEFT",
    "SUPER + SHIFT + UP",
    "SUPER + SHIFT + DOWN",
    "SUPER + J",
    "F10",
    "F11",
    "F12",
    "SUPER + ALT + RIGHT",
    "SUPER + ALT + LEFT",
    "SUPER + ALT + UP",
    "SUPER + ALT + DOWN",
    "SUPER + SHIFT + Y",
    "SUPER + SHIFT + U",
    "SUPER + mouse_down",
    "SUPER + mouse_up",
    "SUPER + S",
    "SUPER + SHIFT + S",
    "SUPER + ALT + S"
}

for _, combo in ipairs(required_defaults) do
    check(by_combo[canonical(combo)] ~= nil, string.format("documented combo %s is missing", combo))
end

local screenshot_commands = {
    ["SUPER + CTRL + S"] = "hyde-shell screenshot sc",
    ["SUPER + P"] = "hyde-shell screenshot s",
    ["SUPER + CTRL + P"] = "hyde-shell screenshot sf",
    ["SUPER + ALT + P"] = "hyde-shell screenshot m",
    ["Print"] = "hyde-shell screenshot p"
}

for combo, expected in pairs(screenshot_commands) do
    local bind = by_combo[canonical(combo)]
    check(bind ~= nil, string.format("documented screenshot combo %s is missing", combo))

    if bind then
        local args = type(bind.action) == "table" and bind.action.args or nil
        local command = args and args[1]
        check(
            command == expected,
            string.format("%s runs %q, expected %q", combo, tostring(command), expected)
        )
    end
end

-- Every hyde-shell command reachable from a bind has to exist in the tree.
for _, bind in ipairs(binds) do
    local args = type(bind.action) == "table" and bind.action.args or nil
    local command = args and args[1]

    if type(command) == "string" then
        local name = command:match("^hyde%-shell%s+([%w%._-]+)")
        if name then
            check(command_resolves(name), string.format("%q runs %q, which is not in the tree", bind.combo, name))
        end
    end
end

local gesture_seen = {}
for index, gesture in ipairs(gestures) do
    local where = string.format("gesture %d", index)

    if type(gesture) ~= "table" then
        check(false, where .. " is not a table")
    else
        local fingers = tonumber(gesture.fingers)
        check(fingers ~= nil and fingers >= 3, where .. " needs a finger count of 3 or more")

        local direction = tostring(gesture.direction or "")
        check(
            GESTURE_DIRECTIONS[direction] ~= nil,
            string.format("%s has direction %q, which Hyprland does not accept", where, direction)
        )

        local action = tostring(gesture.action or "")
        check(
            GESTURE_ACTIONS[action] ~= nil,
            string.format("%s has action %q, which Hyprland does not accept", where, action)
        )

        -- One swipe cannot carry two meanings, and Hyprland says nothing when
        -- it does: the second declaration simply shadows the first.
        local id = tostring(fingers) .. "|" .. direction
        check(
            gesture_seen[id] == nil,
            string.format("%d fingers %s is declared twice, as %q and %q", fingers or 0, direction,
                tostring(gesture_seen[id]), action)
        )
        gesture_seen[id] = action
    end
end

print(string.format("    %d bind(s) and %d gesture(s) checked", #binds, #gestures))
os.exit(failures == 0 and 0 or 1)

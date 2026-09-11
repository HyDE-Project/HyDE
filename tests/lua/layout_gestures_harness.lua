-- Loads every shipped layout against a stubbed Hyprland API and checks that
-- workspace-switch and directional-focus gestures use a consistent finger
-- count across layouts.
--
-- The near-universal desktop convention -- and the one layout that already
-- documents its own intent ("Use 3-finger swipes to move between
-- workspaces" in monocle.lua) -- is 3 fingers for workspace switching. A
-- layout that binds "workspace" to a different finger count is a regression,
-- not a variant.

local repo_root = assert(os.getenv("REPO_ROOT"), "REPO_ROOT is not set")
local layouts_dir = repo_root .. "/Configs/.local/share/hypr/lua/layouts"

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

local function list_layout_files()
    local files = {}
    local handle = io.popen("ls '" .. layouts_dir .. "'/*.lua 2>/dev/null")
    if handle then
        for line in handle:lines() do
            files[#files + 1] = line
        end
        handle:close()
    end
    table.sort(files)
    return files
end

local failures = 0
local total_gestures = 0

local function check(condition, message)
    if not condition then
        failures = failures + 1
        print("    fail: " .. message)
    end
end

for _, path in ipairs(list_layout_files()) do
    local name = path:match("([^/]+)%.lua$")
    local gestures = {}

    _G.hl = {
        dsp = dsp_proxy(""),
        dispatch = function()
        end,
        config = function()
        end,
        bind = function()
        end,
        gesture = function(spec)
            gestures[#gestures + 1] = spec
        end
    }
    _G.hyde = {
        config = {
            modifiers = {main = "SUPER"}
        }
    }

    local ok, err = pcall(dofile, path)
    check(ok, string.format("%s failed to load: %s", name, tostring(err)))

    local seen = {}
    for _, gesture in ipairs(gestures) do
        total_gestures = total_gestures + 1

        local fingers = tonumber(gesture.fingers)

        if gesture.action == "workspace" then
            check(
                fingers == 3,
                string.format(
                    "%s binds workspace-switch (%s) to %s fingers, not 3 -- inconsistent with the rest",
                    name, tostring(gesture.direction), tostring(fingers)
                )
            )
        elseif type(gesture.action) == "function" then
            check(
                fingers == 4,
                string.format(
                    "%s binds directional focus (%s) to %s fingers, not 4 -- inconsistent with the rest",
                    name, tostring(gesture.direction), tostring(fingers)
                )
            )
        end

        local id = tostring(fingers) .. "|" .. tostring(gesture.direction)
        check(seen[id] == nil, string.format("%s declares %s twice", name, id))
        seen[id] = true
    end
end

print(string.format("    %d gesture(s) checked across %d layout(s)", total_gestures, #list_layout_files()))
os.exit(failures == 0 and 0 or 1)

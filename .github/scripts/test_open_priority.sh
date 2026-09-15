#!/usr/bin/env sh

set -eu

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
open_lua="$repo_root/Configs/.local/lib/hyde/open.lua"

if ! command -v lua >/dev/null 2>&1; then
    echo "skip: lua is not installed"
    exit 0
fi

[ -f "$open_lua" ] || {
    echo "open.lua is missing: $open_lua" >&2
    exit 1
}

OPEN_LUA="$open_lua" lua <<'LUA'
package.preload["lgi"] = function()
    return {Gio = {}, GLib = {}}
end

local open = assert(loadfile(os.getenv("OPEN_LUA")))("__test__")

local function fake_app(id)
    return {
        get_id = function()
            return id
        end,
        get_name = function()
            return id
        end
    }
end

local function reset()
    local launches = {}
    open.resolve_mime = function()
        return "text/html"
    end
    open.set_default_app_for_mime = function()
        return true
    end
    open.launch_app_for_files = function(appinfo)
        table.insert(launches, appinfo:get_id())
        return true
    end
    open.find_default_app_for_mime = function()
        return fake_app("mime.desktop")
    end
    return launches
end

local function run_case(label, configured_app, fallback, appinfo_map, expected)
    local launches = reset()

    open.get_configured_app_for_keyword = function(keyword)
        if keyword == "web-browser" then
            return configured_app
        end
        return nil
    end

    open.appinfo_from_desktop = function(name)
        local id = appinfo_map[name]
        if id then
            return fake_app(id)
        end
        return nil, "missing"
    end

    local args = {[0] = "hyde-shell", "open", "web-browser", "--std"}
    if fallback then
        table.insert(args, "--fall")
        table.insert(args, fallback)
    end

    local rc = open.cli_main(args)
    assert(rc == 0, label .. ": cli_main failed with " .. tostring(rc))
    assert(#launches == 1, label .. ": expected exactly one launch, got " .. tostring(#launches))
    assert(
        launches[1] == expected,
        label .. ": expected " .. expected .. ", got " .. tostring(launches[1])
    )
end

run_case(
    "configured-first",
    "config.desktop",
    "fallback.desktop",
    {["config.desktop"] = "config.desktop", ["fallback.desktop"] = "fallback.desktop"},
    "config.desktop"
)
run_case("fallback-second", "missing.desktop", "fallback.desktop", {
    ["fallback.desktop"] = "fallback.desktop"
}, "fallback.desktop")
run_case("mime-last", "missing.desktop", "fallback.desktop", {}, "mime.desktop")

print("open.lua priority checked")
LUA

#!/usr/bin/env fish

# Prevent re‑activation
if set -q HYDE_ACTIVATED
    exit 0
end

set -x HYDE_ACTIVATED 1
set -x HYDE_MODE ""
set -x HYPRLAND_CONFIG ""

function setup_xdg
    set -q XDG_CONFIG_HOME; or set -x XDG_CONFIG_HOME "$HOME/.config"
    set -q XDG_CACHE_HOME; or set -x XDG_CACHE_HOME "$HOME/.cache"
    set -q XDG_DATA_HOME; or set -x XDG_DATA_HOME "$HOME/.local/share"
    set -q XDG_STATE_HOME; or set -x XDG_STATE_HOME "$HOME/.local/state"
    set -q XDG_RUNTIME_DIR; or set -x XDG_RUNTIME_DIR "/tmp"
end

function hyde_die
    echo $argv >&2
    return 1
end

function hyde_has
    type -q $argv[1]
end

function find_hyde_lua
    for path in \
        "$XDG_DATA_HOME/hypr/hyde.lua" \
        "/usr/local/share/hypr/hyde.lua" \
        "/usr/share/hypr/hyde.lua"
        if test -f $path
            echo $path
            return 0
        end
    end
    return 1
end


function find_hyprland_bin
    for bin in Hyprland hyprland
        if hyde_has $bin
            command -v $bin
            return 0
        end
    end
    return 1
end

function hyprland_has_lua
    if not hyde_has readelf
        return 0
    end
    set _hyprbin (find_hyprland_bin); or return 1
    if readelf -d $_hyprbin ^/dev/null | string match -q "*NEEDED*lua*"
        return 0
    end
    return 1
end

function check_lua_runtime
    hyde_has lua; or return 1
    hyde_has luarocks; or return 1
end

function setup_lua_mode
    set -l cfg (find_hyde_lua)
    and set -gx HYPRLAND_CONFIG $cfg
    check_lua_runtime; or begin
        echo "Lua runtime incomplete" >&2
        return 1
    end
    hyprland_has_lua; or begin
        echo "Hyprland lacks Lua support" >&2
        return 1
    end
    set -gx HYDE_MODE "lua"
    set -gx HYDE_FEATURE_LUA 1
end

function setup_session
    set -q XDG_CURRENT_DESKTOP; or set -x XDG_CURRENT_DESKTOP "HyDE"
    set -q XDG_SESSION_DESKTOP; or set -x XDG_SESSION_DESKTOP "HyDE"
    set -q XDG_SESSION_TYPE; or set -x XDG_SESSION_TYPE "wayland"
end

function hyde_activate
    setup_xdg
    setup_session
    if setup_lua_mode
        :
    else
        hyde_die "No valid HyDE configuration found"
        return 1
    end
end

hyde_activate

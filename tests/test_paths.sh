#!/usr/bin/env sh
# The Hyprland config resolves its paths through hyde.path, which runs before
# anything else in the session. An environment it cannot cope with takes the
# whole config down, so the resolver has to survive a missing or empty variable
# rather than error on a nil concatenation.

# shellcheck source=tests/lib/common.sh
. "$(dirname -- "$0")/lib/common.sh"

if ! command -v lua >/dev/null 2>&1; then
    skip "lua is not installed"
    finish
fi

path_module="$REPO_ROOT/Configs/.local/share/hypr/lua/hyde/path.lua"
[ -f "$path_module" ] || {
    fail "hyde/path.lua is missing"
    finish
}

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$work_dir/home/.config"

# Prints the resolved value of one field, or "error" when loading blew up.
resolve() {
    lua -e "
        local ok, err = pcall(dofile, [[$path_module]])
        if not ok then
            io.write('error: ', tostring(err))
        else
            io.write(tostring(hyde.path.$1))
        end
    " 2>&1
}

config=$(HOME="$work_dir/home" XDG_CONFIG_HOME='' resolve config)
[ "$config" = "$work_dir/home/.config" ] ||
    fail "an empty XDG_CONFIG_HOME did not fall back to HOME: $config"

config=$(HOME="$work_dir/home" XDG_CONFIG_HOME="$work_dir/elsewhere" resolve config)
[ "$config" = "$work_dir/elsewhere" ] ||
    fail "a set XDG_CONFIG_HOME was not honoured: $config"

# A session without HOME cannot resolve the fallback, but it must not error:
# an unresolved path is skippable, a raised error is not.
config=$(env -u HOME -u XDG_CONFIG_HOME lua -e "
    local ok, err = pcall(dofile, [[$path_module]])
    if not ok then
        io.write('error: ', tostring(err))
    else
        io.write(tostring(hyde.path.config))
    end
" 2>&1)
case $config in
error*) fail "an absent HOME raised instead of leaving the path unresolved: $config" ;;
nil) ;;
*) fail "an absent HOME resolved a path out of nowhere: $config" ;;
esac

# The consumer has to be prepared for that, otherwise the guard above buys
# nothing: dynamic.lua must not concatenate the config path unconditionally.
dynamic="$REPO_ROOT/Configs/.local/share/hypr/lua/dynamic.lua"
grep -q 'os.getenv("XDG_CONFIG_HOME") \.\.' "$dynamic" &&
    fail "dynamic.lua still builds the config path by concatenating os.getenv"

# Every probe of an optional file has to close what it opened; a bare
# `if io.open(path) then` leaks a handle on every config reload.
grep -qE '^[[:space:]]*if io\.open\(' "$dynamic" &&
    fail "dynamic.lua tests a file with io.open without closing the handle"

printf '    %d path field(s) checked\n' 3

finish

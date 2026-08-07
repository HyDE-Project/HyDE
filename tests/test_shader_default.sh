#!/usr/bin/env bash
# A fresh install starts on the shader that changes nothing.
#
# The selector falls back to the first item in name order when no choice has
# been made, and the shaders sort blue-light-filter first, so deploying the
# directory tinted every fresh install blue. The bar reads the same selector,
# and read its state file directly, so a choice made through the shell was
# reported as the default.

. "$(dirname -- "$0")/lib/common.sh"

shaders_dir="$REPO_ROOT/Configs/.config/hypr/shaders"
[ -d "$shaders_dir" ] ||
    { skip "no shaders in this checkout"; finish; }

# The neutral shader has to exist, and it must not be the one that sorts first,
# or the case would pass without the fix.
[ -f "$shaders_dir/disable.frag" ] ||
    fail "the blank shader is missing, a fresh install has nothing neutral to start on"
first=$(find "$shaders_dir" -maxdepth 1 -name '*.frag' -printf '%f\n' | sort | head -n 1)
[ "$first" = "disable.frag" ] &&
    skip "the blank shader sorts first, the fallback cannot be told apart here"

selector="$REPO_ROOT/Configs/.local/lib/hyde/luautils/selector/common.lua"
shaders_lua="$REPO_ROOT/Configs/.local/lib/hyde/shaders.lua"

grep -q 'default_key' "$shaders_lua" ||
    fail "the shader selector names no neutral default, a fresh install starts on ${first%.frag}"
grep -q 'opts.default_key' "$selector" ||
    fail "the selector ignores the default a set names for itself"

# The bar has to report the selection, not the state file alone.
awk '/local function waybar/,/^    end/' "$selector" | grep -q 'current()' ||
    fail "the bar reads the state file directly, so a selection made elsewhere reads as the default"

# Behaviour, in a throwaway home, when lua and the environment are available.
lua_env="$HOME/.local/state/hyde/lua_env"
lua_lib=$(find "$lua_env/lib/lua" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -n 1)
if ! command -v lua >/dev/null 2>&1 || [ -z "$lua_lib" ]; then
    skip "the lua environment is not built, only the source is checked"
    finish
fi

version=$(basename "$lua_lib")
lib="$REPO_ROOT/Configs/.local/lib/hyde"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/.config/hypr" "$work/.local/state/hyde" "$work/.local/share"
cp -a "$shaders_dir" "$work/.config/hypr/"

run_lua() {
    HOME="$work" XDG_CONFIG_HOME="$work/.config" XDG_STATE_HOME="$work/.local/state" \
        XDG_DATA_HOME="$work/.local/share" \
        LUA_PATH="$lib/?.lua;$lib/luautils/?.lua;$lib/luautils/selector/?.lua;$lua_env/share/lua/$version/?.lua;$lua_env/share/lua/$version/?/init.lua;;" \
        LUA_CPATH="$lua_env/lib/lua/$version/?.so;;" \
        lua -e "$1" 2>&1 | tail -n 1
}

rm -rf "$work/.local/state/hyde/lua_state"
current=$(run_lua 'local c = require("shaders").current(); print(c and c.key or "")')
[ "$current" = "disable" ] ||
    fail "a fresh install resolves to the '$current' shader instead of the blank one"

printf 'HYPR_SHADER="%s"\n' "${first%.frag}" >"$work/.local/state/hyde/staterc"
rm -rf "$work/.local/state/hyde/lua_state"
reported=$(run_lua 'require("shaders").waybar()')
case "$reported" in
*"${first%.frag}"*) ;;
*) fail "the bar reports '$reported' for a selection of ${first%.frag}" ;;
esac

printf '    shader default and bar state checked\n'

finish

#!/usr/bin/env sh
# hint-hyprland.py must resolve a Lua-registered ("__lua") bind back to a
# launchable command when hyde/binds.lua's cache has it (#1996).

. "$(dirname -- "$0")/lib/common.sh"

if ! command -v python3 >/dev/null 2>&1; then
    skip "python3 is not installed"
    finish
fi

python3 "$TESTS_DIR/python/check_keybind_hint_resolve.py" ||
    fail "check_keybind_hint_resolve reported defects"

finish

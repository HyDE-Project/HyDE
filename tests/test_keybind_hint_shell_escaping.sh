#!/usr/bin/env sh
# keybinds_hint.sh must not run hint-hyprland.py's output through `echo -e`
# before handing it to rofi. A resolved __lua bind's dispatcher can contain
# the backslash escapes _escape_lua_string() produces (\\ and \n, so the
# generated hl.dsp.exec_cmd("...") call stays valid, single-line Lua) --
# `echo -e` reinterprets exactly those: \\ collapses back to one backslash
# before Lua ever sees it, and \n becomes a real newline, breaking the Lua
# string syntax and tripping keybinds_hint.sh's own single-line dispatch
# check, which then just silently reopens the menu instead of running
# anything. `printf '%s\n'` prints its argument byte-for-byte and does not
# have this problem (caught in review on PR #2068).

. "$(dirname -- "$0")/lib/common.sh"

script="$REPO_ROOT/Configs/.local/lib/hyde/keybinds_hint.sh"
[ -f "$script" ] || {
    fail "keybinds_hint.sh not found at $script"
    finish
}

# Regression guard on the actual script: the exact broken pattern must be
# gone, and the pipe into rofi must go through printf instead.
if grep -n 'echo -e "\$output"' "$script"; then
    fail "keybinds_hint.sh still pipes \$output through 'echo -e' into rofi"
fi
grep -qE "printf '%s\\\\n' \"\\\$output\" \\| rofi" "$script" ||
    fail "keybinds_hint.sh does not pipe \$output into rofi via printf '%s\\n'"

# Demonstrates *why*, rather than just matching a string: an escaped
# dispatcher, exactly as _escape_lua_string() would produce it, must survive
# byte-for-byte through the shell step that's actually used.
escaped_dispatch='hl.dsp.exec_cmd("notify-send \"hi\" \\ok")'

printf_result=$(printf '%s\n' "$escaped_dispatch")
[ "$printf_result" = "$escaped_dispatch" ] ||
    fail "printf '%s\\n' altered the dispatcher string -- it must pass through unchanged"

# The same string through the pattern this test exists to keep out, as
# positive proof the two are not equivalent -- if this ever stops failing,
# the two forms have become the same and the guard above is no longer
# protecting anything.
echo_e_result=$(echo -e "$escaped_dispatch")
if [ "$echo_e_result" = "$escaped_dispatch" ]; then
    fail "echo -e no longer corrupts backslash escapes on this shell -- the reasoning behind this test needs re-checking, not just the pattern match"
fi

# The printf'd result must still be exactly one line (multiple lines is
# what keybinds_hint.sh's own dispatch check rejects) and still valid Lua,
# chaining this check to the same syntax proof
# tests/python/check_keybind_hint_resolve.py already does for the escaping
# itself.
[ "$(printf '%s\n' "$printf_result" | wc -l)" -eq 1 ] ||
    fail "the dispatcher string spans more than one line after printf"

if command -v lua >/dev/null 2>&1; then
    lua -e "local hl = { dsp = { exec_cmd = function() end } }
return ${printf_result}" || fail "the printf-preserved dispatcher is not valid Lua"
fi

finish

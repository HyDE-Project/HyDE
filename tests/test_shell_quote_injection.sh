#!/usr/bin/env sh
# #1901's path.lua fix (PR #1902) left three other call sites with the same
# class of bug, flagged in the issue's own "Additional Information" but not
# fixed there: dconf.lua and batterynotify.lua interpolated a value into a
# shell command with no quoting at all, and altab.lua quoted but did not
# escape, so a value containing a single quote still closes the quote early.
# In all three cases the value traces back to something the local user
# controls (a config.toml setting, or a command name), the same trust
# boundary #1901 was about.

. "$(dirname -- "$0")/lib/common.sh"

if ! command -v lua >/dev/null 2>&1; then
    skip "lua is not installed"
    finish
fi

lua "$TESTS_DIR/lua/shell_quote_harness.lua" || fail "shell_quote_harness reported defects"

dconf_lua="$REPO_ROOT/Configs/.local/lib/hyde/color/dconf.lua"
batterynotify_lua="$REPO_ROOT/Configs/.local/lib/hyde/batterynotify.lua"
altab_lua="$REPO_ROOT/Configs/.local/lib/hyde/altab.lua"

for f in "$dconf_lua" "$batterynotify_lua" "$altab_lua"; do
    [ -f "$f" ] || fail "expected file missing: ${f#"$REPO_ROOT"/}"
done

grep -q 'io\.popen("command -v " \.\. shell_quote(TERMINAL)' "$dconf_lua" ||
    fail "dconf.lua's terminal probe no longer quotes TERMINAL before it reaches the shell"

grep -q "io\.popen('command -v ' \.\. shell_quote(cmd)" "$batterynotify_lua" ||
    fail "batterynotify.lua's has_command no longer quotes cmd before it reaches the shell"

grep -q 'io\.popen("command -v " \.\. shell_quote(cmd) \.\. " 2>/dev/null")' "$altab_lua" ||
    fail "altab.lua's which no longer quotes cmd before it reaches the shell"

finish

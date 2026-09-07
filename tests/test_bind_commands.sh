#!/usr/bin/env sh
# Checks the hl.bind()/hl.dsp.exec_cmd() -> hyde.binds._commands capture
# mechanism hyde/binds.lua adds for #1996, and the cache file it writes.

. "$(dirname -- "$0")/lib/common.sh"

if ! command -v lua >/dev/null 2>&1; then
    skip "lua is not installed"
    finish
fi
if ! command -v python3 >/dev/null 2>&1; then
    skip "python3 is not installed"
    finish
fi

work_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$work_dir"' EXIT

BIND_COMMANDS_TEST_WORK_DIR="$work_dir" lua "$TESTS_DIR/lua/bind_commands_spec.lua" ||
    fail "bind_commands_spec reported defects"

finish

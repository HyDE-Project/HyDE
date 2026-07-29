#!/usr/bin/env sh
# Checks the shipped Lua keybinds for collisions and unreachable binds.

. "$(dirname -- "$0")/lib/common.sh"

if ! command -v lua >/dev/null 2>&1; then
    skip "lua is not installed"
    finish
fi

lua "$TESTS_DIR/lua/bind_harness.lua" || fail "bind_harness reported defects"

finish

#!/usr/bin/env sh
# hl.env("PATH", ...) sets the live compositor's env var, which survives a
# `hyprctl reload` -- appending hyde.path.lib to PATH unconditionally on every
# load grows it by one more copy each time. This is what #1521 reports as
# "duplicated addresses" in PATH after a reload.

. "$(dirname -- "$0")/lib/common.sh"

if ! command -v lua >/dev/null 2>&1; then
    skip "lua is not installed"
    finish
fi

lua "$TESTS_DIR/lua/env_harness.lua" || fail "env_harness reported defects"

finish

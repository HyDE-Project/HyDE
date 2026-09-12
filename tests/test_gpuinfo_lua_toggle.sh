#!/usr/bin/env sh
. "$(dirname -- "$0")/lib/common.sh"

if ! command -v lua >/dev/null 2>&1; then
    skip "lua is not installed"
    finish
fi

lua "$TESTS_DIR/lua/gpuinfo_toggle_spec.lua" || fail "gpuinfo_toggle_spec reported defects"

finish

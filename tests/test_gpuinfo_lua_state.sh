#!/usr/bin/env sh
# Task 1 of the gpuinfo.lua rewrite: state persistence in isolation.

. "$(dirname -- "$0")/lib/common.sh"

if ! command -v lua >/dev/null 2>&1; then
    skip "lua is not installed"
    finish
fi

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

XDG_RUNTIME_DIR="$work_dir" lua "$TESTS_DIR/lua/gpuinfo_state_spec.lua" ||
    fail "gpuinfo_state_spec reported defects"

finish

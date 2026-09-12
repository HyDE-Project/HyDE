#!/usr/bin/env sh
. "$(dirname -- "$0")/lib/common.sh"

if ! command -v lua >/dev/null 2>&1; then
    skip "lua is not installed"
    finish
fi

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

XDG_RUNTIME_DIR="$work_dir" GPUINFO_TEST_WORK_DIR="$work_dir" lua "$TESTS_DIR/lua/gpuinfo_cli_spec.lua" ||
    fail "gpuinfo_cli_spec reported defects"

finish

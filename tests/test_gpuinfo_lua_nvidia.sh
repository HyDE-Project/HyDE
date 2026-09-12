#!/usr/bin/env sh
. "$(dirname -- "$0")/lib/common.sh"

if ! command -v lua >/dev/null 2>&1; then
    skip "lua is not installed"
    finish
fi

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

GPUINFO_TEST_WORK_DIR="$work_dir" lua "$TESTS_DIR/lua/gpuinfo_nvidia_spec.lua" ||
    fail "gpuinfo_nvidia_spec reported defects"

finish

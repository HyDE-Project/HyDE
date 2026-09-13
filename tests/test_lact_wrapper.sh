#!/usr/bin/env sh
# Checks lact.lua's standalone formatting/parsing logic: malformed, missing,
# negative, and out-of-range LACT daemon values must all degrade to valid
# Waybar JSON instead of crashing the module.

. "$(dirname -- "$0")/lib/common.sh"

if ! command -v lua >/dev/null 2>&1; then
    skip "lua is not installed"
    finish
fi

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

# Isolates lact.lua's state file (the --emoji preference) from the real
# machine, same approach test_gpuinfo_lua_e2e.sh uses for gpuinfo.lua.
mkdir -p "$work_dir/runtime"
LACT_TEST_WORK_DIR="$work_dir" XDG_RUNTIME_DIR="$work_dir/runtime" \
    lua "$TESTS_DIR/lua/lact_spec.lua" || fail "lact_spec reported defects"

finish

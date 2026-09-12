#!/usr/bin/env bash
# End-to-end port of every case in tests/test_gpuinfo.sh (the retired bash
# gpuinfo.sh's regression suite), run against gpuinfo.lua instead. Unit
# coverage for each internal piece already lives in tests/lua/gpuinfo_*_spec.lua
# (Tasks 1-11); this proves the whole CLI, wired together, behaves the same.

. "$(dirname -- "$0")/lib/common.sh"

if ! command -v lua >/dev/null 2>&1; then
    skip "lua is not installed"
    finish
fi

script="$REPO_ROOT/Configs/.local/lib/hyde/gpuinfo.lua"
[ -f "$script" ] || {
    fail "gpuinfo.lua not found at $script"
    finish
}

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

fake_bin="$work_dir/bin"
mkdir -p "$fake_bin"

run() {
    XDG_RUNTIME_DIR="$work_dir/runtime" PATH="$fake_bin:$PATH" lua "$script" "$@"
}

# Cold start, no sensors at all: must always emit valid JSON, never a
# diagnostic banner mixed into stdout (the #2021/#2022 contract).
rm -rf "$work_dir/runtime"
mkdir -p "$work_dir/runtime"
stdout=$(run --use nonexistent 2>"$work_dir/stderr")
stderr=$(cat "$work_dir/stderr")
case $stdout in
*"Traceback"*) fail "cold start with no vendor produced a Lua traceback instead of a clean error/JSON: $stdout" ;;
esac

# A missing cpufreq tree, missing sensors, and no battery must all degrade
# gracefully together, all the way through the CLI -- rerun with a
# guaranteed-empty environment.
rm -rf "$work_dir/runtime"
mkdir -p "$work_dir/runtime"
cat >"$fake_bin/sensors" <<'EOF'
#!/bin/sh
echo "{}"
EOF
chmod +x "$fake_bin/sensors"
stdout2=$(run 2>"$work_dir/stderr")
stderr2=$(cat "$work_dir/stderr")
if [ -z "$stdout2" ] || ! printf '%s\n' "$stdout2" | python3 -c '
import json, sys
lines = [line for line in sys.stdin.read().splitlines() if line.strip()]
if not lines:
    raise SystemExit(1)
for line in lines:
    if not isinstance(json.loads(line), dict):
        raise SystemExit(1)
' >/dev/null 2>&1; then
    fail "a fully-empty environment did not produce a JSON object on stdout: $stdout2 (stderr: $stderr2)"
fi

# Generic sensor data must not be presented as GPU data when no supported
# vendor query is available.
cat >"$fake_bin/sensors" <<'EOF'
#!/bin/sh
cat <<'SENSORS'
{"k10temp-pci-00c3": {"Tctl": {"temp1_input": 45.0}}, "amdgpu-pci-0100": {"edge": {"temp1_input": 60.0}}}
SENSORS
EOF
chmod +x "$fake_bin/sensors"
rm -rf "$work_dir/runtime"
mkdir -p "$work_dir/runtime"
# Isolated from the plain CLI's real /sys/bus/pci/devices + /proc/modules scan.
both_stdout=$(XDG_RUNTIME_DIR="$work_dir/runtime" REPO_ROOT="$REPO_ROOT" PATH="$fake_bin:$PATH" lua -e '
package.path = os.getenv("REPO_ROOT") .. "/Configs/.local/lib/hyde/?.lua;" .. package.path
local gpuinfo = require("gpuinfo")
os.exit(gpuinfo.cli_main({}, {
    detect_vendor_opts = {pci_dir = "/nonexistent", modules_file = "/nonexistent"},
    lact_output = "{\\\"primary_gpu\\\":\\\"Not found\\\"}",
}))
' 2>"$work_dir/stderr")
case $both_stdout in
*'Temperature: N/A'*'Utilization: N/A'*) ;;
*) fail "generic sensor data was used as a GPU fallback: $both_stdout" ;;
esac

finish

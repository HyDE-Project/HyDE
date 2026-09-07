#!/usr/bin/env sh
# See the fix comment on general:snap in defaults.lua for why window_gap/
# monitor_gap at 10 (not 1) matters (#1917).

. "$(dirname -- "$0")/lib/common.sh"

if ! command -v lua >/dev/null 2>&1; then
    skip "lua is not installed"
    finish
fi

defaults_lua="$REPO_ROOT/Configs/.local/share/hypr/lua/defaults.lua"
[ -f "$defaults_lua" ] || {
    fail "defaults.lua not found at $defaults_lua"
    finish
}

work_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$work_dir"' EXIT

# Reads a defaults.lua-shaped file with hl.config stubbed to just record what
# it was called with, then prints snap.enabled/window_gap/monitor_gap as
# three lines -- run against both the real shipped file and a synthetic
# fixture reproducing the exact pre-fix (#1917) shape, so the assertion logic
# itself is proven to catch the original bug, not just to pass on today's
# already-fixed file.
read_snap_values() {
    # A trailing "lua -e ... file" argument is treated as a script to run
    # after the -e statement, not as arg[1] for it -- arg[1] would stay nil,
    # and dofile(nil) reads from stdin and hangs forever. Pass the path
    # through the environment instead, matching the rest of this test suite.
    LUA_SNAP_TARGET=$1 lua -e '
        local captured
        hl = { config = function(t) captured = t end }
        local ok, err = pcall(dofile, os.getenv("LUA_SNAP_TARGET"))
        if not ok then
            io.stderr:write("dofile failed: " .. tostring(err) .. "\n")
            os.exit(1)
        end
        local snap = captured and captured.general and captured.general.snap
        if not snap then
            io.stderr:write("no general.snap table was passed to hl.config\n")
            os.exit(1)
        end
        print(tostring(snap.enabled))
        print(tostring(snap.window_gap))
        print(tostring(snap.monitor_gap))
    '
}

# Missing/absent: hl.config never called at all, or called without a
# general.snap table -- must fail loudly, not report empty values as if
# they were valid.
printf '%s\n' '-- no hl.config call at all' >"$work_dir/no-call.lua"
read_snap_values "$work_dir/no-call.lua" >/dev/null 2>&1 &&
    fail "a defaults.lua with no hl.config call at all was accepted"

printf 'hl.config({ decoration = { dim_special = 0.3 } })\n' >"$work_dir/no-snap.lua"
read_snap_values "$work_dir/no-snap.lua" >/dev/null 2>&1 &&
    fail "a defaults.lua with no general.snap table was accepted"

# Reproduces the exact pre-fix (#1917) shape, to prove the assertion below
# actually catches the original bug rather than only ever seeing the
# already-fixed real file.
cat >"$work_dir/broken.lua" <<'LUA'
hl.config({
    general = {
        snap = {
            border_overlap = true,
            enabled = true,
            monitor_gap = 1,
            respect_gaps = true,
            window_gap = 1,
        },
    },
})
LUA
broken_values=$(read_snap_values "$work_dir/broken.lua") || fail "the #1917 fixture itself failed to load"
broken_window_gap=$(printf '%s\n' "$broken_values" | sed -n '2p')
broken_monitor_gap=$(printf '%s\n' "$broken_values" | sed -n '3p')
[ "$broken_window_gap" -lt 10 ] 2>/dev/null ||
    fail "the assertion logic doesn't actually reject the pre-fix 1px value (got window_gap=$broken_window_gap)"
[ "$broken_monitor_gap" -lt 10 ] 2>/dev/null ||
    fail "the assertion logic doesn't actually reject the pre-fix 1px value (got monitor_gap=$broken_monitor_gap)"

# Boundary: exactly the schema-documented default (10) must be accepted, not
# just values comfortably above it.
cat >"$work_dir/boundary.lua" <<'LUA'
hl.config({
    general = {
        snap = {
            enabled = true,
            monitor_gap = 10,
            window_gap = 10,
        },
    },
})
LUA
boundary_values=$(read_snap_values "$work_dir/boundary.lua") || fail "the boundary fixture failed to load"
boundary_window_gap=$(printf '%s\n' "$boundary_values" | sed -n '2p')
boundary_monitor_gap=$(printf '%s\n' "$boundary_values" | sed -n '3p')
[ "$boundary_window_gap" -ge 10 ] 2>/dev/null ||
    fail "a window_gap of exactly 10 (the schema default) was rejected"
[ "$boundary_monitor_gap" -ge 10 ] 2>/dev/null ||
    fail "a monitor_gap of exactly 10 (the schema default) was rejected"

real_values=$(read_snap_values "$defaults_lua") || fail "defaults.lua failed to load under the stubbed hl.config"
real_enabled=$(printf '%s\n' "$real_values" | sed -n '1p')
real_window_gap=$(printf '%s\n' "$real_values" | sed -n '2p')
real_monitor_gap=$(printf '%s\n' "$real_values" | sed -n '3p')

[ "$real_enabled" = "true" ] ||
    fail "general.snap.enabled is not true in the shipped defaults.lua -- snapping is off entirely"

case $real_window_gap in
'' | *[!0-9]*)
    fail "general.snap.window_gap is not a plain non-negative integer: got '$real_window_gap'"
    ;;
*)
    [ "$real_window_gap" -ge 10 ] ||
        fail "general.snap.window_gap is $real_window_gap, below the 10px schema default -- too thin a trigger zone to hit while dragging"
    ;;
esac

case $real_monitor_gap in
'' | *[!0-9]*)
    fail "general.snap.monitor_gap is not a plain non-negative integer: got '$real_monitor_gap'"
    ;;
*)
    [ "$real_monitor_gap" -ge 10 ] ||
        fail "general.snap.monitor_gap is $real_monitor_gap, below the 10px schema default -- too thin a trigger zone to hit while dragging"
    ;;
esac

finish

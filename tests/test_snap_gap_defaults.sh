#!/usr/bin/env sh
# See the fix comment on general:snap in defaults.lua: window_gap/monitor_gap
# are deliberately left unset so Hyprland's own built-in default applies --
# a fixed pixel count doesn't scale across HiDPI monitors, and HyDE shipping
# its own copy of that default just drifts if Hyprland ever changes it
# (#1917, per kRHYME7's review on #2066).

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
# three lines ("nil" for an absent key) -- run against both the real shipped
# file and synthetic fixtures, so the assertion logic itself is proven to
# catch a regression, not just to pass on today's already-fixed file.
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

# Reproduces the original pre-fix (#1917) shape -- an explicit 1px value --
# and proves read_snap_values() reports it as a real, non-nil value. This is
# what makes the real-file check below trustworthy: if it can't tell "1" from
# "nil", a regression back to this exact shape would silently pass.
cat >"$work_dir/broken-1px.lua" <<'LUA'
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
broken_values=$(read_snap_values "$work_dir/broken-1px.lua") || fail "the #1917 1px fixture itself failed to load"
broken_window_gap=$(printf '%s\n' "$broken_values" | sed -n '2p')
broken_monitor_gap=$(printf '%s\n' "$broken_values" | sed -n '3p')
[ "$broken_window_gap" = "1" ] ||
    fail "read_snap_values misreported an explicit 1px window_gap as '$broken_window_gap'"
[ "$broken_monitor_gap" = "1" ] ||
    fail "read_snap_values misreported an explicit 1px monitor_gap as '$broken_monitor_gap'"

# Out-of-spec regression: HyDE re-adding its own copy of Hyprland's default
# (10) is *also* wrong now -- the whole point is that HyDE must not own this
# value at all, not that it must own the "correct" one. A test that only
# checked ">= 10" would happily pass this and miss the regression entirely.
# Proves read_snap_values() reports this shape as non-nil too, same reasoning
# as the 1px fixture above.
cat >"$work_dir/reintroduced-10.lua" <<'LUA'
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
reintroduced_values=$(read_snap_values "$work_dir/reintroduced-10.lua") || fail "the reintroduced-10 fixture itself failed to load"
reintroduced_window_gap=$(printf '%s\n' "$reintroduced_values" | sed -n '2p')
reintroduced_monitor_gap=$(printf '%s\n' "$reintroduced_values" | sed -n '3p')
[ "$reintroduced_window_gap" = "10" ] ||
    fail "read_snap_values misreported a re-added explicit window_gap=10 as '$reintroduced_window_gap'"
[ "$reintroduced_monitor_gap" = "10" ] ||
    fail "read_snap_values misreported a re-added explicit monitor_gap=10 as '$reintroduced_monitor_gap'"

# A minimal, correct fixture: snap enabled, gap keys absent -- must pass.
cat >"$work_dir/correct.lua" <<'LUA'
hl.config({
    general = {
        snap = {
            enabled = true,
            respect_gaps = true,
        },
    },
})
LUA
correct_values=$(read_snap_values "$work_dir/correct.lua") || fail "the correct fixture failed to load"
correct_window_gap=$(printf '%s\n' "$correct_values" | sed -n '2p')
correct_monitor_gap=$(printf '%s\n' "$correct_values" | sed -n '3p')
[ "$correct_window_gap" = "nil" ] ||
    fail "a fixture that never sets window_gap reported one anyway (got $correct_window_gap)"
[ "$correct_monitor_gap" = "nil" ] ||
    fail "a fixture that never sets monitor_gap reported one anyway (got $correct_monitor_gap)"

real_values=$(read_snap_values "$defaults_lua") || fail "defaults.lua failed to load under the stubbed hl.config"
real_enabled=$(printf '%s\n' "$real_values" | sed -n '1p')
real_window_gap=$(printf '%s\n' "$real_values" | sed -n '2p')
real_monitor_gap=$(printf '%s\n' "$real_values" | sed -n '3p')

[ "$real_enabled" = "true" ] ||
    fail "general.snap.enabled is not true in the shipped defaults.lua -- snapping is off entirely"

[ "$real_window_gap" = "nil" ] ||
    fail "general.snap.window_gap is set to $real_window_gap in the shipped defaults.lua -- it should be left unset so Hyprland's own default applies"

[ "$real_monitor_gap" = "nil" ] ||
    fail "general.snap.monitor_gap is set to $real_monitor_gap in the shipped defaults.lua -- it should be left unset so Hyprland's own default applies"

finish

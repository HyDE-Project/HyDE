#!/usr/bin/env sh
# Every layout's touchpad gestures must agree on which finger count switches
# workspaces. dwindle/master/scrolling/scrolling-down bound it to 4 fingers
# while monocle bound it to 3 (its own comment: "Use 3-finger swipes to move
# between workspaces") -- all five came out of the same Lua migration commit,
# so this was drift, not an intentional per-layout difference, and it is
# exactly what #1941/#1945 report as "3-finger swipe broken, falls back to
# 4-finger".

. "$(dirname -- "$0")/lib/common.sh"

if ! command -v lua >/dev/null 2>&1; then
    skip "lua is not installed"
    finish
fi

lua "$TESTS_DIR/lua/layout_gestures_harness.lua" || fail "layout_gestures_harness reported defects"

finish

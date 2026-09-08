#!/usr/bin/env sh
# swaync's layer-shell surface spans the full monitor height (fit-to-screen
# in config.json), so without an explicit transparent background on its GTK
# window node, GTK's default dark background paints across that whole area
# -- a black rectangle next to every notification, not just the popup (#1611).

. "$(dirname -- "$0")/lib/common.sh"

dcol="$REPO_ROOT/Configs/.local/share/wallbash/theme/swaync.dcol"
[ -f "$dcol" ] || {
    fail "swaync.dcol not found at $dcol"
    finish
}

grep -Eq 'notificationwindow,[[:space:]]*blankwindow[[:space:]]*\{' "$dcol" ||
    fail "swaync.dcol has no rule for the notificationwindow/blankwindow GTK nodes"

awk '/notificationwindow,[ \t]*blankwindow[ \t]*\{/,/\}/' "$dcol" | grep -q 'background:[[:space:]]*transparent' ||
    fail "the notificationwindow/blankwindow rule does not set a transparent background"

finish

#!/usr/bin/env sh
# batterynotify.lua's icon names must be valid freedesktop icon-naming-spec
# battery icons -- driving the full notification pipeline (GLib/luv timers,
# /sys/class/power_supply reads, D-Bus) just to observe one string is more
# than this bug needs, so this checks the source text directly, the same way
# tests/test_monitor_scale.sh checks for a leftover pattern rather than
# running the function it's guarding against every possible input.
#
# "battery-N-charging" and "xfce4-battery-critical" aren't freedesktop names
# at all -- icon themes that only ship the spec's battery-level-N[-charging]
# -symbolic set (e.g. Tela-circle-dracula, per the report) resolved neither,
# so the notification showed with no icon (#798).

. "$(dirname -- "$0")/lib/common.sh"

script="$REPO_ROOT/Configs/.local/lib/hyde/batterynotify.lua"
[ -f "$script" ] || {
    fail "batterynotify.lua not found at $script"
    finish
}

grep -q "xfce4-battery-critical" "$script" &&
    fail "batterynotify.lua still requests the non-standard 'xfce4-battery-critical' icon"

grep -qE "'battery-' \.\. tostring\(\(steps > 0\) and steps or [0-9]+\) \.\. '-charging'" "$script" &&
    fail "batterynotify.lua still builds a plain 'battery-N-charging' icon name, not the freedesktop battery-level-N-charging-symbolic form"

for name in "battery-empty-symbolic" "battery-level-.*-charging-symbolic"; do
    grep -qE "$name" "$script" ||
        fail "batterynotify.lua no longer requests an icon matching '$name'"
done

# Every icon name actually passed to notify_send must match the freedesktop
# battery icon pattern -- catches a typo'd or malformed replacement, not just
# the two specific strings above.
icons=$(grep -oE "'(battery-[a-z0-9-]*-symbolic|xfce4[a-z0-9-]*)'" "$script" | tr -d "'" | sort -u)
[ -n "$icons" ] || fail "no battery icon names found in batterynotify.lua at all -- the patterns above may be stale"
while IFS= read -r icon; do
    case "$icon" in
    battery-empty-symbolic | battery-full-symbolic | battery-good-symbolic | \
        battery-low-symbolic | battery-caution-symbolic | battery-missing-symbolic | \
        battery-full-charging-symbolic | battery-level-[0-9]*-symbolic | \
        battery-level-[0-9]*-charging-symbolic) ;;
    *) fail "'$icon' does not look like a freedesktop battery icon name" ;;
    esac
done <<EOF
$icons
EOF

finish

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

if command -v python3 >/dev/null 2>&1; then
    python3 "$TESTS_DIR/python/check_batterynotify_notify_calls.py" "$script" ||
        fail "a notify_send(...) call does not pass an { urgency = ... } options table -- notify_mod.send reads opts.urgency/opts.icon, so a bare string/positional 4th arg silently loses both"

    work_dir=$(mktemp -d) || exit 1
    trap 'rm -rf "$work_dir"' EXIT

    # Out-of-spec: a call nested three function-calls deep (well past what
    # any real call in this file needs) must still be found and checked --
    # a fixed-one-level-of-parens regex would silently drop it from the
    # results instead of failing loudly, so a missing options table on a
    # deeply-nested call would never be caught.
    cat >"$work_dir/deep-ok.lua" <<'LUA'
notify_send('Deep', string.format('%s', tostring(compute(x, y))), { urgency = 'critical', icon = 'battery-full-symbolic' })
LUA
    python3 "$TESTS_DIR/python/check_batterynotify_notify_calls.py" "$work_dir/deep-ok.lua" ||
        fail "a deeply-nested notify_send call with both urgency and icon was rejected"

    cat >"$work_dir/deep-missing-icon.lua" <<'LUA'
notify_send('Deep', string.format('%s', tostring(compute(x, y))), { urgency = 'critical' })
LUA
    python3 "$TESTS_DIR/python/check_batterynotify_notify_calls.py" "$work_dir/deep-missing-icon.lua" >/dev/null 2>&1 &&
        fail "a deeply-nested notify_send call missing icon was accepted -- the balanced-paren scanner may have silently dropped it instead of checking it"

    # Missing icon on an otherwise well-formed (unnested) call.
    cat >"$work_dir/urgency-only.lua" <<'LUA'
notify_send('X', 'Y', { urgency = 'critical' })
LUA
    python3 "$TESTS_DIR/python/check_batterynotify_notify_calls.py" "$work_dir/urgency-only.lua" >/dev/null 2>&1 &&
        fail "a notify_send call with urgency but no icon was accepted"

    # Out-of-spec: a literal ')' inside a Lua string argument (a battery
    # percentage message can legitimately contain one) must not be mistaken
    # for the call's own closing paren -- a naive char-by-char depth counter
    # would truncate the call there and report a false "missing" failure.
    cat >"$work_dir/paren-in-string.lua" <<'LUA'
notify_send('Battery at 20%)', 'body', { urgency = 'critical', icon = 'battery-full-symbolic' })
LUA
    python3 "$TESTS_DIR/python/check_batterynotify_notify_calls.py" "$work_dir/paren-in-string.lua" ||
        fail "a ')' inside a string argument made a well-formed notify_send call fail"
else
    skip "python3 is not installed"
fi

# The UNPLUG-threshold notification (mirrors the Battery Low block below it,
# same interval throttle) used to compute an icon and never call
# notify_send at all.
awk '/unplug_charger_threshold and not string\.find/,/^    end$/' "$script" | grep -q "notify_send" ||
    fail "the UNPLUG-threshold block still never calls notify_send"

grep -qE "'battery-' \.\. tostring\(\(steps > 0\) and steps or [0-9]+\) \.\. '-charging'" "$script" &&
    fail "batterynotify.lua still builds a plain 'battery-N-charging' icon name, not the freedesktop battery-level-N-charging-symbolic form"

for name in "battery-empty-symbolic" "battery-level-.*-charging-symbolic"; do
    grep -qE "$name" "$script" ||
        fail "batterynotify.lua no longer requests an icon matching '$name'"
done

# Every icon name actually passed to notify_send must match the freedesktop
# battery icon pattern -- catches a typo'd or malformed replacement, not just
# the two specific strings above. Fully-literal names are pulled directly;
# the dynamic ones ('prefix' .. tostring(...) .. 'suffix') are reconstructed
# with a representative steps value AND the expression's own fallback value,
# so a typo in either the literal parts or the fallback number is caught --
# grep alone can't do this, since it never sees the concatenated result.
icons=$(grep -oE "'(battery-[a-z0-9-]*-symbolic|xfce4[a-z0-9-]*)'" "$script" | tr -d "'" | sort -u)

dynamic=$(grep -oE "local icon = '[a-z-]+' \.\. tostring\(\(steps > 0\) and steps or [0-9]+\) \.\. '[a-z-]+'" "$script")
[ -n "$dynamic" ] || fail "no dynamically-built icon expressions found -- the extraction pattern below may be stale"
while IFS= read -r expr; do
    prefix=$(printf '%s\n' "$expr" | sed -E "s/^local icon = '([a-z-]+)'.*/\1/")
    fallback=$(printf '%s\n' "$expr" | sed -E "s/.*or ([0-9]+)\).*/\1/")
    suffix=$(printf '%s\n' "$expr" | sed -E "s/.*\.\. '([a-z-]+)'\$/\1/")
    icons="${icons}
${prefix}50${suffix}
${prefix}${fallback}${suffix}"
done <<EOF
$dynamic
EOF

icons=$(printf '%s\n' "$icons" | sort -u)
[ -n "$icons" ] || fail "no battery icon names found in batterynotify.lua at all -- the patterns above may be stale"
while IFS= read -r icon; do
    [ -n "$icon" ] || continue
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

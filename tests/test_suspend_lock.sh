#!/usr/bin/env sh
# Every "systemctl suspend"/"systemctl hibernate" call site in this repo
# relies on the screen being locked before the system actually sleeps.
# wlogout's own layout used to do that itself with
# "lockscreen.sh & disown && systemctl suspend" -- a bare background job with
# no synchronization, racing the suspend that follows it on the same line
# (#1536). Every other call site (waybar's power menus, the battery-critical
# auto-suspend, hypridle's own idle-timeout suspend) never attempted a lock at
# all and depended on nothing.
#
# The fix is centralized: hypridle's before_sleep_cmd fires on every sleep
# (suspend or hibernate, regardless of what triggered it). wlogout's manual
# pre-lock is now redundant and removed.
#
# before_sleep_cmd alone is not enough, though. Per hyprwm/hypridle's own
# src/core/Hypridle.cpp, general:inhibit_sleep=2 ("auto", the default) only
# grants the race-free "wait until the session actually reports itself
# locked" behavior (SLEEP_INHIBIT_LOCK_NOTIFY, via the Wayland lock-notify
# protocol) when lock_cmd/before_sleep_cmd literally contain the substring
# "hyprlock". HyDE's lock_cmd is `hyde-shell lockscreen.sh`, which resolves
# to the real locker indirectly at runtime -- the literal string "hyprlock"
# never appears in hypridle.conf, so that heuristic can never match, and
# "auto" silently falls back to SLEEP_INHIBIT_NORMAL, which spawns
# before_sleep_cmd and releases hypridle's own systemd sleep-inhibitor right
# away without waiting for it to do anything -- the exact same
# fire-and-forget race this fix exists to remove, just moved from a shell
# script into hypridle's C++. inhibit_sleep=3 ("wait until locked") forces
# the race-free mode unconditionally, independent of what the command
# strings say.

. "$(dirname -- "$0")/lib/common.sh"

hypridle_conf="$REPO_ROOT/Configs/.config/hypr/hypridle.conf"
wlogout_layout="$REPO_ROOT/Configs/.config/wlogout/layout_1"

[ -f "$hypridle_conf" ] || {
    fail "hypridle.conf not found at $hypridle_conf"
    finish
}
[ -f "$wlogout_layout" ] || {
    fail "wlogout layout_1 not found at $wlogout_layout"
    finish
}

# Extracted so it can be run against synthetic fixtures below, not just the
# one real shipped file -- otherwise a subtly wrong regex here (e.g. one that
# accidentally matches a commented-out line) would give a silent false pass
# forever, since the real file only ever exercises the "correct" path once
# this fix lands.
has_active_lock_before_sleep() {
    conf_file=$1
    line=$(grep -E '^[[:space:]]*before_sleep_cmd[[:space:]]*=' "$conf_file")
    [ -n "$line" ] || return 1
    case $line in
    *lock*) return 0 ;;
    *) return 1 ;;
    esac
}

# Same reasoning, for the mode that actually makes before_sleep_cmd
# synchronous. Anything other than an active "inhibit_sleep = 3" leaves
# HyDE's hyprlock-via-hyde-shell indirection undetected by hypridle's own
# substring heuristic (mode 2, "auto") and silently degrades to the
# fire-and-forget mode (0 disables it outright, 1 is fire-and-forget always).
has_forced_lock_notify() {
    conf_file=$1
    line=$(grep -E '^[[:space:]]*inhibit_sleep[[:space:]]*=' "$conf_file")
    [ -n "$line" ] || return 1
    # Exact value comparison, not substring: "inhibit_sleep = 30" is a
    # different (invalid) mode and must not match on "contains '3'".
    value=$(printf '%s\n' "$line" | sed -E 's/^[[:space:]]*inhibit_sleep[[:space:]]*=[[:space:]]*//; s/#.*//; s/[[:space:]]+$//')
    [ "$value" = "3" ]
}

work_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$work_dir"' EXIT

# Missing input: no such file at all.
has_active_lock_before_sleep "$work_dir/no-such-file" 2>/dev/null &&
    fail "a missing conf file was treated as having an active before_sleep_cmd"

# Missing input: file exists but the key was never set (the pre-#1536 state
# of hypridle.conf -- the setting existed only as a comment).
printf '# before_sleep_cmd =     # command ran before sleep\n' >"$work_dir/commented.conf"
has_active_lock_before_sleep "$work_dir/commented.conf" &&
    fail "a commented-out before_sleep_cmd was treated as active"

# Malformed/out-of-spec: the key is active but has no value at all.
printf 'before_sleep_cmd =\n' >"$work_dir/empty-value.conf"
has_active_lock_before_sleep "$work_dir/empty-value.conf" &&
    fail "an empty before_sleep_cmd value was treated as locking the session"

# Malformed/out-of-spec: active and non-empty, but doesn't lock anything --
# a plausible typo/copy-paste (e.g. someone meaning to reuse another
# listener's on-timeout command here).
printf 'before_sleep_cmd = notify-send "going to sleep"\n' >"$work_dir/no-lock.conf"
has_active_lock_before_sleep "$work_dir/no-lock.conf" &&
    fail "a before_sleep_cmd with no locking command was accepted"

# Boundary: indentation/whitespace variants around an otherwise-correct line
# must still be recognized as active.
printf '  before_sleep_cmd=loginctl lock-session\n' >"$work_dir/tight.conf"
has_active_lock_before_sleep "$work_dir/tight.conf" ||
    fail "a tightly-spaced but valid before_sleep_cmd was rejected"

printf 'before_sleep_cmd = loginctl lock-session # lock before sleep\n' >"$work_dir/correct.conf"
has_active_lock_before_sleep "$work_dir/correct.conf" ||
    fail "a correctly-set before_sleep_cmd was rejected"

# The real shipped config must itself satisfy the same check.
has_active_lock_before_sleep "$hypridle_conf" ||
    fail "hypridle.conf has no active, locking before_sleep_cmd -- suspend/hibernate can happen before the screen locks"

# Missing input: key never set at all (hypridle then defaults to
# inhibit_sleep=2 "auto", which does not detect HyDE's lock_cmd).
: >"$work_dir/no-inhibit-key.conf"
has_forced_lock_notify "$work_dir/no-inhibit-key.conf" &&
    fail "a conf with no inhibit_sleep key was treated as forcing lock-notify mode"

# The three modes that all silently keep the fire-and-forget race for HyDE's
# lock_cmd (0=disabled, 1=always fire-and-forget, 2=auto but never detects
# the hyde-shell indirection) must all be rejected, not just "unset".
for bad_mode in 0 1 2; do
    printf 'inhibit_sleep = %s\n' "$bad_mode" >"$work_dir/mode-$bad_mode.conf"
    has_forced_lock_notify "$work_dir/mode-$bad_mode.conf" &&
        fail "inhibit_sleep = $bad_mode was accepted as forcing lock-notify mode"
done

# Malformed/out-of-spec: a value that merely contains the digit "3" as a
# substring (not equal to it) must not pass on a loose match.
printf 'inhibit_sleep = 30\n' >"$work_dir/mode-30.conf"
has_forced_lock_notify "$work_dir/mode-30.conf" &&
    fail "inhibit_sleep = 30 was accepted as if it were mode 3 (substring match bug)"

printf 'inhibit_sleep = 3\n' >"$work_dir/mode-3.conf"
has_forced_lock_notify "$work_dir/mode-3.conf" ||
    fail "inhibit_sleep = 3 was rejected"

# The real shipped config must force mode 3, not rely on "auto".
has_forced_lock_notify "$hypridle_conf" ||
    fail "hypridle.conf does not force inhibit_sleep = 3 -- with lock_cmd going through hyde-shell, 'auto' silently falls back to the fire-and-forget mode"

# wlogout's suspend action must not carry its own manual pre-lock anymore --
# that was the racy "fire a background job, then immediately suspend on the
# same line" pattern this fix removes in favor of the centralized one above.
suspend_action=$(grep -A2 '"label": "suspend"' "$wlogout_layout" | grep '"action"')
case $suspend_action in
*disown*) fail "wlogout's suspend action still backgrounds its own lock call: $suspend_action" ;;
esac
case $suspend_action in
*'systemctl suspend'*) ;;
*) fail "wlogout's suspend action no longer calls systemctl suspend: $suspend_action" ;;
esac

# Regression guard, structural rather than a literal string match: a lone
# (non-doubled) '&' followed on the same line by "systemctl suspend/hibernate"
# is the actual bug class -- "backgrounded job, then unconditionally sleep
# right after" -- regardless of whether it's spelled with "disown", a
# different command being backgrounded, or copy-pasted into a different
# layout/theme file. A combination nobody has written yet is still the same
# bug if it appears.
race_pattern='[^&]&[^&].*systemctl[[:space:]]+(suspend|hibernate)'
if grep -rEn "$race_pattern" "$REPO_ROOT/Configs" 2>/dev/null; then
    fail "a backgrounded-job-then-immediate-sleep pattern still exists somewhere in Configs/"
fi
# Sanity check on the pattern itself: legitimate synchronous "&&" chaining
# (no backgrounding at all) must not be flagged as a false positive.
printf 'notify-send "bye" && systemctl suspend\n' | grep -Eq "$race_pattern" &&
    fail "the race-pattern regex flags plain && chaining as if it backgrounded a job"

# Out-of-spec: hibernate never had any lock attempt at all, manual or
# otherwise -- confirm it stays a plain dispatch (no stray backgrounding) so
# it keeps relying on the same centralized before_sleep_cmd rather than
# regaining a second, inconsistent one-off fix.
hibernate_action=$(grep -A2 '"label": "hibernate"' "$wlogout_layout" | grep '"action"')
case $hibernate_action in
*disown*) fail "wlogout's hibernate action unexpectedly backgrounds a lock call: $hibernate_action" ;;
esac
case $hibernate_action in
*'systemctl hibernate'*) ;;
*) fail "wlogout's hibernate action no longer calls systemctl hibernate: $hibernate_action" ;;
esac

finish

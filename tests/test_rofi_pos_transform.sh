#!/usr/bin/env sh
# get_rofi_pos positions cursor-relative rofi menus (cliphist, emoji/glyph
# picker, hyprlock) by comparing the cursor position against the focused
# monitor's width/height from `hyprctl -j monitors`. Verified against a real
# headless Hyprland output: those fields are the monitor's pre-transform mode
# and are NOT swapped for a 90/270-degree rotation. On a portrait monitor the
# comparison was still done against the landscape resolution, so menus landed
# off-screen or wrapped, worst near the bottom-right (#975).

. "$(dirname -- "$0")/lib/common.sh"

if ! command -v jq >/dev/null 2>&1; then
    skip "jq is not installed"
    finish
fi

lib_dir="$REPO_ROOT/Configs/.local/lib/hyde"
work_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$work_dir"' EXIT

bin_dir="$work_dir/bin"
mkdir -p "$bin_dir" "$work_dir/home/.config"

# cursor_x/cursor_y/mon_w/mon_h/transform_field are threaded through env vars
# so the same stub covers every case below without rewriting it each time.
# transform_field is the raw jq fragment for the "transform" key -- passing
# an empty string omits the key entirely, to cover a monitors payload from a
# hyprctl too old to report it. mon_x/mon_y/reserved default to 0/0/all-zero
# so most cases don't have to think about them, but can be overridden to
# exercise the monitor-offset and reserved-margin arithmetic too.
cat > "$bin_dir/hyprctl" << 'STUB'
#!/usr/bin/env sh
case "$1 $2" in
"cursorpos -j")
    printf '{"x":%s,"y":%s}\n' "$CURSOR_X" "$CURSOR_Y"
    ;;
"-j monitors")
    printf '[{"focused":true,"width":%s,"height":%s,"scale":1,"x":%s,"y":%s,"reserved":[%s]%s}]\n' \
        "$MON_W" "$MON_H" "${MON_X:-0}" "${MON_Y:-0}" "${RESERVED:-0,0,0,0}" "$TRANSFORM_FIELD"
    ;;
esac
STUB
chmod +x "$bin_dir/hyprctl"

get_pos() {
    HOME="$work_dir/home" \
        XDG_CONFIG_HOME="$work_dir/home/.config" \
        HYPRLAND_INSTANCE_SIGNATURE=test \
        CURSOR_X="$1" CURSOR_Y="$2" \
        MON_W="$3" MON_H="$4" \
        TRANSFORM_FIELD="$5" \
        MON_X="${6:-0}" MON_Y="${7:-0}" \
        RESERVED="${8:-0,0,0,0}" \
        PATH="$bin_dir:$PATH" \
        bash -c '. "$1/globalcontrol.sh" >/dev/null 2>&1; get_rofi_pos' _ "$lib_dir"
}

# Baseline, transform 0 (normal): a 1920x1080 landscape monitor, cursor near
# the bottom-right -- must anchor east/south. Regression guard for the
# unrotated case the fix must not disturb.
pos=$(get_pos 1800 1000 1920 1080 ',"transform":0')
case "$pos" in
*"east"*"south"*) ;;
*) fail "transform 0, cursor near bottom-right: expected east/south, got '$pos'" ;;
esac

# Boundary: the anchor decision uses -ge, so a cursor sitting exactly on the
# midpoint of a 1920x1080 monitor (960, 540) must fall on the east/south side
# of the split, not just comfortably past it -- and the offsets computed from
# that exact point must match precisely, not merely land in the right corner.
pos=$(get_pos 960 540 1920 1080 ',"transform":0')
case "$pos" in
*"east"*"south"*"x-offset:-960px"*"y-offset:-540px"*) ;;
*) fail "cursor exactly at the monitor's midpoint (960,540): expected east/south with x-offset:-960px/y-offset:-540px, got '$pos'" ;;
esac

# Boundary: the (0,0) corner, combined with non-zero reserved margins (e.g. a
# bar reserving space on each edge) -- exercises offRes[0]/offRes[1], which
# every other case in this file leaves at zero and so never actually checks.
pos=$(get_pos 0 0 1920 1080 ',"transform":0' 0 0 '10,20,30,40')
case "$pos" in
*"west"*"north"*"x-offset:-10px"*"y-offset:-20px"*) ;;
*) fail "cursor at (0,0) with reserved margins [10,20,30,40]: expected west/north with x-offset:-10px/y-offset:-20px, got '$pos'" ;;
esac

# Out-of-spec for every other case here, but a normal multi-monitor layout:
# the focused monitor sits at a non-zero position (x=1920, as the second
# monitor in a side-by-side layout). Every other case leaves monRes[3]/
# monRes[4] at zero, so the curPos-minus-monitor-origin subtraction has never
# actually been exercised until this case.
pos=$(get_pos 2620 300 1920 1080 ',"transform":0' 1920 0)
case "$pos" in
*"west"*"north"*"x-offset:700px"*"y-offset:300px"*) ;;
*) fail "cursor at (2620,300) on a monitor positioned at x=1920: expected west/north with x-offset:700px/y-offset:300px, got '$pos'" ;;
esac

# transform 1 (90 degrees): the SAME 1920x1080 mode now displays as a
# 1080x1920 portrait screen. A cursor at (900, 1800) sits in the lower-right
# quadrant of that actual 1080x1920 screen. Without swapping width/height,
# 900 compares as the left half of a (wrongly) 1920-wide screen (west, not
# east) and 1800 exceeds the (wrongly) 1080-tall screen entirely, producing a
# nonsensical y-offset -- reproducing "spawns off screen" from #975.
pos=$(get_pos 900 1800 1920 1080 ',"transform":1')
case "$pos" in
*"east"*"south"*) ;;
*) fail "transform 1, cursor near bottom-right of the rotated screen: expected east/south, got '$pos'" ;;
esac

# transform 3 (270 degrees) is the other portrait rotation -- odd like 1, so
# it must swap too. Cursor near the top-left of the 1080x1920 screen this
# time, to also prove north/west still comes out right post-swap.
pos=$(get_pos 100 100 1920 1080 ',"transform":3')
case "$pos" in
*"west"*"north"*) ;;
*) fail "transform 3, cursor near top-left of the rotated screen: expected west/north, got '$pos'" ;;
esac

# transform 2 (180 degrees) is even -- upright dimensions, no swap needed.
# Must behave exactly like transform 0 for the same cursor position.
pos=$(get_pos 1800 1000 1920 1080 ',"transform":2')
case "$pos" in
*"east"*"south"*) ;;
*) fail "transform 2 (even, no swap expected), cursor near bottom-right: expected east/south, got '$pos'" ;;
esac

# Missing/absent: a monitors payload with no "transform" key at all (older
# hyprctl) must not crash the arithmetic, and must fall back to no swap.
pos=$(get_pos 1800 1000 1920 1080 '')
status=$?
[ "$status" -eq 0 ] || fail "a monitors payload with no transform field made get_rofi_pos exit $status"
case "$pos" in
*"east"*"south"*) ;;
*) fail "missing transform field: expected the no-swap fallback (east/south), got '$pos'" ;;
esac

# Out-of-spec: a missing "transform" key makes jq emit the bare word null,
# and bash arithmetic resolves an unquoted identifier as a variable name --
# so without an explicit `// 0` fallback in the jq expression, a shell that
# happens to already have a variable literally named "null" in scope hijacks
# the swap decision instead of the intended no-swap default. Cursor x=700 on
# a 1920x1080 monitor is chosen deliberately: it reads "west" against the
# real width (1920) but "east" against the wrongly-swapped one (1080) -- a
# cursor position that reads the same either way (as an earlier version of
# this test used) would pass regardless of whether the hijack happened.
pos=$(HOME="$work_dir/home" \
    XDG_CONFIG_HOME="$work_dir/home/.config" \
    HYPRLAND_INSTANCE_SIGNATURE=test \
    CURSOR_X=700 CURSOR_Y=100 MON_W=1920 MON_H=1080 TRANSFORM_FIELD='' \
    null=1 \
    PATH="$bin_dir:$PATH" \
    bash -c '. "$1/globalcontrol.sh" >/dev/null 2>&1; get_rofi_pos' _ "$lib_dir")
case "$pos" in
*"west"*"north"*) ;;
*) fail "missing transform field with a coincidental 'null' variable in scope: expected the no-swap fallback (west/north), got '$pos'" ;;
esac

# Missing/absent: no HYPRLAND_INSTANCE_SIGNATURE (not running inside a
# Hyprland session, or the guard rail regressed) must fail loudly and never
# reach hyprctl at all -- shadow it with a stub that fails the test outright
# if invoked, as proof the guard clause short-circuits before any query.
no_session_bin_dir="$work_dir/bin_no_session"
mkdir -p "$no_session_bin_dir"
cat > "$no_session_bin_dir/hyprctl" << 'STUB'
#!/usr/bin/env sh
echo "hyprctl was invoked without a Hyprland session -- get_rofi_pos's guard did not short-circuit" >&2
exit 99
STUB
chmod +x "$no_session_bin_dir/hyprctl"

out=$(HOME="$work_dir/home" \
    XDG_CONFIG_HOME="$work_dir/home/.config" \
    HYPRLAND_INSTANCE_SIGNATURE="" \
    PATH="$no_session_bin_dir:$PATH" \
    bash -c '. "$1/globalcontrol.sh" >/dev/null 2>&1; get_rofi_pos' _ "$lib_dir" 2>&1)
status=$?
[ "$status" -eq 1 ] || fail "an unset HYPRLAND_INSTANCE_SIGNATURE made get_rofi_pos exit $status, not 1"
[ -z "$out" ] || fail "an unset HYPRLAND_INSTANCE_SIGNATURE still produced output: $out"

finish

#!/usr/bin/env sh
# A monitor scale is read as a number, not as text with the dot deleted.
#
# Every menu sizes itself by dividing a pixel count by the scale. Deleting the
# dot makes the divisor depend on how many decimals the compositor printed, so
# a scale reported as 1 rather than 1.00 shrinks the divisor a hundredfold and
# the surface asked for is far larger than any the compositor can hand back.

. "$(dirname -- "$0")/lib/common.sh"

lib_dir="$REPO_ROOT/Configs/.local/lib/hyde"

probe() {
    HOME="$work_dir/home" \
        XDG_CONFIG_HOME="$work_dir/home/.config" \
        bash -c '. "$1/globalcontrol.sh" >/dev/null 2>&1; get_monitor_scale "$2"' _ "$lib_dir" "$1" 2>/dev/null
}

work_dir=$(mktemp -d) || exit 1
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$work_dir/home/.config"

for pair in '1 100' '1.0 100' '1.00 100' '1.000000 100' '1.25 125' '1.5 150' '2 200' '0 100'; do
    raw=${pair% *}
    want=${pair#* }
    got=$(probe "$raw")
    [ "$got" = "$want" ] ||
        fail "a scale of $raw reads as $got, not $want"
done

# An empty argument makes get_monitor_scale fall back to querying the live
# compositor via hyprctl, so "unreadable" has to be forced by making that
# query fail -- otherwise this case silently tests the real session's scale
# instead of the fallback path, and passes or fails depending on whether the
# machine running the suite has a Hyprland session open.
unreadable_bin_dir="$work_dir/bin_unreadable"
mkdir -p "$unreadable_bin_dir"
cat > "$unreadable_bin_dir/hyprctl" << 'STUB'
#!/usr/bin/env sh
exit 1
STUB
chmod +x "$unreadable_bin_dir/hyprctl"

got=$(HOME="$work_dir/home" \
    XDG_CONFIG_HOME="$work_dir/home/.config" \
    PATH="$unreadable_bin_dir:$PATH" \
    bash -c '. "$1/globalcontrol.sh" >/dev/null 2>&1; get_monitor_scale ""' _ "$lib_dir" 2>/dev/null)
[ "$got" = "100" ] ||
    fail "an unreadable scale reads as $got, not 100"

leftovers=$(grep -rn 'scale[^=]*|[[:space:]]*sed[[:space:]]*"*'"'"'*s/\\\./' "$lib_dir" 2>/dev/null | wc -l)
[ "$leftovers" -eq 0 ] ||
    fail "$leftovers script(s) still derive a scale by deleting the dot"

if [ "$(grep -rlc 'scale.*//\.//}' "$lib_dir" 2>/dev/null | wc -l)" -ne 0 ]; then
    fail "a script still strips the dot out of a scale by expansion"
fi

grep -q 'export -f .*get_monitor_scale' "$lib_dir/globalcontrol.sh" ||
    fail "the helper is not exported, so a function that calls it breaks in a child shell"

exported=$(HOME="$work_dir/home" XDG_CONFIG_HOME="$work_dir/home/.config" \
    bash -c '. "$1/globalcontrol.sh" >/dev/null 2>&1; bash -c "get_monitor_scale 1.5"' _ "$lib_dir" 2>/dev/null)
[ "$exported" = "150" ] ||
    fail "a child shell reads the scale as '$exported', not 150"

for caller in $(grep -rl 'get_monitor_scale' "$lib_dir" 2>/dev/null); do
    case "$(basename "$caller")" in
        globalcontrol.sh) continue ;;
    esac
    grep -qE '[Ss]cale.*:-100\}' "$caller" ||
        fail "$(basename "$caller") divides by a scale it never defaults"
done

if ! command -v jq > /dev/null 2>&1 || ! command -v envsubst > /dev/null 2>&1; then
    skip "jq or envsubst is not installed"
    finish
fi

bin_dir="$work_dir/bin"
mkdir -p "$bin_dir"

cat > "$bin_dir/pgrep" << 'STUB'
#!/usr/bin/env sh
exit 1
STUB

cat > "$bin_dir/hyprctl" << 'STUB'
#!/usr/bin/env sh
printf '[{"focused":true,"width":1920,"height":1200,"scale":1,"x":0,"y":0,"reserved":[0,0,0,0]}]\n'
STUB

cat > "$bin_dir/wlogout" << 'STUB'
#!/usr/bin/env sh
printf 'wlogout called\n' >> "$WLOGOUT_TEST_LOG"
while [ "$#" -gt 0 ]; do
    if [ "$1" = "--css" ]; then
        cat "$2" >> "$WLOGOUT_TEST_LOG"
        break
    fi
    shift
done
STUB

chmod +x "$bin_dir/pgrep" "$bin_dir/hyprctl" "$bin_dir/wlogout"

run_launcher() {
    HOME="$work_dir/home" \
        XDG_CONFIG_HOME="$work_dir/home/.config" \
        WLOGOUT_TEST_LOG="$work_dir/wlogout.log" \
        PATH="$bin_dir:$PATH" \
        bash "$lib_dir/logoutlaunch.sh" > "$work_dir/out" 2>&1
}

: > "$work_dir/wlogout.log"
if run_launcher; then
    fail "the launcher reported success with no wlogout config deployed"
fi
grep -q "wlogout called" "$work_dir/wlogout.log" &&
    fail "the launcher drew a menu with no layout to draw it from"

mkdir -p "$work_dir/home/.config/wlogout"
cp "$REPO_ROOT/Configs/.config/wlogout/layout_1" "$work_dir/home/.config/wlogout/" 2>/dev/null
cp "$REPO_ROOT/Configs/.config/wlogout/style_1.css" "$work_dir/home/.config/wlogout/" 2>/dev/null

: > "$work_dir/wlogout.log"
run_launcher
grep -q "wlogout called" "$work_dir/wlogout.log" ||
    fail "the launcher did not draw a menu it had the config for"

grep -q "336px" "$work_dir/wlogout.log" ||
    fail "the margins were not sized from the height and the scale"
grep -qE "[0-9]{5,}px" "$work_dir/wlogout.log" &&
    fail "a margin came out larger than any surface the compositor can hand back"

printf '    monitor scale and logout launcher checked\n'

finish

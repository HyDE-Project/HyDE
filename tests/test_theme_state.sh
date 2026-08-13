#!/usr/bin/env bash
##
# Theme colour state.
#
# The state the session configuration reads is generated in every mode, its
# absence is detected, and a run that cannot produce it fails loudly instead of
# leaving the desktop unstyled. The helpers are executed for real; the call
# sites that consume them are read, since a correct helper is worthless where
# its answer is discarded.
##

. "$(dirname -- "$0")/lib/common.sh"

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

empty_data_dir="$work_dir/no-shared-data"
mkdir -p "$empty_data_dir"

global_control="$REPO_ROOT/Configs/.local/lib/hyde/globalcontrol.sh"
core_sh="$REPO_ROOT/Configs/.local/lib/hyde/wallpaper/core.sh"
wallpaper_sh="$REPO_ROOT/Configs/.local/lib/hyde/wallpaper.sh"
theme_switch="$REPO_ROOT/Configs/.local/lib/hyde/theme.switch.sh"
color_set="$REPO_ROOT/Configs/.local/lib/hyde/color.set.sh"
color_hypr="$REPO_ROOT/Configs/.local/lib/hyde/color/hypr.sh"
installer="$REPO_ROOT/Scripts/install.sh"
lua_template="$REPO_ROOT/Configs/.local/share/wallbash/always/lua.dcol"

for required in "$global_control" "$core_sh" "$wallpaper_sh" "$theme_switch" \
    "$color_set" "$color_hypr" "$installer"; do
    [ -f "$required" ] || {
        fail "missing ${required#"$REPO_ROOT"/}"
        finish
    }
done

##
# Runs a body with the shared helpers loaded against a private home.
#
# Arguments:
#   $1  home directory to run against
#   $2  session configuration path, empty for a run outside a session
#   $3  shell body to evaluate
# Outputs:
#   The body's own output on stdout, the loader's diagnostics on stderr
# Returns:
#   The body's status, 97 when the helpers themselves fail to load
##
probe() {
    env -i \
        HOME="$1" \
        XDG_CONFIG_HOME="$1/.config" \
        XDG_DATA_HOME="$1/.local/share" \
        XDG_CACHE_HOME="$1/.cache" \
        XDG_STATE_HOME="$1/.local/state" \
        XDG_RUNTIME_DIR="$1/run" \
        XDG_DATA_DIRS="${PROBE_DATA_DIRS:-$empty_data_dir}" \
        HYPRLAND_CONFIG="${2:-}" \
        PATH="/usr/bin:/bin" \
        bash -c ". '$global_control' >/dev/null || exit 97
$3"
}

##
# Reports a mismatch between an expected and an observed helper answer.
#
# Arguments:
#   $1  expected value
#   $2  observed value
#   $3  what was being asked
##
expect() {
    [ "$1" = "$2" ] || fail "$3: expected '$1', got '$2'"
}

home_loads="$work_dir/loads"
mkdir -p "$home_loads"
loaded=$(probe "$home_loads" "" 'echo loaded' 2>"$work_dir/load.err")
expect "loaded" "$loaded" "the shared helpers do not load"
[ -s "$work_dir/load.err" ] &&
    printf '    note: loader diagnostics: %s\n' "$(head -n 1 "$work_dir/load.err")"

home_dirs="$work_dir/dirs"
mkdir -p "$home_dirs"
probe "$home_dirs" "" 'true' 2>/dev/null
for created in ".local/state/hyde/lua_state" ".cache/hyde/wallbash" "run/hyde" ".config/hypr/themes"; do
    [ -d "$home_dirs/$created" ] ||
        fail "loading the shared helpers left $created uncreated, so its template is skipped as a missing dependency"
done

home_entry="$work_dir/entry"
mkdir -p "$home_entry/.local/share/hypr"
probe "$home_entry" "" 'true' 2>/dev/null
: >"$home_entry/.local/share/hypr/hyde.lua"

state_dir="$home_entry/.local/state/hyde/lua_state"
report='wallbash_state_is_complete && echo complete || echo incomplete'

expect "incomplete" "$(probe "$home_entry" "" "$report" 2>/dev/null)" \
    "a Lua installation with no generated state"

printf 'return {}\n' >"$state_dir/colors.lua"
expect "incomplete" "$(probe "$home_entry" "" "$report" 2>/dev/null)" \
    "a Lua state carrying colours but no interface state"

printf 'return {}\n' >"$state_dir/ui.lua"
expect "incomplete" "$(probe "$home_entry" "" "$report" 2>/dev/null)" \
    "a Lua state carrying both generated files but no colour include for hyprlock"

mkdir -p "$home_entry/.config/hypr/themes"
printf '$color = rgb(000000)\n' >"$home_entry/.config/hypr/themes/colors.conf"
expect "complete" "$(probe "$home_entry" "" "$report" 2>/dev/null)" \
    "a Lua state carrying every generated file"

: >"$state_dir/colors.lua"
expect "incomplete" "$(probe "$home_entry" "" "$report" 2>/dev/null)" \
    "a Lua state whose colours file is empty"

home_hyprlang="$work_dir/hyprlang"
mkdir -p "$home_hyprlang/.config/hypr/themes"
probe "$home_hyprlang" "" 'true' 2>/dev/null
expect "incomplete" "$(probe "$home_hyprlang" "/somewhere/hyprland.conf" "$report" 2>/dev/null)" \
    "a hyprlang installation with no colour include"

printf '$color = rgb(000000)\n' >"$home_hyprlang/.config/hypr/themes/colors.conf"
expect "incomplete" "$(probe "$home_hyprlang" "/somewhere/hyprland.conf" "$report" 2>/dev/null)" \
    "a hyprlang-style installation carrying its colour include but no Lua state"

home_directory="$work_dir/directory"
mkdir -p "$home_directory/.config/hypr/themes/colors.conf"
probe "$home_directory" "" 'true' 2>/dev/null
: >"$home_directory/.config/hypr/themes/colors.conf/leftover"
expect "incomplete" "$(probe "$home_directory" "/somewhere/hyprland.conf" "$report" 2>/dev/null)" \
    "a colour include that is a directory rather than a generated file"

expect "function" "$(probe "$home_dirs" "" "bash -c 'type -t wallbash_state_is_complete'" 2>/dev/null)" \
    "wallbash_state_is_complete reaching a child process"

core_flat=$(tr '\n' ' ' <"$core_sh")

case "$core_flat" in
*'color.set.sh" "${wallList[setIndex]}" &'*)
    fail "the colour pass is backgrounded, so a caller that exits first loses it without a trace"
    ;;
esac

case "$core_flat" in
*'if ! "$LIB_DIR/hyde/color.set.sh"'*) ;;
*) fail "the wallpaper core does not check the colour pass" ;;
esac

grep -q 'print_log -sec "wallpaper" -err "colors"' "$core_sh" ||
    fail "the wallpaper core does not report a failed colour pass"

grep -q 'cache_output' "$core_sh" ||
    fail "the wallpaper core discards the cache output, so a failure cannot be diagnosed"

handoff_calls=$(grep -nE '^[[:space:]]+(Wall_Cache|Wall_Change)( |$)' "$wallpaper_sh")
handoff_count=$(printf '%s\n' "$handoff_calls" | grep -c '[^[:space:]]')
[ "$handoff_count" -ge 5 ] ||
    fail "found $handoff_count wallpaper hand-off call(s), so the scan no longer reaches them and passes without checking anything"

while IFS= read -r line; do
    [ -n "$line" ] || continue
    case "$line" in
    *'|| exit $?'*) continue ;;
    *'||'*) fail "a hand-off failure is flattened to a single status, so a stale colour state cannot be told from a backend that failed to paint: ${line}" ;;
    *) fail "an unchecked call drops a failure in the wallpaper script: ${line}" ;;
    esac
done <<EOF
$handoff_calls
EOF

wallpaper_flat=$(tr '\n' ' ' <"$wallpaper_sh")
case "$wallpaper_flat" in
*'export WALLPAPER_RELOAD_ALL=0 WALLBASH_STARTUP=1'*)
    fail "session start skips the colour pass unconditionally, so a missing state is never rebuilt"
    ;;
esac
case "$wallpaper_flat" in
*'if wallbash_state_is_complete'*'WALLBASH_STARTUP=1'*) ;;
*) fail "session start does not gate the skip on a complete state" ;;
esac

theme_flat=$(tr '\n' ' ' <"$theme_switch")
case "$theme_flat" in
*'if ! wallbash_state_is_complete'*'color.set.sh"'*) ;;
*) fail "the theme switch does not generate the colour state when it is missing" ;;
esac
case "$theme_flat" in
*'colour state is still incomplete'*) ;;
*) fail "the theme switch does not fail on an incomplete colour state" ;;
esac
case "$theme_flat" in
*'hyq --dump'*'>"$theme_buffer"'*'mv "$theme_buffer" "$theme_state"'*) ;;
*) fail "the theme dump writes onto the state directly, so a failed dump truncates it" ;;
esac
case "$theme_flat" in
*'could not dump hypr.theme'*) ;;
*) fail "a failed theme dump is not reported" ;;
esac
case "$theme_flat" in
*'readlink "$HYDE_THEME_DIR/wall.set"'*'find -H "$HYDE_THEME_DIR/wallpapers"'*) ;;
*) fail "the theme switch has no fallback when the theme carries no current wallpaper link" ;;
esac
case "$theme_flat" in
*'wallpaper_output'*) ;;
*) fail "the theme switch discards the wallpaper output, so a backend failure cannot be diagnosed" ;;
esac

color_flat=$(tr '\n' ' ' <"$color_set")
case "$color_flat" in
*'-c "$target_file"'*) ;;
*) fail "the colour pass moves onto a character device target" ;;
esac
case "$color_flat" in
*'print_log -sec "wallbash" -err "write"'*) ;;
*) fail "a template that cannot be written is not reported" ;;
esac
grep -q 'rm -f "$temp_target_file"' "$color_set" ||
    fail "the colour pass leaks its temporary file"
case "$color_flat" in
*'parallel fn_wallbash {} "${wallbashDirs[@]}" ::: "${deployList[@]}" || true'*)
    fail "the theme template pass discards its failures"
    ;;
esac
case "$color_flat" in
*'*/always*'*'|| true'*)
    fail "the always template pass discards its failures"
    ;;
esac
case "$color_flat" in
*'render_failures'*'exit 1'*) ;;
*) fail "the colour pass exits zero although templates failed" ;;
esac

grep -qE '\$\{HYPRLAND_CONFIG##\*\.\}. == .lua' "$color_hypr" &&
    fail "the colour writer still reads the raw session variable"

installer_flat=$(tr '\n' ' ' <"$installer")
case "$installer_flat" in
*'theme.switch.sh" -q || true'*)
    fail "the installer swallows a failed theme switch"
    ;;
esac
case "$installer_flat" in
*'if ! "$HOME/.local/lib/hyde/theme.switch.sh" -q'*) ;;
*) fail "the installer does not check the theme switch" ;;
esac
case "$installer_flat" in
*'theme_failed'*'exit 1'*) ;;
*) fail "the installer reports a broken theme state without failing the run" ;;
esac

[ -f "$lua_template" ] ||
    fail "the template that writes the Lua colour state is gone"
if [ -f "$lua_template" ]; then
    head -n 1 "$lua_template" | grep -q 'hyde/lua_state/colors.lua' ||
        fail "the Lua colour template no longer targets the state the session reads"
fi

printf '    theme colour state checked\n'

finish

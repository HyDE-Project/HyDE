#!/usr/bin/env bash
##
# Colour pass behaviour.
#
# The two functions the colour state depends on are executed against stubs:
# the wallpaper core hand-off that generates the state, and the template
# renderer that writes each generated file. Where the companion case reads the
# call sites to keep the intent from being undone, this one runs the code, so a
# change that keeps the shape but breaks the behaviour is caught as well.
##

. "$(dirname -- "$0")/lib/common.sh"

core_sh="$REPO_ROOT/Configs/.local/lib/hyde/wallpaper/core.sh"
color_set="$REPO_ROOT/Configs/.local/lib/hyde/color.set.sh"
global_control="$REPO_ROOT/Configs/.local/lib/hyde/globalcontrol.sh"
theme_switch="$REPO_ROOT/Configs/.local/lib/hyde/theme.switch.sh"
wallpaper_sh="$REPO_ROOT/Configs/.local/lib/hyde/wallpaper.sh"

for required in "$core_sh" "$color_set" "$global_control" "$theme_switch" "$wallpaper_sh"; do
    [ -f "$required" ] || {
        fail "missing ${required#"$REPO_ROOT"/}"
        finish
    }
done

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

statuses_home="$work_dir/statuses"
mkdir -p "$statuses_home"
eval "$(env -i HOME="$statuses_home" \
    XDG_CONFIG_HOME="$statuses_home/.config" \
    XDG_DATA_HOME="$statuses_home/.local/share" \
    XDG_CACHE_HOME="$statuses_home/.cache" \
    XDG_STATE_HOME="$statuses_home/.local/state" \
    XDG_RUNTIME_DIR="$statuses_home/run" \
    PATH="/usr/bin:/bin" \
    bash -c ". '$global_control' >/dev/null 2>&1
printf 'HYDE_STATUS_CACHE_FAILED=%s\nHYDE_STATUS_COLOURS_FAILED=%s\n' \
    \"\${HYDE_STATUS_CACHE_FAILED:-}\" \"\${HYDE_STATUS_COLOURS_FAILED:-}\"")"

for named in HYDE_STATUS_CACHE_FAILED HYDE_STATUS_COLOURS_FAILED; do
    case "$(eval "printf '%s' \"\${$named:-}\"")" in
    '' | 0) fail "the shared helpers do not name $named, so a caller cannot tell a stale colour state from a backend that failed to paint" ;;
    esac
done

##
# Builds a stand-alone script that loads the wallpaper core against stubs and
# calls the cache hand-off once.
#
# Arguments:
#   $1  directory to build the stand in
#   $2  exit status the thumbnail cache stub reports
#   $3  exit status the colour pass stub reports
# Outputs:
#   The path of the script to run
##
build_core_stand() {
    local stand="$1" cache_status="$2" colour_status="$3"
    mkdir -p "$stand/lib/hyde/wallpaper" "$stand/theme" "$stand/cache/thumbs" "$stand/cache/dcols"

    printf '%s\n' '#!/usr/bin/env bash' \
        'printf "cache ran\n"' \
        'printf "cache noise on stderr\n" >&2' \
        "exit $cache_status" >"$stand/lib/hyde/wallpaper/cache.sh"

    printf '%s\n' '#!/usr/bin/env bash' \
        'printf "colours ran\n" >"$STAND/colour.marker"' \
        "exit $colour_status" >"$stand/lib/hyde/color.set.sh"
    chmod +x "$stand/lib/hyde/wallpaper/cache.sh" "$stand/lib/hyde/color.set.sh"

    : >"$stand/theme/wallpaper.png"

    cat >"$stand/run.sh" <<STAND
#!/usr/bin/env bash
STAND="$stand"
export STAND
LIB_DIR="$stand/lib"
export LIB_DIR
HYDE_STATUS_CACHE_FAILED=$HYDE_STATUS_CACHE_FAILED
HYDE_STATUS_COLOURS_FAILED=$HYDE_STATUS_COLOURS_FAILED
export HYDE_STATUS_CACHE_FAILED HYDE_STATUS_COLOURS_FAILED
print_log() { printf '%s\n' "log: \$*"; }
wallList=("$stand/theme/wallpaper.png")
wallHash=("deadbeef")
wallSet="$stand/wall.set"
wallCur="$stand/wall.cur"
wallSqr="$stand/wall.sqre"
wallTmb="$stand/wall.thmb"
wallBlr="$stand/wall.blur"
wallQad="$stand/wall.quad"
wallDcl="$stand/wall.dcol"
thmbDir="$stand/cache/thumbs"
dcolDir="$stand/cache/dcols"
setIndex=0
set_as_global=true
wallpaper_setter_flag=s
. "$core_sh"
Wall_Cache
status=\$?
printf 'status=%s\n' "\$status"
STAND
    chmod +x "$stand/run.sh"
    printf '%s\n' "$stand/run.sh"
}

stand_ok="$work_dir/core-ok"
run_ok=$(build_core_stand "$stand_ok" 0 0)
output_ok=$(bash "$run_ok" 2>&1)

case "$output_ok" in
*'status=0'*) ;;
*) fail "a working colour pass did not report success: $output_ok" ;;
esac
[ -f "$stand_ok/colour.marker" ] ||
    fail "the colour pass did not run before the hand-off returned, so a caller that exits first loses the state"
[ -L "$stand_ok/wall.set" ] ||
    fail "the current wallpaper link was not written"
for generated in wall.sqre wall.thmb wall.blur wall.quad wall.dcol; do
    [ -L "$stand_ok/$generated" ] ||
        fail "the $generated link was not written after a successful pass"
done

stand_colour="$work_dir/core-colour-fails"
run_colour=$(build_core_stand "$stand_colour" 0 1)
output_colour=$(bash "$run_colour" 2>&1)

case "$output_colour" in
*"status=$HYDE_STATUS_COLOURS_FAILED"*) ;;
*) fail "a failed colour pass did not report its own status: $output_colour" ;;
esac
case "$output_colour" in
*'could not generate colours'*) ;;
*) fail "a failed colour pass was not named in the output: $output_colour" ;;
esac
for generated in wall.sqre wall.thmb wall.blur wall.quad wall.dcol; do
    [ -e "$stand_colour/$generated" ] &&
        fail "the $generated link was written although the colour pass failed"
done

stand_cache="$work_dir/core-cache-fails"
run_cache=$(build_core_stand "$stand_cache" 1 0)
output_cache=$(bash "$run_cache" 2>&1)

case "$output_cache" in
*"status=$HYDE_STATUS_CACHE_FAILED"*) ;;
*) fail "a failed thumbnail cache did not report its own status: $output_cache" ;;
esac
case "$output_cache" in
*'could not cache'*) ;;
*) fail "a failed thumbnail cache was not named in the output: $output_cache" ;;
esac
case "$output_cache" in
*'cache noise on stderr'*) ;;
*) fail "the cache output was discarded, leaving the failure undiagnosable: $output_cache" ;;
esac
[ -f "$stand_cache/colour.marker" ] &&
    fail "the colour pass ran although the thumbnail cache had already failed"

stand_verdict="$work_dir/switch-verdict"
mkdir -p "$stand_verdict"
cat >"$stand_verdict/run.sh" <<STAND
#!/usr/bin/env bash
HYDE_STATUS_CACHE_FAILED=$HYDE_STATUS_CACHE_FAILED
HYDE_STATUS_COLOURS_FAILED=$HYDE_STATUS_COLOURS_FAILED
$(sed -n '/^wallpaper_failure_is_fatal() {/,/^}$/p' "$theme_switch")
for probed in 0 1 2 "\$HYDE_STATUS_CACHE_FAILED" "\$HYDE_STATUS_COLOURS_FAILED"; do
    if wallpaper_failure_is_fatal "\$probed"; then
        printf '%s=fatal\n' "\$probed"
    else
        printf '%s=carry-on\n' "\$probed"
    fi
done
STAND
output_verdict=$(bash "$stand_verdict/run.sh" 2>&1)

case "$output_verdict" in
*"$HYDE_STATUS_CACHE_FAILED=fatal"*) ;;
*) fail "a failed thumbnail cache does not stop the theme switch, so it finishes green on the previous theme's colours: $output_verdict" ;;
esac
case "$output_verdict" in
*"$HYDE_STATUS_COLOURS_FAILED=fatal"*) ;;
*) fail "a failed colour pass does not stop the theme switch, so it finishes green on the previous theme's colours: $output_verdict" ;;
esac
for painting in 1 2; do
    case "$output_verdict" in
    *"$painting=carry-on"*) ;;
    *) fail "status $painting comes from the wallpaper backend, which paints and nothing else, and must not stop the theme switch: $output_verdict" ;;
    esac
done
case "$output_verdict" in
*'0=carry-on'*) ;;
*) fail "a hand-off that succeeded was treated as a failure: $output_verdict" ;;
esac

stand_backend="$work_dir/backend-status"
mkdir -p "$stand_backend"
cat >"$stand_backend/run.sh" <<STAND
#!/usr/bin/env bash
HYDE_STATUS_CACHE_FAILED=$HYDE_STATUS_CACHE_FAILED
HYDE_STATUS_COLOURS_FAILED=$HYDE_STATUS_COLOURS_FAILED
$(sed -n '/^wallpaper_backend_status() {/,/^}$/p' "$wallpaper_sh")
for probed in 0 1 2 "\$HYDE_STATUS_CACHE_FAILED" "\$HYDE_STATUS_COLOURS_FAILED"; do
    printf '%s->%s\n' "\$probed" "\$(wallpaper_backend_status "\$probed")"
done
STAND
output_backend=$(bash "$stand_backend/run.sh" 2>&1)

for reserved in "$HYDE_STATUS_CACHE_FAILED" "$HYDE_STATUS_COLOURS_FAILED"; do
    case "$output_backend" in
    *"$reserved->1"*) ;;
    *) fail "a backend exiting with $reserved is passed on as a failed generation, so a theme switch stops on a wallpaper that merely failed to paint: $output_backend" ;;
    esac
done
for kept in '0->0' '1->1' '2->2'; do
    case "$output_backend" in
    *"$kept"*) ;;
    *) fail "a backend status was rewritten although it collides with nothing ($kept): $output_backend" ;;
    esac
done

##
# Builds a stand-alone script that loads the template renderer out of the
# colour pass and renders one template.
#
# Arguments:
#   $1  directory to build the stand in
#   $2  template file to render
# Outputs:
#   The path of the script to run
##
build_render_stand() {
    local stand="$1" template="$2"
    mkdir -p "$stand/state" "$stand/tmp"
    cat >"$stand/run.sh" <<STAND
#!/usr/bin/env bash
TMPDIR="$stand/tmp"
export TMPDIR
HYDE_STATE_HOME="$stand/state"
export HYDE_STATE_HOME
NORMAL_SED_SCRIPT='s|<colour>|rgb(101010)|g'
INVERTED_SED_SCRIPT="\$NORMAL_SED_SCRIPT"
export NORMAL_SED_SCRIPT INVERTED_SED_SCRIPT
print_log() { printf '%s\n' "log: \$*"; }
pkg_installed() { return 0; }
export -f print_log pkg_installed
$(sed -n '/^fn_wallbash() {/,/^}$/p' "$color_set")
target_file=""
fn_wallbash "$template"
printf 'status=%s\n' "\$?"
printf 'leftovers=%s\n' "\$(find "$stand/tmp" -type f | wc -l)"
STAND
    chmod +x "$stand/run.sh"
    printf '%s\n' "$stand/run.sh"
}

stand_file="$work_dir/render-file"
mkdir -p "$stand_file/out"
printf '%s\n' "$stand_file/out/theme.conf" 'colour = <colour>' >"$work_dir/file.dcol"
output_file=$(bash "$(build_render_stand "$stand_file" "$work_dir/file.dcol")" 2>&1)

case "$output_file" in
*'status=0'*) ;;
*) fail "rendering into a plain file failed: $output_file" ;;
esac
grep -q 'rgb(101010)' "$stand_file/out/theme.conf" 2>/dev/null ||
    fail "the rendered file did not receive the substituted colours"
case "$output_file" in
*'leftovers=0'*) ;;
*) fail "rendering into a plain file left its temporary behind: $output_file" ;;
esac

stand_discard="$work_dir/render-discard"
mkdir -p "$stand_discard"
discard_target="$stand_discard/discard.dev"
if mknod "$discard_target" c 1 3 2>/dev/null; then
    printf '%s\n' "$discard_target" 'colour = <colour>' >"$work_dir/discard.dcol"
    output_discard=$(bash "$(build_render_stand "$stand_discard" "$work_dir/discard.dcol")" 2>&1)

    case "$output_discard" in
    *'status=0'*) ;;
    *) fail "a template that discards its render was treated as a failure: $output_discard" ;;
    esac
    case "$output_discard" in
    *'leftovers=0'*) ;;
    *) fail "a discarding template left its temporary behind: $output_discard" ;;
    esac
    [ -c "$discard_target" ] ||
        fail "the discard target stopped being a character device, which the run replaced"
else
    skip "creating a character device is not permitted here, so the discard target cannot be isolated from the host"
fi

stand_readonly="$work_dir/render-readonly"
mkdir -p "$stand_readonly/locked"
printf '%s\n' "$stand_readonly/locked/theme.conf" 'colour = <colour>' >"$work_dir/readonly.dcol"
chmod 500 "$stand_readonly/locked"
output_readonly=$(bash "$(build_render_stand "$stand_readonly" "$work_dir/readonly.dcol")" 2>&1)
chmod 700 "$stand_readonly/locked"

if [ "$(id -u)" -eq 0 ]; then
    skip "a write into a read-only directory cannot be refused for the superuser"
else
    case "$output_readonly" in
    *'status=1'*) ;;
    *) fail "a template that could not be written reported success: $output_readonly" ;;
    esac
    case "$output_readonly" in
    *'could not write'*) ;;
    *) fail "a template that could not be written was not named: $output_readonly" ;;
    esac
    case "$output_readonly" in
    *'leftovers=0'*) ;;
    *) fail "a failed render left its temporary behind: $output_readonly" ;;
    esac
fi

stand_absent="$work_dir/render-absent"
printf '%s\n' "$work_dir/nowhere/theme.conf" 'colour = <colour>' >"$work_dir/absent.dcol"
output_absent=$(bash "$(build_render_stand "$stand_absent" "$work_dir/absent.dcol")" 2>&1)

case "$output_absent" in
*'status=0'*) ;;
*) fail "a template whose dependency is absent should be skipped, not failed: $output_absent" ;;
esac
case "$output_absent" in
*"skip 'missing directory'"*) ;;
*) fail "a skipped template was not named in the output: $output_absent" ;;
esac

stand_directory="$work_dir/render-directory"
mkdir -p "$stand_directory/out/theme.conf"
printf '%s\n' "$stand_directory/out/theme.conf" 'colour = <colour>' >"$work_dir/directory.dcol"
output_directory=$(bash "$(build_render_stand "$stand_directory" "$work_dir/directory.dcol")" 2>&1)

case "$output_directory" in
*'status=1'*) ;;
*) fail "a template whose target is a directory reported success: $output_directory" ;;
esac
case "$output_directory" in
*'not a regular file'*) ;;
*) fail "a target that is not a regular file was not named: $output_directory" ;;
esac
[ -d "$stand_directory/out/theme.conf" ] ||
    fail "the directory target was replaced instead of refused"
[ -e "$stand_directory/out/theme.conf/theme.conf" ] &&
    fail "the render was moved inside the directory target, leaving the state unwritten"
case "$output_directory" in
*'leftovers=0'*) ;;
*) fail "a refused render left its temporary behind: $output_directory" ;;
esac

printf '    colour pass behaviour checked\n'

finish

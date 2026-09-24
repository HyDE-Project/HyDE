#! /bin/env bash
# Caffeine mode (idle-inhibit toggle) for Waybar.
#
# Waybar's native `idle_inhibitor` module type keeps its activated/deactivated
# state only in Waybar's own process memory. Waybar hot-reloads its config via
# SIGUSR2 on routine theme/wallpaper changes (not just --hide), which
# reinitializes every module -- silently resetting Caffeine mode to off with
# no notification (HyDE-Project/HyDE#2117).
#
# Fix: track the on/off state in a small state file (`$XDG_RUNTIME_DIR`, since
# it is inherently boot/session-scoped, not a persistent user preference), and
# do the actual inhibiting with `systemd-inhibit --what=idle:sleep`, a plain
# background process independent of Waybar's lifecycle. hypridle.conf already
# has `ignore_systemd_inhibit = false`, so it respects this natively -- no
# custom Wayland idle-inhibit protocol client needed.
# Checked before hyde-shell/globalcontrol.sh is sourced below: that source
# sets its own XDG_RUNTIME_DIR fallback ("/run/user/$(id -u)"), which would
# make this check unreachable. A shared, world-writable fallback like
# /tmp/hyde would let another local user pre-plant that path (a directory
# they own, or a symlink) and read or interfere with this user's caffeine
# state and inhibitor pid (CWE-377). XDG_RUNTIME_DIR is always set on a
# normal systemd/logind-managed session, so its absence means a broken or
# unusual environment -- fail clearly instead of degrading into that risk.
if [ -z "$XDG_RUNTIME_DIR" ]; then
    echo "Error: XDG_RUNTIME_DIR is not set, refusing to use a shared fallback location" >&2
    exit 1
fi

if ! source "$(command -v hyde-shell)"; then
    echo "[$0] :: Error: hyde-shell not found."
    echo "[$0] :: Is HyDE installed?"
    exit 1
fi

state_dir="$XDG_RUNTIME_DIR/hyde"
state_file="$state_dir/caffeine"
lock_file="$state_dir/caffeine.lock"
mkdir -p "$state_dir"

notify="${waybar_caffeine_notification:-true}"

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
    -t, --toggle                Toggle Caffeine mode (on/off)
    -r, --read                  Report current status as JSON, self-healing
                                 stale state (for waybar's exec/signal)
    -q, --quiet                 Disable notifications
    -P, --sigproc PROC,SIGNAL   Send signal to process (e.g., --sigproc waybar,21)
    -h, --help                  Show this help message

Examples:
    $(basename "$0") -r                        # Report current status
    $(basename "$0") -t -P waybar,21            # Toggle, then nudge waybar to refresh
EOF
}

if [ -z "$*" ]; then
    echo "No arguments provided"
    show_help
    exit 1
fi

LONGOPTS="toggle,read,quiet,sigproc:,help"
SHORTOPTS="trqP:h"
PARSED=$(getopt --options $SHORTOPTS --longoptions "$LONGOPTS" --name "$0" -- "$@")
if [ $? -ne 0 ]; then
    exit 2
fi
eval set -- "$PARSED"
action=""
signal_proc=""
while true; do
    case "$1" in
    -t | --toggle)
        action="toggle"
        shift
        ;;
    -r | --read)
        action="read"
        shift
        ;;
    -q | --quiet)
        notify=false
        shift
        ;;
    -P | --sigproc)
        signal_proc="$2"
        shift 2
        ;;
    -h | --help)
        show_help
        exit 0
        ;;
    --)
        shift
        break
        ;;
    *)
        echo "Invalid option: $1"
        show_help
        exit 1
        ;;
    esac
done
if [ -z "$action" ]; then
    echo "Error: No action specified"
    show_help
    exit 1
fi

send_signal_to_process() {
    if [ -n "$signal_proc" ]; then
        if [[ $signal_proc == *","* ]]; then
            IFS=',' read -r process signal <<<"$signal_proc"
        elif [[ $signal_proc == *":"* ]]; then
            IFS=':' read -r process signal <<<"$signal_proc"
        else
            echo "Error: Invalid sigproc format. Use PROCESS,SIGNAL or PROCESS:SIGNAL"
            return 1
        fi
        if ! [[ $signal =~ ^[0-9]+$ ]]; then
            echo "Error: Signal must be a number"
            return 1
        fi
        if pgrep -x "$process" >/dev/null; then
            pkill -RTMIN+"$signal" "$process" 2>/dev/null || echo "Warning: Failed to send signal $signal to $process"
        else
            echo "Warning: Process '$process' not found"
        fi
    fi
}

# Reads $state_file ("<intended:0|1>|<pid>") and treats the *effective* state
# as whatever is actually true on the system, not whatever the flag says: a
# recorded pid that is dead, missing, or -- to guard against a pid reused by
# an unrelated process across a reboot -- not actually a systemd-inhibit
# process, is treated as "off" and the file is corrected. Malformed content
# (missing file, empty, non-numeric fields, extra/missing delimiters) also
# falls back to a clean "off" instead of erroring.
reconcile_state() {
    intended=0
    inhibitor_pid=""
    if [ -f "$state_file" ]; then
        IFS='|' read -r intended inhibitor_pid <"$state_file"
    fi
    [[ $intended =~ ^[01]$ ]] || intended=0
    if [[ -n $inhibitor_pid ]] && [[ $inhibitor_pid =~ ^[0-9]+$ ]] \
        && kill -0 "$inhibitor_pid" 2>/dev/null \
        && [ "$(ps -p "$inhibitor_pid" -o comm= 2>/dev/null)" = "systemd-inhibit" ]; then
        : # inhibitor_pid confirmed alive and genuinely ours, keep it
    else
        inhibitor_pid=""
        intended=0
    fi
}

save_state() {
    printf '%d|%s\n' "$intended" "$inhibitor_pid" >"$state_file"
}

start_inhibitor() {
    if ! command -v systemd-inhibit >/dev/null 2>&1; then
        echo "Error: systemd-inhibit not found, cannot activate Caffeine mode" >&2
        return 1
    fi
    # Detached from this script's own stdio: a caller that captures this
    # script's output (command substitution, a pipe) would otherwise hang
    # forever, since the backgrounded, disowned process still holds that
    # fd open long after this script itself has exited.
    systemd-inhibit --what=idle:sleep --who=HyDE --why="Caffeine mode" sleep infinity \
        </dev/null >/dev/null 2>&1 &
    disown
    inhibitor_pid=$!
    intended=1
}

stop_inhibitor() {
    [ -n "$inhibitor_pid" ] && kill "$inhibitor_pid" 2>/dev/null
    inhibitor_pid=""
    intended=0
}

send_notification() {
    if [ "$intended" -eq 1 ]; then
        notify-send -a "HyDE Notify" -r 21 -t 800 "Caffeine Mode: ON"
    else
        notify-send -a "HyDE Notify" -r 21 -t 800 "Caffeine Mode: OFF"
    fi
}

# Icons match the values the old native idle_inhibitor module shipped
# (format-icons "activated"/"deactivated"), kept as JSON \u escapes so this
# stays plain ASCII in the script and lets waybar's own JSON parser decode
# them, same as it already does for the .jsonc module definitions.
generate_status() {
    local icon alt tooltip
    if [ "$intended" -eq 1 ]; then
        icon='󰅶'
        alt="activated"
        tooltip="<span foreground='#98c379'>󰅶 Caffeine Mode Active</span>\nPrevents system from going to sleep"
    else
        icon='󰛊'
        alt="deactivated"
        tooltip="<span foreground='#e06c75'>󰛊 Caffeine Mode Inactive</span>\nSystem will follow normal power settings"
    fi
    printf '{"text":"%s","alt":"%s","tooltip":"%s","class":"%s"}\n' "$icon" "$alt" "$tooltip" "$alt"
}

# Critical section: reconcile + mutate + save under a lock, so a rapid
# double-click (two invocations racing on the same state file) cannot
# interleave and corrupt it or double-spawn/double-kill the inhibitor.
exec 9>"$lock_file"
flock 9

reconcile_state
start_failed=0
case "$action" in
toggle)
    if [ "$intended" -eq 1 ]; then
        stop_inhibitor
    else
        start_inhibitor || start_failed=1
    fi
    save_state
    ;;
read)
    save_state # persist any self-heal from reconcile_state
    ;;
esac

flock -u 9

[ "$notify" = true ] && [ "$action" = "toggle" ] && [ "$start_failed" -eq 0 ] && send_notification
send_signal_to_process
generate_status
[ "$start_failed" -eq 0 ]

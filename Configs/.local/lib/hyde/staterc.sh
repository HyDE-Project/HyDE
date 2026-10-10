#!/usr/bin/env bash
##
# Locked, atomic writer for $XDG_STATE_HOME/hyde/staterc.
#
# Usage: staterc.sh set KEY VALUE
#
# waybar.py, set_conf() and the Lua selectors all rewrite staterc. Unlocked
# and truncated in place, two of them running at once could wipe it down to
# one line, since a writer that read it mid-rewrite saw an empty file
# (HyDE-Project/HyDE#2194). Here the read-modify-write runs under an flock
# on staterc.lock, which waybar.py takes too (fcntl.flock is the same lock),
# and the result replaces staterc with a rename, so a script sourcing it
# never sees half a file.
#
# The value is written literally: it reaches awk through the environment,
# not through sed's c command, which ate backslashes ("a\nb" became two
# lines). A key present twice is collapsed instead of appended again.
#
# Do not delete staterc.lock while it is held: the lock lives on the open
# file, so a second writer would lock a new file at the same path and run
# concurrently (same as wallpaper_acquire_lock in globalcontrol.sh).
#
# Exit status: 0 written, 1 write failed, 2 usage error.
##

if [ "$#" -ne 3 ] || [ "$1" != "set" ]; then
    echo "usage: staterc.sh set KEY VALUE" >&2
    exit 2
fi
key=$2
if [[ ! "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    echo "staterc.sh: invalid key '$key'" >&2
    exit 2
fi

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hyde"
staterc="$state_dir/staterc"
mkdir -p "$state_dir" || exit 1

# A writer that can't get the lock in time still writes: losing the setting
# is worse than the rare race it would otherwise wait out.
if exec {lock_fd}>"$state_dir/staterc.lock" 2>/dev/null; then
    flock -w 10 "$lock_fd" ||
        echo "staterc.sh: staterc is still locked after 10s, writing without the lock" >&2
else
    echo "staterc.sh: cannot open staterc.lock, writing without the lock" >&2
fi

tmp=$(mktemp "$state_dir/.staterc.XXXXXX" 2>/dev/null) || exit 1
trap 'rm -f "$tmp"' EXIT

# Replace the first KEY= line, drop later duplicates, append if absent.
src=/dev/null
[ -f "$staterc" ] && src=$staterc
STATERC_VALUE=$3 awk -v key="$key" '
    BEGIN { line = key "=\"" ENVIRON["STATERC_VALUE"] "\"" }
    index($0, key "=") == 1 { if (!done) { print line; done = 1 }; next }
    { print }
    END { if (!done) print line }
' "$src" >"$tmp" || exit 1

# mktemp creates 0600: keep the old file's mode, or give a new one what a
# plain redirect would (0666 minus the umask).
if [ -f "$staterc" ]; then
    chmod --reference="$staterc" "$tmp"
else
    chmod "$(printf '%o' $((0666 & ~0$(umask))))" "$tmp"
fi || exit 1

mv -f "$tmp" "$staterc" || exit 1

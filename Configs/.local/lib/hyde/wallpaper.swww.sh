#!/usr/bin/env bash
selected_wall="${1:-"$HYDE_CACHE_HOME/wall.set"}"
lockFile="$XDG_RUNTIME_DIR/hyde/$(basename "$0").lock"
mkdir -p "$(dirname "$lockFile")"
if [ -e "$lockFile" ]; then
    existing_pid="$(cat "$lockFile" 2>/dev/null || true)"
    if [ -n "$existing_pid" ] && kill -0 "$existing_pid" 2>/dev/null; then
        cat << EOF

Error: Another instance of $(basename "$0") is running.
PID:
    $existing_pid
If you are sure that no other instance is running, remove the lock file:
    $lockFile
EOF
        exit 1
    fi
    # stale lock from crashed session
    rm -f "$lockFile"
fi
printf '%s\n' "$$" >"$lockFile"
trap 'rm -f "$lockFile"' EXIT INT TERM

if command -v swww >/dev/null 2>&1; then
    wallpaper_cmd="swww"
elif command -v awww >/dev/null 2>&1; then
    wallpaper_cmd="awww"
else
    echo "Error: neither 'swww' nor 'awww' is available." >&2
    exit 127
fi

if command -v swww-daemon >/dev/null 2>&1; then
    wallpaper_daemon_cmd="swww-daemon"
elif command -v awww-daemon >/dev/null 2>&1; then
    wallpaper_daemon_cmd="awww-daemon"
else
    echo "Error: neither 'swww-daemon' nor 'awww-daemon' is available." >&2
    exit 127
fi

scrDir="$(dirname "$(realpath "$0")")"
source "$scrDir/globalcontrol.sh"
case "$WALLPAPER_SET_FLAG" in
    p)
        xtrans=$WALLPAPER_SWWW_TRANSITION_PREV
        xtrans="${xtrans:-"outer"}"
        ;;
    n)
        xtrans=$WALLPAPER_SWWW_TRANSITION_NEXT
        xtrans="${xtrans:-"grow"}"
        ;;
esac
[ -z "$selected_wall" ] && echo "No input wallpaper" && exit 1
selected_wall="$(readlink -f "$selected_wall")"
if ! "$wallpaper_cmd" query &>/dev/null; then
    "$wallpaper_daemon_cmd" --format xrgb &
    disown
    "$wallpaper_cmd" query && "$wallpaper_cmd" restore
fi
is_video=$(file --mime-type -b "$selected_wall" | grep -c '^video/')
if [ "$is_video" -eq 1 ]; then
    print_log -sec "wallpaper" -stat "converting video" "$selected_wall"
    mkdir -p "$HYDE_CACHE_HOME/wallpapers/thumbnails"
    cached_thumb="$HYDE_CACHE_HOME/wallpapers/$(${hashMech:-sha1sum} "$selected_wall" | cut -d' ' -f1).png"
    extract_thumbnail "$selected_wall" "$cached_thumb"
    selected_wall="$cached_thumb"
fi
xtrans=$WALLPAPER_SWWW_TRANSITION_DEFAULT
[ -z "$xtrans" ] && xtrans="grow"
[ -z "$wallFramerate" ] && wallFramerate=60
[ -z "$wallTransDuration" ] && wallTransDuration=0.4
print_log -sec "wallpaper" -stat "apply" "$selected_wall"
"$wallpaper_cmd" img "$(readlink -f "$selected_wall")" --transition-bezier .43,1.19,1,.4 --transition-type "$xtrans" --transition-duration "$wallTransDuration" --transition-fps "$wallFramerate" --invert-y --transition-pos "$(hyprctl cursorpos | grep -E '^[0-9]' || echo "0,0")" &

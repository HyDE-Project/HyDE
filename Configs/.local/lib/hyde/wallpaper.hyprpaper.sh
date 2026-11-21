#!/usr/bin/env bash
[[ $HYDE_SHELL_INIT -ne 1 ]] && eval "$(hyde-shell init)"

wallpaper_acquire_lock 15
trap 'flock -u "$WALLPAPER_LOCK_FD"' EXIT

if [[ ! -f "$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprpaper.lock" ]]; then
    # Detached from our stdio: a daemon holding the caller's stdout keeps a
    # "$(wallpaper.sh ...)" capture open forever, which froze the installer (#2156).
    # The whole list: it runs in a background subshell that holds the same
    # output while it waits for hyprpaper.
    { systemctl --user start hyprpaper.service || setsid hyprpaper; } </dev/null &>/dev/null &
    sleep 1
fi
selected_wall="${1:-${XDG_CACHE_HOME:-$HOME/.cache}/hyde/wall.set}"
[ -z "$selected_wall" ] && echo "No input wallpaper" && exit 1
selected_wall="$(readlink -f "$selected_wall")"
is_video=$(file --mime-type -b "$selected_wall" | grep -c '^video/')
if [ "$is_video" -eq 1 ]; then
    print_log -sec "wallpaper" -stat "converting video" "$selected_wall"
    mkdir -p "$HYDE_CACHE_HOME/wallpapers/thumbnails"
    cached_thumb="$HYDE_CACHE_HOME/wallpapers/$(${hashMech:-sha1sum} "$selected_wall" | cut -d' ' -f1).png"
    extract_thumbnail "$selected_wall" "$cached_thumb"
    selected_wall="${cached_thumb}"
fi

if [[ -n $HYPRLAND_INSTANCE_SIGNATURE ]]; then
    hyprctl hyprpaper wallpaper ",${selected_wall}" ||
        hyprctl hyprpaper reload ,"${selected_wall}" #TODO: I do not know when did they change this command but yeah will remove this line after some time
else
    cat <<EOF >"$XDG_STATE_HOME/hyde/hyprpaper.conf"
splash = false
wallpaper:path = "${selected_wall}"
EOF

    if systemctl --user is-active --quiet hyprpaper.service; then
        systemctl --user restart hyprpaper.service
    else
        app.sh -- hyprpaper --config "$XDG_STATE_HOME/hyde/hyprpaper.conf"
    fi

fi

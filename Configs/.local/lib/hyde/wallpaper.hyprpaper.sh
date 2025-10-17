#!/usr/bin/env bash
# A wallpaper backend adapter for hyprpaper
# * Notes
# For future backends, this can be used as a base, just
# change the hyprctl commands for the desired backend's commands

# shellcheck source=$HOME/.local/bin/hyde-shell
# shellcheck disable=SC1091
if ! source "$(which hyde-shell)"; then
    echo "[wallbash] code :: Error: hyde-shell not found."
    echo "[wallbash] code :: Is HyDE installed?"
    exit 1
fi

# ? Be sure the wallpaper daemon is running
if [[ ! -f "${XDG_RUNTIME_DIR}/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprpaper.lock" ]]; then
    systemctl --user start hyprpaper.service || setsid hyprpaper &
    sleep 1
fi

selected_wall="${1:-${XDG_CACHE_HOME:-$HOME/.cache}/hyde/wall.set}"
[ -z "${selected_wall}" ] && echo "No input wallpaper" && exit 1
selected_wall="$(readlink -f "${selected_wall}")"

#? hyprlock do not support videos, so we need to convert them to images
is_video=$(file --mime-type -b "${selected_wall}" | grep -c '^video/')
if [ "${is_video}" -eq 1 ]; then
    print_log -sec "wallpaper" -stat "converting video" "$selected_wall"
    mkdir -p "${HYDE_CACHE_HOME}/wallpapers/thumbnails"
    cached_thumb="$HYDE_CACHE_HOME/wallpapers/$(${hashMech:-sha1sum} "${selected_wall}" | cut -d' ' -f1).png"
    extract_thumbnail "${selected_wall}" "${cached_thumb}"
    selected_wall="${cached_thumb}"
fi

# ? Setting wallpaper using hyprctl IPC!
# https://wiki.hypr.land/Hypr-Ecosystem/hyprpaper/#the-reload-keyword
hyprctl hyprpaper reload ",${selected_wall}"

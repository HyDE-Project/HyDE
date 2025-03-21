#!/usr/bin/env bash
# shellcheck disable=SC1091
# Separated wallpaper script for swww backend
# We will handle swww specific configurations here
# add overrides in [wallpaper.swww] in ~/.config/hyde/config.toml

# * Contributor Notes,
# this is a separate implementation of swww wallpaper setter
# If you want to add another backend add it as `wallpaper.<backend>.sh`
# This script only accepts one argument,
#   the path to the wallpaper or a symlink
# This script should handle unsupported files.
#   In this case we used the method `extract_thumbnail`
#   to generate a png from a video file as swww do not support video

selected_wall="${1:-"$$HYDE_CACHE_HOME/wall.set"}"
lockFile="$HYDE_RUNTIME_DIR/$(basename "${0}").lock"
if [ -e "${lockFile}" ]; then
    cat <<EOF

Error: Another instance of $(basename "${0}") is running.
If you are sure that no other instance is running, remove the lock file:
    ${lockFile}
EOF
    exit 1
fi
touch "${lockFile}"
trap 'rm -f ${lockFile}' EXIT

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"

# Handle transition
case "${WALLPAPER_SET_FLAG}" in
p)
    xtrans=${WALLPAPER_SWWW_TRANSITION_PREV}
    xtrans="${xtrans:-"outer"}"
    ;;
n)
    xtrans=${WALLPAPER_SWWW_TRANSITION_NEXT}
    xtrans="${xtrans:-"grow"}"
    ;;

esac

selected_wall="$1"
[ -z "${selected_wall}" ] && echo "No input wallpaper" && exit 1
selected_wall="$(readlink -f "${selected_wall}")"

if ! swww query &>/dev/null; then
    swww-daemon --format xrgb &
    disown
    swww query && swww restore
fi

is_video=$(file --mime-type -b "${selected_wall}" | grep -c '^video/')
if [ "${is_video}" -eq 1 ]; then
    print_log -sec "wallpaper" -stat "converting video" "$selected_wall"
    mkdir -p "${HYDE_CACHE_HOME}/wallpapers/thumbnails"
    cached_thumb="$HYDE_CACHE_HOME/wallpapers/$(${hashMech:-sha1sum} "${selected_wall}" | cut -d' ' -f1).png"
    extract_thumbnail "${selected_wall}" "${cached_thumb}"
    selected_wall="${cached_thumb}"
fi

#// set defaults
xtrans=${WALLPAPER_SWWW_TRANSITION_DEFAULT}
[ -z "${xtrans}" ] && xtrans="grow"
[ -z "${wallFramerate}" ] && wallFramerate=60
[ -z "${wallTransDuration}" ] && wallTransDuration=0.4

#// apply wallpaper
# TODO: add support for other backends
print_log -sec "wallpaper" -stat "apply" "$selected_wall"
swww img "$(readlink -f "$selected_wall")" --transition-bezier .43,1.19,1,.4 --transition-type "${xtrans}" --transition-duration "${wallTransDuration}" --transition-fps "${wallFramerate}" --invert-y --transition-pos "$(hyprctl cursorpos | grep -E '^[0-9]' || echo "0,0")" &

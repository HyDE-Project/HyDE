#!/usr/bin/env bash
# shellcheck disable=SC1091
# Separated wallpaper script for swww backend
# We will handle swww specific configurations here
# [wallpaper.swww] in ~/.config/hyde/config.toml

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

if ! swww query &>/dev/null; then
    swww-daemon --format xrgb &
    disown
    swww query && swww restore
fi

#// set defaults
xtrans=${WALLPAPER_SWWW_TRANSITION_DEFAULT}
[ -z "${xtrans}" ] && xtrans="grow"
[ -z "${wallFramerate}" ] && wallFramerate=60
[ -z "${wallTransDuration}" ] && wallTransDuration=0.4

#// apply wallpaper
# TODO: add support for other backends
print_log -sec "wallpaper" -stat "apply" "$(readlink -f "$selected_wall")"
swww img "$(readlink -f "$selected_wall")" --transition-bezier .43,1.19,1,.4 --transition-type "${xtrans}" --transition-duration "${wallTransDuration}" --transition-fps "${wallFramerate}" --invert-y --transition-pos "$(hyprctl cursorpos | grep -E '^[0-9]' || echo "0,0")" &

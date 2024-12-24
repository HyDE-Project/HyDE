#!/usr/bin/env bash
# shellcheck disable=SC2154

#// lock instance

lockFile="$HYDE_RUNTIME_DIR/$(basename "${0}").lock"
[ -e "${lockFile}" ] && echo "An instance of the script is already running..." && exit 1
touch "${lockFile}"
trap 'rm -f ${lockFile}' EXIT

#// define functions

Wall_Cache() {
    ln -fs "${wallList[setIndex]}" "${wallSet}"
    ln -fs "${wallList[setIndex]}" "${wallCur}"
    "${scrDir}/swwwallcache.sh" -w "${wallList[setIndex]}" &>/dev/null
    "${scrDir}/swwwallbash.sh" "${wallList[setIndex]}" &
    ln -fs "${thmbDir}/${wallHash[setIndex]}.sqre" "${wallSqr}"
    ln -fs "${thmbDir}/${wallHash[setIndex]}.thmb" "${wallTmb}"
    ln -fs "${thmbDir}/${wallHash[setIndex]}.blur" "${wallBlr}"
    ln -fs "${thmbDir}/${wallHash[setIndex]}.quad" "${wallQad}"
    ln -fs "${dcolDir}/${wallHash[setIndex]}.dcol" "${wallDcl}"
}

Wall_Change() {
    curWall="$(set_hash "${wallSet}")"
    for i in "${!wallHash[@]}"; do
        if [ "${curWall}" == "${wallHash[i]}" ]; then
            if [ "${1}" == "n" ]; then
                setIndex=$(((i + 1) % ${#wallList[@]}))
            elif [ "${1}" == "p" ]; then
                setIndex=$((i - 1))
            fi
            break
        fi
    done
    Wall_Cache
}

#// set variables

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"
wallSet="${HYDE_THEME_DIR}/wall.set"
wallCur="${cacheDir}/wall.set"
wallSqr="${cacheDir}/wall.sqre"
wallTmb="${cacheDir}/wall.thmb"
wallBlr="${cacheDir}/wall.blur"
wallQad="${cacheDir}/wall.quad"
wallDcl="${cacheDir}/wall.dcol"

#// check wall

setIndex=0
[ ! -d "${HYDE_THEME_DIR}" ] && echo "ERROR: \"${HYDE_THEME_DIR}\" does not exist" && exit 0
wallPathArray=("${HYDE_THEME_DIR}")
wallPathArray+=("${WALLPAPER_CUSTOM_PATHS[@]}")
get_hashmap "${wallPathArray[@]}"
[ ! -e "$(readlink -f "${wallSet}")" ] && echo "fixing link :: ${wallSet}" && ln -fs "${wallList[setIndex]}" "${wallSet}"

#// evaluate options

while getopts "nps:" option; do
    case $option in
    n) # set next wallpaper
        xtrans=${WALLPAPER_SWWW_TRANSITION_NEXT}
        xtrans="${xtrans:-"grow"}"
        Wall_Change n
        ;;
    p) # set previous wallpaper
        xtrans=${WALLPAPER_SWWW_TRANSITION_PREV}
        xtrans="${xtrans:-"outer"}"
        Wall_Change p
        ;;
    s) # set input wallpaper
        if [ -n "${OPTARG}" ] && [ -f "${OPTARG}" ]; then
            get_hashmap "${OPTARG}"
        fi
        Wall_Cache
        ;;
    *) # invalid option
        echo "... invalid option ..."
        echo "$(basename "${0}") -[option]"
        echo "n : set next wall"
        echo "p : set previous wall"
        echo "s : set input wallpaper"
        exit 1
        ;;
    esac
done

#// check swww daemon

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
print_log -sec "wallpaper" -stat "apply" "$(readlink -f "${wallSet}")"
swww img "$(readlink "${wallSet}")" --transition-bezier .43,1.19,1,.4 --transition-type "${xtrans}" --transition-duration "${wallTransDuration}" --transition-fps "${wallFramerate}" --invert-y --transition-pos "$(hyprctl cursorpos | grep -E '^[0-9]' || echo "0,0")" &

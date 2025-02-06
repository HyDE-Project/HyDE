#!/usr/bin/env bash

#// set variables

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"

# // Help message
show_help() {
    cat <<EOF
Usage: $(basename "$0") --[options|flags] [parameters]
options:
    -h, --help                Display this help message

flags:
    -b, --backend <backend>   Set wallpaper backend to use (swww, hyprpaper, etc.)

notes: 
       --backend <backend> is also use to cache wallpapers/background images e.g. hyprlock
           when '--backend hyprlock' is used, the wallpaper will be cached in
           ~/.cache/hyde/wall.hyprlock.png
EOF
    exit 0
}

#// set rofi scaling

font_scale="${ROFI_WALLPAPER_SCALE}"
[[ "${font_scale}" =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}

# set font name
font_name=${ROFI_WALLPAPER_FONT:-$ROFI_FONT}
font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
font_name=${font_name:-$(get_hyprConf "FONT")}

# set rofi font override
font_override="* {font: \"${font_name:-"JetBrainsMono Nerd Font"} ${font_scale}\";}"

# shellcheck disable=SC2154
elem_border=$((hypr_border * 3))

#// scale for monitor

mon_x_res=$(hyprctl -j monitors | jq '.[] | select(.focused == true) | (.width / .scale)')

#// generate config

elm_width=$(((28 + 8 + 5) * font_scale))
max_avail=$((mon_x_res - (4 * font_scale)))
col_count=$((max_avail / elm_width))
r_override="window{width:100%;}
    listview{columns:${col_count};spacing:5em;}
    element{border-radius:${elem_border}px;
    orientation:vertical;} 
    element-icon{size:28em;border-radius:0em;}
    element-text{padding:1em;}"

#// launch rofi menu

# shellcheck disable=SC2154
currentWall="$(basename "$(readlink "${HYDE_THEME_DIR}/wall.set")")"
wallPathArray=("${HYDE_THEME_DIR}")
wallPathArray+=("${WALLPAPER_CUSTOM_PATHS[@]}")
get_hashmap "${wallPathArray[@]}"
wallListBase=()
# shellcheck disable=SC2154
for wall in "${wallList[@]}"; do
    wallListBase+=("${wall##*/}") # get the basename // bash way
done

# shellcheck disable=SC2154
rofiSel=$(paste <(printf "%s\n" "${wallListBase[@]}") <(printf "|%s\n" "${wallHash[@]}") |
    awk -F '|' -v thmbDir="${thmbDir}" '{split($1, arr, "/"); print arr[length(arr)] "\x00icon\x1f" thmbDir "/" $2 ".sqre"}' |
    rofi -dmenu \
        -theme-str "${font_override}" \
        -theme-str "${r_override}" \
        -theme "${ROFI_WALLPAPER_STYLE:-selector}" \
        -select "${currentWall}" | xargs)

#// evaluate options

if [ -z "${*}" ]; then
    echo "No arguments provided"
    show_help
fi

# Define long options
LONGOPTS="backend:,help"

# Parse options
PARSED=$(
    if getopt --options b:h --longoptions $LONGOPTS --name "$0" -- "$@"; then
        exit 2
    fi
)

# Apply parsed options
eval set -- "$PARSED"
while true; do
    case "$1" in
    -b | --backend)
        # Set wallpaper backend to use (swww, hyprpaper, etc.)
        wallpaper_backend="${2:-"$WALLPAPER_BACKEND"}"
        shift 2
        ;;
    -h | --help)
        show_help
        ;;
    --)
        shift
        break
        ;;
    *)
        echo "Invalid option: $1"
        echo "Try '$(basename "$0") --help' for more information."
        exit 1
        ;;
    esac
done

main() {
    #// set full cache variables
    if [ -z "$wallpaper_backend" ]; then
        print_log -err "wallpaper" " No backend specified"
        print_log -err "wallpaper" " Please specify a backend, try '--backend swww'"
        exit 1
    fi

    #// apply wallpaper

    if [ -n "${rofiSel}" ]; then
        for i in "${!wallPathArray[@]}"; do
            setWall=$(find "${wallPathArray[i]}" -type f -name "${rofiSel}")
            [ -z "${setWall}" ] || break
        done
        if [ -n "${setWall}" && -n "${wallpaper_backend}" ]; then
            "${scrDir}/wallpaper.sh" -s "${setWall}" --backend "${wallpaper_backend}" --global
            notify-send -a "HyDE Alert" -i "${thmbDir}/$(set_hash "${setWall}").sqre" " ${rofiSel}"
        else
            notify-send -a "HyDE Alert" "Wallpaper not found"
        fi

    fi
}

main

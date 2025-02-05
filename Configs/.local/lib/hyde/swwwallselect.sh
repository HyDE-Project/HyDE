#!/usr/bin/env bash

#// set variables

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"

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

#// apply wallpaper

if [ -n "${rofiSel}" ]; then
    for i in "${!wallPathArray[@]}"; do
        setWall=$(find "${wallPathArray[i]}" -type f -name "${rofiSel}")
        [ -z "${setWall}" ] || break
    done
    if [ -n "${setWall}" ]; then
        "${scrDir}/swwwallpaper.sh" -s "${setWall}"
        notify-send -a "HyDE Alert" -i "${thmbDir}/$(set_hash "${setWall}").sqre" " ${rofiSel}"
    else
        notify-send -a "HyDE Alert" "Wallpaper not found"
    fi

fi

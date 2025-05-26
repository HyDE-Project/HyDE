#!/usr/bin/env bash

#// set variables

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"
wallbashModes=("theme" "auto" "dark" "light")

#// rofi select mode

rofi_wallbash() {
    font_scale=$ROFI_WALLBASH_MODE_SCALE
    [[ "${font_scale}" =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}
    r_scale="configuration {font: \"JetBrainsMono Nerd Font ${font_scale}\";}"
    elem_border=$((hypr_border * 4))
    r_override="window{border-radius:${elem_border}px;} element{border-radius:${elem_border}px;}"
    rofiSel=$(parallel echo {} ::: "${wallbashModes[@]}" | rofi -dmenu \
        -theme-str "${r_scale}" \
        -theme-str "${r_override}" \
        -theme wallbash \
        -select "${wallbashModes[${enableWallDcol}]}")
    if [ ! -z "${rofiSel}" ]; then
        setMode="$(parallel --link echo {} ::: "${!wallbashModes[@]}" ::: "${wallbashModes[@]}" ::: "${rofiSel}" | awk '{if ($2 == $3) print $1}')"
    else
        exit 0
    fi
}

#// switch mode

step_wallbash() {
    for i in "${!wallbashModes[@]}"; do
        if [ "${enableWallDcol}" == "${i}" ]; then
            if [ "${1}" == "n" ]; then
                setMode=$(((i + 1) % ${#wallbashModes[@]}))
            elif [ "${1}" == "p" ]; then
                setMode=$((i - 1))
            fi
            break
        fi
    done
}

#// apply wallbash mode

case "${1}" in
m | -m | --menu) rofi_wallbash ;;
n | -n | --next) step_wallbash n ;;
p | -p | --prev) step_wallbash p ;;
*) step_wallbash n ;;
esac

export reload_flag=1
[[ "${setMode}" -lt 0 ]] && setMode=$((${#wallbashModes[@]} - 1))
set_conf "enableWallDcol" "${setMode}"
"${scrDir}/theme.switch.sh"
notify-send -a "HyDE Alert" -i "${ICONS_DIR}/Wallbash-Icon/hyde.png" " ${wallbashModes[setMode]} mode"

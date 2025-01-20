#!/usr/bin/env bash

#// set variables
scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"
# shellcheck disable=SC2154

#// set rofi scaling
rofiScale="${ROFI_THEME_SCALE}"
[[ "${rofiScale}" =~ ^[0-9]+$ ]] || rofiScale=${ROFI_SCALE:-10}
# shellcheck disable=SC2154
elem_border=$((hypr_border * 5))
icon_border=$((elem_border - 5))

#// scale for monitor
mon_x_res=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .width')
mon_scale=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .scale' | sed "s/\.//")
mon_x_res=$((mon_x_res * 100 / mon_scale))

#// generate config
ROFI_THEME_STYLE="${ROFI_THEME_STYLE:-1}"
# shellcheck disable=SC2154
case "${ROFI_THEME_STYLE}" in
2) # adapt to style 2
    elm_width=$(((20 + 12) * rofiScale * 2))
    max_avail=$((mon_x_res - (4 * rofiScale)))
    col_count=$((max_avail / elm_width))
    r_override="window { width: 100%; background-color: #00000003; }
listview { columns: ${col_count}; }
element { border-radius: ${elem_border}px; background-color: @main-bg; }
element-icon { size: 20em; border-radius: ${icon_border}px 0 0 ${icon_border}px; }"
    thmbExtn="quad"
    ;;
*) # default to style 1
    elm_width=$(((23 + 12 + 1) * rofiScale * 2))
    max_avail=$((mon_x_res - (4 * rofiScale)))
    col_count=$((max_avail / elm_width))
    r_override="window { width: 100%; }
listview { columns: ${col_count}; }
element { border-radius: ${elem_border}px; padding: 0.5em; }
element-icon { size: 23em; border-radius: ${icon_border}px; }"
    thmbExtn="sqre"
    ;;
esac

#// launch rofi menu
get_themes

# shellcheck disable=SC2154
rofiSel=$(
    i=0
    while [ $i -lt ${#thmList[@]} ]; do
        echo -en "${thmList[$i]}\x00icon\x1f${thmbDir}/$(set_hash "${thmWall[$i]}").${thmbExtn:-sqre}\n"
        i=$((i + 1))
    done | rofi -dmenu \
        -theme "selector" \
        -theme-str "${r_override}" \
        -select "${HYDE_THEME}"
)

#// apply theme
if [ -n "${rofiSel}" ]; then
    "${scrDir}/themeswitch.sh" -s "${rofiSel}"
    # shellcheck disable=SC2154
    notify-send -a "HyDE Alert" -i "${iconsDir}/Wallbash-Icon/hyde.png" " ${rofiSel}"
fi

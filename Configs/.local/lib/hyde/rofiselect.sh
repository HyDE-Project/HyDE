#!/usr/bin/env bash

#// set variables

# shellcheck source=$HOME/.local/bin/hyde-shell
# shellcheck disable=SC1091
if ! source "$(which hyde-shell)"; then
    echo "[wallbash] code :: Error: hyde-shell not found."
    echo "[wallbash] code :: Is HyDE installed?"
    exit 1
fi

rofiStyleDir="${SHARE_DIR}/hyde/rofi/themes"
rofiAssetDir="${SHARE_DIR}/hyde/rofi/assets"

#// set rofi scaling
font_scale=$ROFI_SELECT_SCALE
[[ "${font_scale}" =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}

# set font name
font_name=${ROFI_SELECT_FONT:-$ROFI_FONT}
font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
font_name=${font_name:-$(get_hyprConf "FONT")}

# set rofi font override
font_override="* {font: \"${font_name:-"JetBrainsMono Nerd Font"} ${font_scale}\";}"

elem_border=$((hypr_border * 5))
icon_border=$((elem_border - 5))

#// scale for monitor

mon_data=$(hyprctl -j monitors)
mon_x_res=$(jq '.[] | select(.focused==true) | if (.transform % 2 == 0) then .width else .height end' <<<"${mon_data}")
mon_scale=$(jq '.[] | select(.focused==true) | .scale' <<<"${mon_data}" | sed "s/\.//")
mon_x_res=$((mon_x_res * 100 / mon_scale))

#// generate config

elm_width=$(((20 + 12 + 16) * font_scale))
max_avail=$((mon_x_res - (4 * font_scale)))
col_count=$((max_avail / elm_width))
[[ "${col_count}" -gt 5 ]] && col_count=5
r_override="window{width:100%;} 
    listview{columns:${col_count};}
    element{orientation:vertical;border-radius:${elem_border}px;}
    element-icon{border-radius:${icon_border}px;size:20em;} 
    element-text{enabled:false;}"

#// launch rofi menu

RofiSel=$(
    # shellcheck disable=SC2154
    find "${rofiStyleDir}" -type f -exec grep -l "Attr.*launcher.*" {} \; |
        while read -r file; do
            baseName=$(basename "${file}" .rasi)
            assetFile="${file/rofi\/themes/rofi\/assets}"
            assetFile="${assetFile%.rasi}.png"
            echo -en "${baseName}\x00icon\x1f${assetFile}\n"
        done | sort -n | rofi -dmenu \
        -theme-str "${font_override}" \
        -theme-str "${r_override}" \
        -theme "${ROFI_SELECT_STYLE:-selector}" \
        -select "${rofiStyle}"
)

#// apply rofi style

if [ -n "${RofiSel}" ]; then
    set_conf "rofiStyle" "${RofiSel}"
    notify-send -a "HyDE Alert" -r 2 -t 2200 -i "${rofiAssetDir}/${RofiSel}.png" " style ${RofiSel} applied..."
fi
if [ -n "$ROFI_LAUNCH_STYLE" ]; then
    notify-send -a "HyDE Alert" -r 3 -u critical "Style: '$ROFI_LAUNCH_STYLE' is explicitly set, remove it in ~/.config/hyde/config.toml for changes to take effect."
fi

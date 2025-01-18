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
rofiScale=$ROFI_STYLE_SCALE
[[ "${rofiScale}" =~ ^[0-9]+$ ]] || rofiScale=${ROFI_SCALE:-10}
r_scale="configuration {font: \"JetBrainsMono Nerd Font ${rofiScale}\";}"
elem_border=$((hypr_border * 5))
icon_border=$((elem_border - 5))

#// scale for monitor

mon_x_res=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .width')
mon_scale=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .scale' | sed "s/\.//")
mon_x_res=$((mon_x_res * 100 / mon_scale))

#// generate config

elm_width=$(((20 + 12 + 16) * rofiScale))
max_avail=$((mon_x_res - (4 * rofiScale)))
col_count=$((max_avail / elm_width))
[[ "${col_count}" -gt 5 ]] && col_count=5
r_override="window{width:100%;} listview{columns:${col_count};} element{orientation:vertical;border-radius:${elem_border}px;} element-icon{border-radius:${icon_border}px;size:20em;} element-text{enabled:false;}"

#// launch rofi menu

RofiSel=$(find "${rofiStyleDir}" -name "style_*" |
    awk -F '[_.]' '{print $((NF - 1))}' |
    while read styleNum; do
        echo -en "${styleNum}\x00icon\x1f${rofiAssetDir}/style_${styleNum}.png\n"
    done | sort -n | rofi -dmenu \
    -theme-str "${r_override}" \
    -config "selector" \
    -select "${rofiStyle}")

#// apply rofi style

if [ -n "${RofiSel}" ]; then
    set_conf "rofiStyle" "${RofiSel}"
    notify-send -a "HyDE Alert" -r 2 -t 2200 -i "${rofiAssetDir}/style_${RofiSel}.png" " style ${RofiSel} applied..."
fi
if [ -n "$ROFI_LAUNCH_STYLE" ]; then
    notify-send -a "HyDE Alert" -r 3 -u critical "Style: '$ROFI_LAUNCH_STYLE' is explicitly set, remove it in ~/.config/hyde/config.toml for changes to take effect."
fi

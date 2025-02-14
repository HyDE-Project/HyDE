#!/usr/bin/env sh


#// set variables

scrDir="$(dirname "$(realpath "$0")")"
source "${scrDir}/globalcontrol.sh"
rofiConf="${confDir}/rofi/selector.rasi"
rofiStyleDir="${confDir}/rofi/styles"
rofiAssetDir="${confDir}/rofi/assets"


#// set rofi scaling

[[ "${rofiScale}" =~ ^[0-9]+$ ]] || rofiScale=10
r_scale="configuration {font: \"JetBrainsMono Nerd Font ${rofiScale}\";}"
elem_border=$(( hypr_border * 5 ))
icon_border=$(( elem_border - 5 ))


#// scale for monitor

mon_x_res=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .width')
mon_scale=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .scale' | sed "s/\.//")
mon_x_res=$(( mon_x_res * 100 / mon_scale ))


#// generate config

elm_width=$(( (20 + 12 + 16 ) * rofiScale ))
max_avail=$(( mon_x_res - (4 * rofiScale) ))
col_count=$(( max_avail / elm_width ))
[[ "${col_count}" -gt 5 ]] && col_count=5
r_override="window{width:100%;} listview{columns:${col_count};} element{orientation:vertical;border-radius:${elem_border}px;} element-icon{border-radius:${icon_border}px;size:20em;} element-text{enabled:false;}"


#// launch rofi menu

RofiSel=$(ls ${rofiStyleDir}/style_*.rasi | awk -F '[_.]' '{print $((NF - 1))}' | while read styleNum
do
    echo -en "${styleNum}\x00icon\x1f${rofiAssetDir}/style_${styleNum}.png\n"
done | sort -n | rofi -dmenu -theme-str "${r_override}" -config "${rofiConf}" -select "${rofiStyle}")


#// apply rofi style

if [ ! -z "${RofiSel}" ] ; then
    set_conf "rofiStyle" "${RofiSel}"
    notify-send -a "t1" -r 91190 -t 2200 -i "${rofiAssetDir}/style_${RofiSel}.png" " style ${RofiSel} applied..." 
fi


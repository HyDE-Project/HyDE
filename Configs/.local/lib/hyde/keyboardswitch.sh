#!/usr/bin/env sh

scrDir=`dirname "$(realpath "$0")"`
source $scrDir/globalcontrol.sh

hyprctl switchxkblayout all next

layMain=$(hyprctl -j devices | jq '.keyboards' | jq '.[] | select (.main == true)' | awk -F '"' '{if ($2=="active_keymap") print $4}')
notify-send -a "HyDE Alert" -r 91190 -t 800 -i "${iconsDir}/Wallbash-Icon/keyboard.svg" "${layMain}"


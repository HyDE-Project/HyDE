#!/usr/bin/env bash

scrDir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
source "$scrDir/globalcontrol.sh"

hyprctl switchxkblayout all next

layMain=$(hyprctl -j devices | jq '.keyboards' | jq '.[] | select (.main == true)' | awk -F '"' '{if ($2=="active_keymap") print $4}')
notify-send -a "HyDE Alert" -r 91190 -t 800 -i "${ICONS_DIR}/Wallbash-Icon/keyboard.svg" "${layMain}"

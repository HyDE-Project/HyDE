#!/usr/bin/env bash
scrDir=$(dirname "$(realpath "$0")")
source "$scrDir/globalcontrol.sh"
# shellcheck disable=SC1091
source "$scrDir/shutils/l10n.sh"
hyprctl switchxkblayout current next
layMain=$(hyprctl -j devices | jq '.keyboards' | jq '.[] | select (.main == true)' | awk -F '"' '{if ($2=="active_keymap") print $4}')
send_notifs -a "HyDE Alert" -r 91190 -t 800 -i "$ICONS_DIR/Wallbash-Icon/keyboard.svg" "$layMain"

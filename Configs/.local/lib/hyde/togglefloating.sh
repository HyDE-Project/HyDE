#!/usr/bin/env bash

hyprctl dispatch togglefloating

#Use default togglefloating behavior
if [ $# -eq 0 ]; then    
    exit
fi

#Only resize window when it's floating
if [[ $(hyprctl activewindow -j | jq -r '.floating') == "true" ]]; then
    hyprctl --batch "dispatch resizeactive exact $1 $1; dispatch centerwindow"

    size="${1%\%}"

    #When size is less than 75%, give window random offset
    if [[ "$size" -lt 75 ]]; then
        hyprctl dispatch moveactive $((RANDOM % 200 - 100)) $((RANDOM % 200 - 100))
    fi
fi
#!/usr/bin/env bash

# set variables

scrDir=$(dirname "$(realpath "$0")")
scrDir="${scrDir:-$HOME/.local/lib/hyde}"
source $scrDir/globalcontrol.sh
confDir=${confDir:-$XDG_CONFIG_HOME}
rofi_config="$confDir/rofi/quickapps.rasi"

if [ $# -eq 0 ]; then
    echo "usage: ./quickapps.sh <app1> <app2> ... <app[n]>"
    exit 1
else
    appCount="$#"
fi

# Set rofi scaling
[[ "${font_scale}" =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}

# set font name
font_name=${ROFI_QUICKAPPS_FONT:-$ROFI_FONT}
font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
font_name=${font_name:-$(get_hyprConf "FONT")}

# set rofi font override
font_override="* {font: \"${font_name:-"JetBrainsMono Nerd Font"} ${font_scale}\";}"

hypr_border=${hypr_border:-"$(hyprctl -j getoption decoration:rounding | jq '.int')"}
wind_border=$((hypr_border * 3 / 2))
elem_border=$((hypr_border == 0 ? 5 : hypr_border))

# Evaluate spawn position
readarray -t curPos < <(hyprctl cursorpos -j | jq -r '.x,.y')
readarray -t monRes < <(hyprctl -j monitors | jq '.[] | select(.focused==true) | .width,.height,.scale,.x,.y')
readarray -t offRes < <(hyprctl -j monitors | jq -r '.[] | select(.focused==true).reserved | map(tostring) | join("\n")')
monRes[2]="${monRes[2]//./}"
monRes[0]=$((monRes[0] * 100 / monRes[2]))
monRes[1]=$((monRes[1] * 100 / monRes[2]))
curPos[0]=$((curPos[0] - monRes[3]))
curPos[1]=$((curPos[1] - monRes[4]))

if [ "${curPos[0]}" -ge "$((monRes[0] / 2))" ]; then
    x_pos="east"
    x_off="-$((monRes[0] - curPos[0] - offRes[2]))"
else
    x_pos="west"
    x_off="$((curPos[0] - offRes[0]))"
fi

if [ "${curPos[1]}" -ge "$((monRes[1] / 2))" ]; then
    y_pos="south"
    y_off="-$((monRes[1] - curPos[1] - offRes[3]))"
else
    y_pos="north"
    y_off="$((curPos[1] - offRes[1]))"
fi
hypr_width=${hypr_width:-"$(hyprctl -j getoption general:border_size | jq '.int')"}

# override rofi

dockHeight=$((monRes[0] * 3 / 100))
dockWidth=$((dockHeight * appCount))
iconSize=$((dockHeight - 4))
wind_border=$((hypr_border * 3 / 2))
r_override="window{
height:${dockHeight};
width:${dockWidth};
location:${x_pos} ${y_pos};
anchor:${x_pos} ${y_pos};
x-offset:${x_off}px;
y-offset:${y_off}px;
border:${hypr_width}px;
border-radius:${wind_border}px;
}
listview{
columns:${appCount};
}
element{border-radius:${wind_border}px;
}
element-icon{size:${iconSize}px;
}
wallbox{
border-radius:${elem_border}px;
}
"

# launch rofi menu

if [ -d /run/current-system/sw/share/applications ]; then
    appDir=/run/current-system/sw/share/applications
else
    appDir=/usr/share/applications
fi

RofiSel=$(
    for qApp in "$@"; do
        Lkp=$(grep "$qApp" $appDir/* | grep 'Exec=' | awk -F ':' '{print $1}' | head -1)
        Ico=$(grep 'Icon=' "$Lkp" | awk -F '=' '{print $2}' | head -1)
        # Ico=$(grep 'Icon=' "$qApp" | awk -F '=' '{print $2}' | head -1)

        echo -en "${qApp}\x00icon\x1f${Ico}\n"
    done | rofi -no-fixed-num-lines -dmenu \
        -theme-str "${r_override}" \
        -theme-str "${font_override}" \
        -config "quickapps"
)

[[ -n "${RofiSel}" ]] && gtk-launch "$RofiSel" &

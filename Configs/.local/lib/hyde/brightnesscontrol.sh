#!/usr/bin/env sh

# Check if the script is already running
pgrep -cf "${0##*/}" | grep -qv 1 && echo "An instance of the script is already running..." && exit 1

scrDir=`dirname "$(realpath "$0")"`
source $scrDir/globalcontrol.sh

# Check if SwayOSD is installed
use_swayosd=false
if command -v swayosd-client >/dev/null 2>&1 && pgrep -x swayosd-server >/dev/null; then
    use_swayosd=true
fi

print_error()
{
cat << EOF
    $(basename ${0}) <action> [step] 
    ...valid actions are...
        i -- <i>ncrease brightness [logarithmic step]
        d -- <d>ecrease brightness [logarithmic step]

    Example:
        $(basename ${0}) i 10    # Increase brightness by 10% (logarithmic scaling)
        $(basename ${0}) d       # Decrease brightness by default logarithmic step
EOF
}

send_notification() {
    brightness=`brightnessctl info | grep -oP "(?<=\()\d+(?=%)" | cat`
    brightinfo=$(brightnessctl info | awk -F "'" '/Device/ {print $2}')
    angle="$(((($brightness + 2) / 5) * 5))"
    ico="$HOME/.config/dunst/icons/vol/vol-${angle}.svg"
    bar=$(seq -s "." $(($brightness / 15)) | sed 's/[0-9]//g')
    notify-send -a "t2" -r 91190 -t 800 -i "${ico}" "${brightness}${bar}" "${brightinfo}"
}

get_brightness() {
    brightnessctl -m | grep -o '[0-9]\+%' | head -c-2
}

adjust_brightness_logarithmically() {
    local current_brightness=$(get_brightness)
    local action=$1
    local step=${2:-10} # Default step value, can be overridden

    # Calculate the Weber-Fechner adjustment factor
    local adjustment
    if [[ "$action" == "increase" ]]; then
        adjustment=$(awk "BEGIN {print int($current_brightness * ($step / 100.0))}")
        new_brightness=$((current_brightness + adjustment))
    elif [[ "$action" == "decrease" ]]; then
        adjustment=$(awk "BEGIN {print int($current_brightness * ($step / 100.0))}")
        new_brightness=$((current_brightness - adjustment))
    fi

    # Ensure the new brightness stays within the range of 1% to 100%
    new_brightness=$((new_brightness < 1 ? 1 : (new_brightness > 100 ? 100 : new_brightness)))

    # If brightness is below 10%, we prevent too steep reductions
    if [ "$action" == "decrease" ] && [ "$new_brightness" -lt 10 ] && [ "$current_brightness" -gt 10 ]; then
        new_brightness=$((current_brightness - 2))
    fi

    brightnessctl set "${new_brightness}%"
    send_notification
}



case $1 in
i|-i)  # increase the backlight
    if [[ $(get_brightness) -lt 10 ]] ; then
        adjust_brightness_logarithmically "increase" 1
    else
        adjust_brightness_logarithmically "increase" "${2:-10}"
    fi
    ;;
d|-d)  # decrease the backlight
    if [[ $(get_brightness) -le 10 ]] ; then
        adjust_brightness_logarithmically "decrease" 1
    else
        adjust_brightness_logarithmically "decrease" "${2:-10}"
    fi
    ;;
*)  # print error
    print_error ;;
esac

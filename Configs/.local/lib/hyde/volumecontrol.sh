#!/usr/bin/env bash

# Source global control script
scrDir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
source "$scrDir/globalcontrol.sh"
confDir=${confDir:-$XDG_CONFIG_HOME}

# Check if SwayOSD is installed
use_swayosd=false
isNotify=${VOLUME_NOTIFY:-true}
if command -v swayosd-client >/dev/null 2>&1 && pgrep -x swayosd-server >/dev/null; then
    use_swayosd=true
fi
isVolumeBoost="${VOLUME_BOOST:-false}"
# Define functions

print_usage() {
    cat <<EOF
Usage: $(basename "$0") -[device] <action> [step]

Devices/Actions:
    -i    Input device
    -o    Output device
    -p    Player application
    -s    Select output device
    -t    Toggle to next output device

Actions:
    i     Increase volume
    d     Decrease volume
    m     Toggle mute
    q     Quiet mode (no notifications)

Optional:
    step  Volume change step (default: 5)

Examples:
    $(basename "$0") -o i 5     # Increase output volume by 5
    $(basename "$0") -i m       # Toggle input mute
    $(basename "$0") -p spotify d 10  # Decrease Spotify volume by 10
    $(basename "$0") -p '' d 10  # Decrease volume by 10 for all players
    $(basename "$0") -s          # Select output device
    $(basename "$0") -t          # Toggle to next output device
    $(basename "$0") -q    # Increase output volume by 5 in quiet mode
EOF
    exit 1
}

notify_vol() {
    local vol=$1
    angle=$((((vol + 2) / 5) * 5))
    iconStyle="knob"
    # cap the icon at 100 if vol > 100
    [ "$angle" -gt 100 ] && angle=100
    ico="${icodir}/${iconStyle}-${angle}.svg"
    bar=$(seq -s "." $((vol / 15)) | sed 's/[0-9]//g')
    [[ "${isNotify}" == true ]] && notify-send -a "HyDE Notify" -r 8 -t 800 -i "${ico}" "${vol}${bar}" "${nsink}"
}

notify_mute() {
    mute=$(pamixer "${srce}" --get-mute | cat)
    [ "${srce}" == "--default-source" ] && dvce="microphone" || dvce="speaker"
    if [ "${mute}" == "true" ]; then
        [[ "${isNotify}" == true ]] && notify-send -a "HyDE Notify" -r 8 -t 800 -i "${icodir}/muted-${dvce}.svg" "muted" "${nsink}"
    else
        [[ "${isNotify}" == true ]] && notify-send -a "HyDE Notify" -r 8 -t 800 -i "${icodir}/unmuted-${dvce}.svg" "unmuted" "${nsink}"
    fi
}

change_volume() {
    local action=$1
    local step=$2
    local device=$3
    local delta="-"
    local mode="--output-volume"

    [ "${action}" = "i" ] && delta="+"
    [ "${srce}" = "--default-source" ] && mode="--input-volume"
    case $device in
    "pamixer")
        if [ "${isVolumeBoost}" = true ]; then
            $use_swayosd && swayosd-client ${mode} "${delta}${step}" --max-volume "${VOLUME_BOOST_LIMIT:-150}" && exit 0
            pamixer "$srce" "${allow_boost:-}" --allow-boost --set-limit "${VOLUME_BOOST_LIMIT:-150}" -"${action}" "$step"
        else
            $use_swayosd && swayosd-client ${mode} "${delta}${step}" && exit 0
            pamixer "$srce" -"${action}" "$step"
        fi
        vol=$(pamixer "$srce" --get-volume)
        ;;
    "playerctl")
        playerctl --player="$srce" volume "$(awk -v step="$step" 'BEGIN {print step/100}')${delta}"
        vol=$(playerctl --player="$srce" volume | awk '{ printf "%.0f\n", $0 * 100 }')
        ;;
    esac

    notify_vol "$vol"
}

toggle_mute() {
    local device=$1
    local mode="--output-volume"
    [ "${srce}" = "--default-source" ] && mode="--input-volume"
    case $device in
    "pamixer")
        $use_swayosd && swayosd-client "${mode}" mute-toggle && exit 0
        pamixer "$srce" -t
        notify_mute
        ;;
    "playerctl")
        local volume_file
        volume_file="/tmp/$(basename "$0")_last_volume_${srce:-all}"
        if [ "$(playerctl --player="$srce" volume | awk '{ printf "%.2f", $0 }')" != "0.00" ]; then
            playerctl --player="$srce" volume | awk '{ printf "%.2f", $0 }' >"$volume_file"
            playerctl --player="$srce" volume 0
        else
            if [ -f "$volume_file" ]; then
                last_volume=$(cat "$volume_file")
                playerctl --player="$srce" volume "$last_volume"
            else
                playerctl --player="$srce" volume 0.5 # Default to 50% if no saved volume
            fi
        fi
        notify_mute
        ;;
    esac
}

select_output() {
    local selection=$1
    if [ -n "$selection" ]; then
        device=$(pactl list sinks | grep -C2 -F "Description: $selection" | grep Name | cut -d: -f2 | xargs)
        if pactl set-default-sink "$device"; then
            notify-send -t 2000 -i "${icodir}/unmuted-speaker.svg" -r 8 -u low "Activated: $selection"
        else
            notify-send -t 2000 -r 8 -u critical "Error activating $selection"
        fi
    else
        pactl list sinks | grep -ie "Description:" | awk -F ': ' '{print $2}' | sort
    fi
}

toggle_output() {
    local default_sink
    local current_index
    default_sink=$(pamixer --get-default-sink | awk -F '"' 'END{print $(NF - 1)}')
    mapfile -t sink_array < <(select_output)
    current_index=$(printf '%s\n' "${sink_array[@]}" | grep -n "$default_sink" | cut -d: -f1)
    local next_index=$(((current_index % ${#sink_array[@]}) + 1))
    local next_sink="${sink_array[next_index - 1]}"
    select_output "$next_sink"
}

# Main script logic

# Set default variables
iconsDir="${iconsDir:-$XDG_DATA_HOME/icons}"
icodir="${iconsDir}/Wallbash-Icon/media"
step=${VOLUME_STEPS:-5}

while getopts "iop:stq" opt; do
    case $opt in
    i)
        device="pamixer"
        srce="--default-source"
        nsink=$(pamixer --list-sources | awk -F '"' 'END {print $(NF - 1)}')
        ;;
    o)
        device="pamixer"
        srce=""
        nsink=$(pamixer --get-default-sink | awk -F '"' 'END{print $(NF - 1)}')
        ;;
    p)
        device="playerctl"
        srce="${OPTARG}"
        nsink=$(playerctl --list-all | grep -w "$srce")
        ;;
    s)
        if ! selected_output=$(hyprland-dialog --text "$(
            echo -e "Devices:"
            select_output | sed 's/^/           🔈 /'
        )" \
            --title "Choose an output device" \
            --buttons "$(select_output | sed 's/$/;/')"); then
            selected_output=$(select_output | rofi -dmenu -theme "notification")
        fi
        select_output "${selected_output}"
        exit
        ;;
    t)
        toggle_output
        exit
        ;;
    q)
        isNotify=false
        ;;
    *) print_usage ;;
    esac
done

shift $((OPTIND - 1))

# Check if device is set
[ -z "$device" ] && print_usage

# Execute action
case $1 in
i | d) change_volume "$1" "${2:-$step}" "$device" ;;
m) toggle_mute "$device" ;;
*) print_usage ;;
esac

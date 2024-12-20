#! /bin/env bash

# Set directory paths and file locations
scrDir=$(dirname "$(realpath "$0")")
source "$scrDir/globalcontrol.sh"
sunsetConf="${confDir}/hypr/hyprsunset.json"

# Default temperature settings
default=6500
step=500
min=1000
max=20000

notify="${waybar_temperature_notification:-true}"

# Ensure the configuration file exists, create it if not
if [ ! -f "$sunsetConf" ]; then
    echo "{\"temp\": $default, \"user\": 1}" > "$sunsetConf"
fi

# Read current temperature and mode from the configuration file
currentTemp=$(jq '.temp' "$sunsetConf")
toggle_mode=$(jq '.user' "$sunsetConf")
[ -z "$currentTemp" ] && currentTemp=$default
[ -z "$toggle_mode" ] && toggle_mode=1

# Notification function
send_notification() {
    message="Temperature: $newTemp"
    notify-send -a "t2" -r 91192 -t 800 "$message"
}

#keep temp in range
clamp_temp() {
    newTemp=$1
    [ "$newTemp" -lt "$min" ] && newTemp=$min
    [ "$newTemp" -gt "$max" ] && newTemp=$max
    echo "$newTemp"
}

print_error() {
    cat << EOF
    $(basename ${0}) <action> [mode]
    ...valid actions are...
        i -- <i>ncrease screen temperature [+500]
        d -- <d>ecrease screen temperature [-500]
        r -- <r>ead screen temperature
        t -- <t>oggle temperature mode (on/off)
    Example:
        $(basename ${0}) r       # Read the temperature value
        $(basename ${0}) i       # Increase temperature by 500
        $(basename ${0}) d       # Decrease temperature by 500
        $(basename ${0}) t -q    # Toggle mode quietly
EOF
}

if [ $# -ge 1 ]; then
    if [[ "$2" == *q* ]] || [[ "$3" == *q* ]]; then
	    notify=false
    fi
    if [[ "$2" =~ ^[0-9]+$ ]]; then
	    step=$2
    elif [[ "$3" =~ ^[0-9]+$ ]]; then
        step=$3 
    fi
fi

case "$1" in
    i) action="increase" ;;
    d) action="decrease" ;;
    r) action="read" ;;
    t) action="toggle" ;;
    *) print_error; exit 1 ;;  # If the argument is invalid, show usage and exit
esac

# Apply action based on the selected option
case $action in
    increase) 
        newTemp=$(clamp_temp "$(($currentTemp + $step))") && echo "{\"temp\": $newTemp, \"user\": $toggle_mode}" > "$sunsetConf"
        ;;
    decrease) 
        newTemp=$(clamp_temp "$(($currentTemp - $step))") && echo "{\"temp\": $newTemp, \"user\": $toggle_mode}" > "$sunsetConf"
        ;;
    read) 
        newTemp=$currentTemp
        ;;
    toggle) 
        toggle_mode=$((1 - $toggle_mode))
        [ "$toggle_mode" -eq 1 ] && newTemp=$currentTemp || newTemp=$default
        jq --argjson toggle_mode "$toggle_mode" '.user = $toggle_mode' "$sunsetConf" > "${sunsetConf}.tmp" && mv "${sunsetConf}.tmp" "$sunsetConf"
        ;;
esac

# Send notification if enabled
[ "$notify" = true ] && send_notification

# Fetch current running temperature
current_running_temp=$(pgrep -a hyprsunset | grep -- '--temperature' | awk '{for(i=1;i<=NF;i++) if ($i ~ /--temperature/) print $(i+1)}')

if [ "$action" = "read" ]; then
    if [ "$toggle_mode" -eq 1 ] && [ "$current_running_temp" != "$currentTemp" ]; then
        pkill -x hyprsunset
        hyprsunset --temperature "$currentTemp" > /dev/null &
    fi
else
    pkill -x hyprsunset
    if [ "$toggle_mode" -eq 0 ]; then
        hyprsunset -i > /dev/null &
    else
        hyprsunset --temperature "$newTemp" > /dev/null &
    fi
fi

# Print status message
echo "{\"alt\":\"$( [ "$toggle_mode" -eq 1 ] && echo 'active' || echo 'inactive' )\", \"tooltip\":\"Sunset mode $( [ "$toggle_mode" -eq 1 ] && echo 'active' || echo 'inactive' )\"}"

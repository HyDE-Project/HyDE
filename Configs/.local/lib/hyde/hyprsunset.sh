#! /bin/env bash

# shellcheck source=$HOME/.local/bin/hyde-shell
# shellcheck disable=SC1091
if ! source "$(which hyde-shell)"; then
    echo "[$0] :: Error: hyde-shell not found."
    echo "[$0] :: Is HyDE installed?"
    exit 1
fi

sunsetConf="${XDG_STATE_HOME:-$HOME/.local/state}/hyde/hyprsunset"

# Default settings
default_temp=6500
default_gamma=100
temp_step=500
gamma_step=5
min_temp=1000
max_temp=20000
min_gamma=20
max_gamma=100

notify="${waybar_temperature_notification:-true}"

# Ensure the configuration file exists, create it if not
if [ ! -f "$sunsetConf" ]; then
    printf "%d|%d|%d\n" "$default_temp" "$default_gamma" 1 >"$sunsetConf"
fi

# Read current settings from the configuration file (PSV format: temp|gamma|state)
IFS='|' read -r currentTemp currentGamma toggle_mode <"$sunsetConf"
[ -z "$currentTemp" ] && currentTemp=$default_temp
[ -z "$currentGamma" ] && currentGamma=$default_gamma
[ -z "$toggle_mode" ] && toggle_mode=1

# Notification function
# Notification function
send_notification() {
    local title message

    if [ "$action" = "toggle" ]; then
        if [ "$toggle_mode" -eq 1 ]; then
            title="Hyprsunset: ON"
            # message="Temp: ${currentTemp}K, Gamma: ${currentGamma}"
        else
            title="Hyprsunset: OFF"
            message=""
        fi
    elif [ -n "$newTemp" ]; then
        title="Mode: Temperature"
        message="${newTemp}K"
    elif [ -n "$newGamma" ]; then
        title="Mode: Gamma"
        message="$newGamma"
    fi

    # Send notification with title and message separated
    if [ -n "$message" ]; then
        notify-send -a "HyDE Notify" -r 19 -t 800 -i redshift "$message" "$title"
    else
        notify-send -a "HyDE Notify" -r 19 -t 800 -i redshift  "$title"
    fi
}
# Signal process function
send_signal_to_process() {
    if [ -n "$signal_proc" ]; then
        # Support both comma and colon as separators
        if [[ "$signal_proc" == *","* ]]; then
            IFS=',' read -r process signal <<<"$signal_proc"
        elif [[ "$signal_proc" == *":"* ]]; then
            IFS=':' read -r process signal <<<"$signal_proc"
        else
            echo "Error: Invalid sigproc format. Use PROCESS,SIGNAL or PROCESS:SIGNAL"
            return 1
        fi

        # Validate signal number
        if ! [[ "$signal" =~ ^[0-9]+$ ]]; then
            echo "Error: Signal must be a number"
            return 1
        fi

        # Send signal to all matching processes
        if pgrep -x "$process" >/dev/null; then
            pkill -RTMIN+"$signal" "$process" 2>/dev/null || echo "Warning: Failed to send signal $signal to $process"
        else
            echo "Warning: Process '$process' not found"
        fi
    fi
}

# Keep temp in range
clamp_temp() {
    local temp=$1
    [ "$temp" -lt "$min_temp" ] && temp=$min_temp
    [ "$temp" -gt "$max_temp" ] && temp=$max_temp
    echo "$temp"
}

# Keep gamma in range
clamp_gamma() {
    local gamma=$1
    # Gamma is integer from 20-100
    [ "$gamma" -lt "$min_gamma" ] && gamma=$min_gamma
    [ "$gamma" -gt "$max_gamma" ] && gamma=$max_gamma
    echo "$gamma"
}

# Query current running temperature from hyprctl
get_running_temp() {
    hyprctl hyprsunset temperature 2>/dev/null || echo "$default_temp"
}

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
    --cm MODE                   Color mode: 'temp' for temperature, 'gamma' for gamma
    -i, --increase [STEP]       Increase the selected color mode value
    -d, --decrease [STEP]       Decrease the selected color mode value
    -s, --set VALUE             Set specific value for the selected color mode
    -r, --read                  Read current screen temperature and gamma
    -t, --toggle                Toggle hyprsunset (on/off)
    -q, --quiet                 Disable notifications
    -P, --sigproc PROC,SIGNAL   Send signal to process (e.g., --sigproc waybar,19)
    -h, --help                  Show this help message

Examples:
    $(basename "$0") -r                     # Read current values
    $(basename "$0") --cm temp -i           # Increase temperature by 500K
    $(basename "$0") --cm temp -d 1000      # Decrease temperature by 1000K
    $(basename "$0") --cm temp -s 4000      # Set temperature to 4000K
    $(basename "$0") --cm gamma -i          # Increase gamma by 5
    $(basename "$0") --cm gamma -d 10       # Decrease gamma by 10
    $(basename "$0") --cm gamma -s 80       # Set gamma to 80
    $(basename "$0") -t --quiet             # Toggle mode quietly
    $(basename "$0") --sigproc waybar,19    # Send SIGUSR1 to waybar
EOF
}

#// evaluate options
if [ -z "${*}" ]; then
    echo "No arguments provided"
    show_help
    exit 1
fi

# Define long options
LONGOPTS="cm:,increase:,decrease:,set:,read,toggle,quiet,sigproc:,help"
SHORTOPTS="i:d:s:rtqP:h"

# Parse options
PARSED=$(getopt --options ${SHORTOPTS} --longoptions "${LONGOPTS}" --name "$0" -- "$@")
if [ $? -ne 0 ]; then
    exit 2
fi
eval set -- "${PARSED}"

# Initialize variables
action=""
color_mode="temp" # Default to temperature mode
custom_step=""
newTemp=""
newGamma=""
signal_proc=""

# Parse arguments
while true; do
    case "$1" in
    --cm)
        color_mode="$2"
        if [ "$color_mode" != "temp" ] && [ "$color_mode" != "gamma" ]; then
            echo "Error: Color mode must be 'temp' or 'gamma'"
            exit 1
        fi
        shift 2
        ;;
    -i | --increase)
        action="increase"
        custom_step="$2"
        shift 2
        ;;
    -d | --decrease)
        action="decrease"
        custom_step="$2"
        shift 2
        ;;
    -s | --set)
        action="set"
        custom_step="$2"
        shift 2
        ;;
    -r | --read)
        action="read"
        shift
        ;;
    -t | --toggle)
        action="toggle"
        shift
        ;;
    -q | --quiet)
        notify=false
        shift
        ;;
    -P | --sigproc)
        signal_proc="$2"
        shift 2
        ;;
    -h | --help)
        show_help
        exit 0
        ;;
    --)
        shift
        break
        ;;
    *)
        echo "Invalid option: $1"
        show_help
        exit 1
        ;;
    esac
done

# Validate and set step value
if [ -n "$custom_step" ]; then
    if [ "$action" = "set" ]; then
        # For set actions, custom_step is the target value, not step size
        if [ "$color_mode" = "gamma" ]; then
            if [[ "$custom_step" =~ ^[0-9]+$ ]] && [ "$custom_step" -ge "$min_gamma" ] && [ "$custom_step" -le "$max_gamma" ]; then
                newGamma="$custom_step"
            else
                echo "Error: Gamma value must be an integer between $min_gamma and $max_gamma"
                exit 1
            fi
        else
            if [[ "$custom_step" =~ ^[0-9]+$ ]] && [ "$custom_step" -ge "$min_temp" ] && [ "$custom_step" -le "$max_temp" ]; then
                newTemp="$custom_step"
            else
                echo "Error: Temperature must be an integer between $min_temp and $max_temp"
                exit 1
            fi
        fi
    else
        # For increase/decrease actions, custom_step is the step size
        # If custom_step is empty or not a number, use defaults
        if [ -z "$custom_step" ] || ! [[ "$custom_step" =~ ^[0-9]+$ ]]; then
            # Use default steps
            : # Do nothing, keep default temp_step and gamma_step
        else
            if [ "$color_mode" = "gamma" ]; then
                if [ "$custom_step" -ge 1 ] && [ "$custom_step" -le 50 ]; then
                    gamma_step="$custom_step"
                else
                    echo "Error: Gamma step must be between 1 and 50"
                    exit 1
                fi
            else
                if [ "$custom_step" -ge 1 ] && [ "$custom_step" -le 5000 ]; then
                    temp_step="$custom_step"
                else
                    echo "Error: Temperature step must be between 1 and 5000"
                    exit 1
                fi
            fi
        fi
    fi
fi

# Validate specific temperature value
if [ -n "$newTemp" ]; then
    if [[ "$newTemp" =~ ^[0-9]+$ ]] && [ "$newTemp" -ge "$min_temp" ] && [ "$newTemp" -le "$max_temp" ]; then
        newTemp=$(clamp_temp "$newTemp")
    else
        echo "Error: Temperature must be a number between $min_temp and $max_temp"
        exit 1
    fi
fi

# Validate specific gamma value
if [ -n "$newGamma" ]; then
    if [[ "$newGamma" =~ ^[0-9]+$ ]] && [ "$newGamma" -ge "$min_gamma" ] && [ "$newGamma" -le "$max_gamma" ]; then
        newGamma=$(clamp_gamma "$newGamma")
    else
        echo "Error: Gamma must be an integer between $min_gamma and $max_gamma"
        exit 1
    fi
fi

# Ensure an action was specified
if [ -z "$action" ]; then
    echo "Error: No action specified"
    show_help
    exit 1
fi

# Apply action based on the selected option
case $action in
increase)
    if [ "$color_mode" = "gamma" ]; then
        newGamma=$(clamp_gamma "$((currentGamma + gamma_step))")
        printf "%d|%d|%d\n" "$currentTemp" "$newGamma" "$toggle_mode" >"$sunsetConf"
        currentGamma="$newGamma" # Update current value for status generation
    else
        newTemp=$(clamp_temp "$((currentTemp + temp_step))")
        printf "%d|%d|%d\n" "$newTemp" "$currentGamma" "$toggle_mode" >"$sunsetConf"
        currentTemp="$newTemp" # Update current value for status generation
    fi
    ;;
decrease)
    if [ "$color_mode" = "gamma" ]; then
        newGamma=$(clamp_gamma "$((currentGamma - gamma_step))")
        printf "%d|%d|%d\n" "$currentTemp" "$newGamma" "$toggle_mode" >"$sunsetConf"
        currentGamma="$newGamma" # Update current value for status generation
    else
        newTemp=$(clamp_temp "$((currentTemp - temp_step))")
        printf "%d|%d|%d\n" "$newTemp" "$currentGamma" "$toggle_mode" >"$sunsetConf"
        currentTemp="$newTemp" # Update current value for status generation
    fi
    ;;
set)
    if [ "$color_mode" = "gamma" ]; then
        printf "%d|%d|%d\n" "$currentTemp" "$newGamma" "$toggle_mode" >"$sunsetConf"
        currentGamma="$newGamma" # Update current value for status generation
    else
        printf "%d|%d|%d\n" "$newTemp" "$currentGamma" "$toggle_mode" >"$sunsetConf"
        currentTemp="$newTemp" # Update current value for status generation
    fi
    ;;
read)
    # Query current running temperature from hyprsunset
    # Just read the current state, no need to store unused variable
    ;;
toggle)
    toggle_mode=$((1 - toggle_mode))
    # Only update the toggle state, preserve the saved temp/gamma settings
    printf "%d|%d|%d\n" "$currentTemp" "$currentGamma" "$toggle_mode" >"$sunsetConf"
    ;;
esac

# Send notification if enabled
[ "$notify" = true ] && send_notification

# Send signal to process if specified
send_signal_to_process

# Ensure that hyprsunset process is running (only when we need to apply changes)
    if ! pgrep -x "hyprsunset" >/dev/null; then
        # If socket exists but process is not running, remove the stale socket
        if [ -f "$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.hyprsunset.sock" ]; then
            rm "$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.hyprsunset.sock"
        fi
        hyprctl --quiet dispatch exec -- hyprsunset
    fi

if [ "$action" = "read" ]; then
    if [ "$toggle_mode" -eq 1 ]; then
        current_running_temp=$(hyprctl hyprsunset temperature)
        if [ "$current_running_temp" != "$currentTemp" ]; then
            hyprctl --quiet hyprsunset temperature "$currentTemp"
        fi
    fi
else
    if [ "$toggle_mode" -eq 0 ]; then
        hyprctl --quiet hyprsunset identity
        hyprctl --quiet hyprsunset gamma "${default_gamma}"
    else
        if [ "$color_mode" = "gamma" ] && [ -n "$newGamma" ]; then
            hyprctl --quiet hyprsunset temperature "$currentTemp"
            hyprctl --quiet hyprsunset gamma "$newGamma"
        elif [ -n "$newTemp" ]; then
            hyprctl --quiet hyprsunset temperature "$newTemp"
        else
            hyprctl --quiet hyprsunset temperature "$currentTemp"
            hyprctl --quiet hyprsunset gamma "$currentGamma"
        fi
    fi
fi

# Function to determine color based on temperature
get_temp_color() {
    local temp=$1
    declare -A temp_colors=(
        [10000]="#8b0000" # Dark Red for very high temps (>10000K daylight)
        [8000]="#ff6347"  # Tomato for high daylight (8000-9999K)
        [6500]=""         # No color for standard daylight (6000-7999K)
        [5000]="#ffa500"  # Orange for warm white (5000-5999K)
        [4000]="#ff8c00"  # Dark Orange for very warm (4000-4999K)
        [3000]="#ff471a"  # Orange-Red for candlelight (3000-3999K)
        [2000]="#d22f2f"  # Light Red for very warm (2000-2999K)
        [1000]="#ad1f2f"  # Red for extremely warm (1000-1999K)
    )

    for threshold in $(echo "${!temp_colors[@]}" | tr ' ' '\n' | sort -nr); do
        if ((temp >= threshold)); then
            color=${temp_colors[$threshold]}
            if [[ -n $color ]]; then
                echo "<span color='$color'><b>${temp}K</b></span>"
            else
                echo "<b>${temp}K</b>"
            fi
            return
        fi
    done
}

# Function to determine color based on gamma value
get_gamma_color() {
    local gamma=$1
    declare -A gamma_colors=(
        [90]="#00ff00" # Green for high gamma (bright)
        [70]="#90ee90" # Light Green for medium-high gamma
        [50]=""        # No color for normal gamma range
        [30]="#ffa500" # Orange for low gamma
        [20]="#ff6347" # Red for very low gamma (dim)
    )

    for threshold in $(echo "${!gamma_colors[@]}" | tr ' ' '\n' | sort -nr); do
        if ((gamma >= threshold)); then
            color=${gamma_colors[$threshold]}
            if [[ -n $color ]]; then
                echo "<span color='$color'><b>$gamma</b></span>"
            else
                echo "<b>$gamma</b>"
            fi
            return
        fi
    done
}

# Modular functions for status generation
get_temp_status() {
    local current_running_temp
    current_running_temp=$(get_running_temp)

    if [ "$toggle_mode" -eq 1 ]; then
        if [ "$current_running_temp" = "$default_temp" ]; then
            echo "Identity"
        else
            echo "${current_running_temp}K"
        fi
    else
        echo "Identity"
    fi
}

get_gamma_status() {
    printf "%d" "$currentGamma"
}

get_saved_temp_status() {
    echo "${currentTemp}K"
}

# Generate status message with detailed information
generate_status() {
    local text_output alt_text tooltip_text
    local temp_colored gamma_colored current_running_temp

    # Get current running temperature
    current_running_temp=$(get_running_temp)

    # Determine text output and alt text
    if [ "$toggle_mode" -eq 1 ]; then
        text_output="󰈈" # Filled eye - active
        alt_text="active"
    else
        text_output="" # Unfilled eye - inactive
        alt_text="inactive"
    fi

    # Build color-coded tooltip with Pango markup
    if [ "$toggle_mode" -eq 1 ]; then
        # Get colored values for tooltip
        temp_colored=$(get_temp_color "$current_running_temp")
        gamma_colored=$(get_gamma_color "$currentGamma")

        # Create rich tooltip with icons and colors
        tooltip_text="󰈈 <b>Hyprsunset Active</b>\n"
        tooltip_text+="󰔄 Temperature: $temp_colored\n"
        tooltip_text+="󰍉 Gamma: $gamma_colored\n"
        tooltip_text+="\n<i>󰀨 Click to Disable</i>"

    else
        # Show saved settings in inactive tooltip
        local saved_temp_colored saved_gamma_colored
        saved_temp_colored=$(get_temp_color "$currentTemp")
        saved_gamma_colored=$(get_gamma_color "$currentGamma")

        tooltip_text=" <b> Hyprsunset: Inactive</b>\n"
        tooltip_text+="󰔄 Temperature: $saved_temp_colored\n"
        tooltip_text+="󰍉 Gamma: $saved_gamma_colored\n"
        tooltip_text+="\n<i>󰀨 Click to activate with saved settings</i>"
    fi

    # Output JSON for waybar with text, alt, and tooltip
    cat <<JSON
{"text":"$text_output", "alt":"$alt_text", "tooltip":"$tooltip_text"}
JSON
}

# Generate and print status message
generate_status

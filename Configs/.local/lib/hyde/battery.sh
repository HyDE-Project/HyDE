#!/usr/bin/env bash
# A simple script to display a battery icon

# Function to display usage information
usage() {
    cat <<USAGE
Usage: battery.sh [OPTIONS]

Options:
  icon          Display the battery icon
  percentage    Display the battery percentage
  int           Display the battery percentage as an integer
  status        Display the battery status (Charging, Discharging, etc.)
  status-icon   Display an icon representing the battery status
  -h, --help    Display this help message
USAGE
}

# Check for help option
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

total_capacity=0
battery_count=0

for capacity in /sys/class/power_supply/BAT*/capacity; do
    if [[ -f "$capacity" ]]; then
        total_capacity=$((total_capacity + $(<"$capacity")))
        battery_count=$((battery_count + 1))
    fi
done

# Exit if no battery is found
if ((battery_count == 0)); then
    exit 0
fi

# Determine the icon based on average capacity
average_capacity=$((total_capacity / battery_count))
index=$((average_capacity / 10))

# Define icons for charging, discharging, and status
charging_icons=(" " " " " " " " " " " " " ")
discharging_icons=("󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹")
status_icons=("" "X" "󰂇") # Add appropriate icons for different statuses

battery_status=$(cat /sys/class/power_supply/BAT0/status)

# Parse format options
formats=("$@")

# Function to output the appropriate information based on format option
output_format() {
    case "$1" in
    icon)
        if [[ "$battery_status" == "Charging" ]]; then
            echo -n "${charging_icons[$index]} "
        else
            echo -n "${discharging_icons[$index]} "
        fi
        ;;
    percentage)
        echo -n "$average_capacity% "
        ;;
    int)
        echo -n "$average_capacity "
        ;;
    status)
        echo -n "$battery_status "
        ;;
    status-icon)
        case "$battery_status" in
        "Charging")
            echo -n "${status_icons[0]} "
            ;;
        "Not Charging")
            echo -n "${status_icons[1]} "
            ;;
        *)
            echo -n "${status_icons[2]} "
            ;;
        esac
        ;;
    *)
        echo "Invalid format option: $1. Use 'icon', 'percentage', 'int', 'status', or 'status-icon'."
        exit 1
        ;;
    esac
}

# Output the information based on provided format options
if [ ${#formats[@]} -eq 0 ]; then
    output_format "icon"
else
    for format in "${formats[@]}"; do
        output_format "$format"
    done
    echo
fi

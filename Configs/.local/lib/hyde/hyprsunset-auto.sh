#!/bin/bash

# Auto hyprsunset scheduler
# This script automatically adjusts screen temperature based on time of day

if ! source "$(which hyde-shell)"; then
    echo "[$0] :: Error: hyde-shell not found."
    echo "[$0] :: Is HyDE installed?"
    exit 1
fi

# Configuration
MORNING_TIME="06:00"    # Start returning to daylight
EVENING_TIME="21:00"    # Start warming up
DAY_TEMP=6500          # Daylight temperature
NIGHT_TEMP=4500        # Evening/night temperature
NIGHT_GAMMA=85         # Evening gamma

# Get current time in format HH:MM
current_time=$(date +"%H:%M")

# Convert time to minutes for easier comparison
time_to_minutes() {
    local time=$1

    # Expect HH:MM (or H:MM); validate and extract components
    if [[ ! $time =~ ^([0-9]{1,2}):([0-9]{2})$ ]]; then
        echo "[$0] :: Invalid time format: '$time'" >&2
        return 1
    fi

    local hour=${BASH_REMATCH[1]}
    local min=${BASH_REMATCH[2]}

    # Force base-10 interpretation to avoid octal issues with leading zeros
    echo $((10#$hour * 60 + 10#$min))
}

if ! current_minutes=$(time_to_minutes "$current_time"); then
    echo "[$0] :: Failed to parse current time: '$current_time'" >&2
    exit 1
fi

if ! morning_minutes=$(time_to_minutes "$MORNING_TIME"); then
    echo "[$0] :: Failed to parse MORNING_TIME: '$MORNING_TIME'" >&2
    exit 1
fi

if ! evening_minutes=$(time_to_minutes "$EVENING_TIME"); then
    echo "[$0] :: Failed to parse EVENING_TIME: '$EVENING_TIME'" >&2
    exit 1
fi
# Determine if we should use day or night settings
if [ $current_minutes -ge $morning_minutes ] && [ $current_minutes -lt $evening_minutes ]; then
    # Daytime: use neutral temperature
    target_temp=$DAY_TEMP
    target_gamma=100
    mode="day"
else
    # Evening/Night: use warm temperature
    target_temp=$NIGHT_TEMP
    target_gamma=$NIGHT_GAMMA
    mode="night"
fi

# Apply settings
echo "[$0] :: Setting $mode mode: ${target_temp}K, ${target_gamma}% gamma"

# Use the HyDE hyprsunset script to apply settings
if ! hyde-shell hyprsunset --cm temp -s "$target_temp" --quiet; then
    echo "[$0] :: Failed to apply temperature."
    exit 1
fi

if ! hyde-shell hyprsunset --cm gamma -s "$target_gamma" --quiet; then
    echo "[$0] :: Failed to apply gamma."
    exit 1
fi
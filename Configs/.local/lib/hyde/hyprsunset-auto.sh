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
current_hour=$(date +"%H")
current_min=$(date +"%M")

# Convert time to minutes for easier comparison
time_to_minutes() {
    local time=$1
    local hour=${time%:*}
    local min=${time#*:}
    echo $((hour * 60 + min))
}

current_minutes=$(time_to_minutes "$current_time")
morning_minutes=$(time_to_minutes "$MORNING_TIME")
evening_minutes=$(time_to_minutes "$EVENING_TIME")

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
hyde-shell hyprsunset --cm temp -s $target_temp --quiet
hyde-shell hyprsunset --cm gamma -s $target_gamma --quiet

exit 0
#!/bin/bash

GOVERNOR_PATH="/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
NO_TURBO_PATH="/sys/devices/system/cpu/intel_pstate/no_turbo"

# Ensure paths exist
[ -f "$GOVERNOR_PATH" ] || exit 1
[ -f "$NO_TURBO_PATH" ] || exit 1

SCALING_GOVERNOR=$(cat "$GOVERNOR_PATH")
NO_TURBO=$(cat "$NO_TURBO_PATH")

# Determine current profile
if [[ "$SCALING_GOVERNOR" == "powersave" && "$NO_TURBO" == "1" ]]; then
    CURRENT_PROFILE="powersave"
elif [[ "$SCALING_GOVERNOR" == "powersave" && "$NO_TURBO" == "0" ]]; then
    CURRENT_PROFILE="balanced"
elif [[ "$SCALING_GOVERNOR" == "performance" && "$NO_TURBO" == "0" ]]; then
    CURRENT_PROFILE="performance"
else
    CURRENT_PROFILE="unknown"
fi

# If toggle is requested, switch to the next profile in cycle
if [ "$1" == "toggle" ]; then
    case "$CURRENT_PROFILE" in
        "powersave")
            NEW_PROFILE="balanced"
            sudo tee "$NO_TURBO_PATH" <<< 0
            sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor <<< "powersave"
            ;;
        "balanced")
            NEW_PROFILE="performance"
            sudo tee "$NO_TURBO_PATH" <<< 0
            sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor <<< "performance"
            ;;
        "performance")
            NEW_PROFILE="powersave"
            sudo tee "$NO_TURBO_PATH" <<< 1
            sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor <<< "powersave"
            ;;
    esac
fi

# Output JSON for Waybar
echo "{\"alt\": \"$CURRENT_PROFILE\"}"

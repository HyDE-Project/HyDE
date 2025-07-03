#!/bin/bash

# Toggle DND
dunstctl set-paused toggle

# Check DND status and notify using hyprctl
if dunstctl is-paused | grep -q true; then
    hyprctl notify -1 3000 "rgb(ff1ea3)" "DND Enabled"
else
    hyprctl notify -1 3000 "rgb(1effa3)" "DND Disabled"
fi

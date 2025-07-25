#!/bin/bash

# This script toggles a special workspace and resizes/centers the app only on show.
# Usage: dropdown_workspace.sh <workspace_name> <size_x> <size_y>

WORKSPACE_NAME="$1"
FULL_WORKSPACE_NAME="special:${WORKSPACE_NAME}"
SIZE_X="$2"
SIZE_Y="$3"

# Check if the special workspace is currently visible.
if hyprctl monitors -j | jq -e --arg name "$FULL_WORKSPACE_NAME" '.[] | select(.focused == true and .specialWorkspace.name == $name)' >/dev/null; then
    # The workspace is VISIBLE, so hide it.
    hyprctl dispatch togglespecialworkspace "$WORKSPACE_NAME"
else
    # The workspace is HIDDEN, so toggle it and then resize/center the app.
    hyprctl --batch "dispatch togglespecialworkspace $WORKSPACE_NAME; dispatch resizeactive exact $SIZE_X $SIZE_Y; dispatch centerwindow"
fi

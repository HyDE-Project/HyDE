#!/bin/env bash

# Get the JSON data from hyprctl commands
active_window=$(hyprctl monitors -j)
cursor_pos=$(hyprctl cursorpos -j)

# Merge the JSON data
merged_json=$(jq -s '.[0] * .[1]' <(echo "$active_window") <(echo "$cursor_pos"))

# Print the merged JSON
echo "$merged_json"

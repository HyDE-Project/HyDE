#!/usr/bin/env bash
WinFloat=$(hyprctl -j clients | jq '.[] | select(.focusHistoryID == 0) | .floating')
WinPinned=$(hyprctl -j clients | jq '.[] | select(.focusHistoryID == 0) | .pinned')
if [ "$WinFloat" == "false" ] && [ "$WinPinned" == "false" ]; then
    hyprctl dispatch togglefloating active
fi
hyprctl dispatch pin active
WinFloat=$(hyprctl -j clients | jq '.[] | select(.focusHistoryID == 0) | .floating')
WinPinned=$(hyprctl -j clients | jq '.[] | select(.focusHistoryID == 0) | .pinned')
if [ "$WinFloat" == "true" ] && [ "$WinPinned" == "false" ]; then
    hyprctl dispatch togglefloating active
fi

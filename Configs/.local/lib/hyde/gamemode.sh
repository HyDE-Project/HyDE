#!/usr/bin/env bash
<<<<<<< HEAD
# TODO: Add persistent mode
HYPRGAMEMODE=$(hyprctl getoption animations:enabled | sed -n '1p' | awk '{print $2}')

# Hyprland performance
if [ "$HYPRGAMEMODE" = 1 ]; then
        hyprctl -q --batch "\
        keyword animations:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:xray 1;\
        keyword decoration:blur:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0 ;\
        keyword decoration:active_opacity 1 ;\
        keyword decoration:inactive_opacity 1 ;\
        keyword decoration:fullscreen_opacity 1 ;\
        keyword layerrule noanim,waybar ;\
        keyword layerrule noanim,swaync-notification-window ;\
        keyword layerrule noanim,swww-daemon ;\
        keyword layerrule noanim,rofi
        "
        hyprctl 'keyword windowrule opaque,class:(.*)' # ensure all windows are opaque
        exit
else
        hyprctl reload config-only -q
=======
LOCK_FILE="${XDG_RUNTIME_DIR}/hyde/gamemode.lck"

if [ -f "$LOCK_FILE" ]; then
    # Gamemode is ON → turn it OFF
    hyprctl reload config-only -q
    rm -f "$LOCK_FILE"
else
    # Gamemode is OFF → turn it ON
    mkdir -p "${XDG_RUNTIME_DIR}/hyde"
    hyprctl keyword source "${XDG_CONFIG_HOME}/hypr/workflows/gaming.conf"
    touch "$LOCK_FILE"
>>>>>>> master
fi

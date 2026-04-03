#!/usr/bin/env bash
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
fi

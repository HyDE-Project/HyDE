#!/usr/bin/env bash

[[ "${HYDE_SHELL_INIT}" -ne 1 ]] && eval "$(hyde-shell init)"

sleep 1
killall -e xdg-desktop-portal-hyprland
killall -e xdg-desktop-portal
sleep 1

# Use different directory on NixOS
if [ -d /run/current-system/sw/libexec ]; then
    libDir=/run/current-system/sw/libexec
else
    libDir=/usr/lib
fi

# We will run it safely as a service!
app2unit.sh -t service $libDir/xdg-desktop-portal-hyprland
sleep 1
app2unit.sh -t service $libDir/xdg-desktop-portal &

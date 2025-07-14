#!/usr/bin/env bash
systemctl --user stop xdg-desktop-portal

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

# $libDir/xdg-desktop-portal-hyprland &
# sleep 2
# $libDir/xdg-desktop-portal &

systemctl --user restart xdg-desktop-portal
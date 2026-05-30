#!/usr/bin/env bash
[[ $DOORWAYDE_SHELL_INIT -ne 1 ]] && eval "$(doorwayde-shell init)"
sleep 1

if [ -d /run/current-system ]; then
    # NixOS: portals are systemd user services (set up by programs.hyprland or
    # xdg.portal.enable). Restart them so they inherit the Wayland environment
    # that dbus-update-activation-environment just propagated.
    systemctl --user restart xdg-desktop-portal-hyprland.service 2>/dev/null
    sleep 1
    systemctl --user restart xdg-desktop-portal.service 2>/dev/null
else
    # Non-NixOS: find and re-exec the portal binaries directly.
    killall -e xdg-desktop-portal-hyprland
    killall -e xdg-desktop-portal
    sleep 1
    if [ -d /run/current-system/sw/libexec ]; then
        libDir=/run/current-system/sw/libexec
    else
        libDir=/usr/lib
    fi
    app2unit.sh -t service "$libDir/xdg-desktop-portal-hyprland"
    sleep 1
    app2unit.sh -t service "$libDir/xdg-desktop-portal" &
fi

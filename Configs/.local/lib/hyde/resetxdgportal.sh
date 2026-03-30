#!/usr/bin/env bash
<<<<<<< HEAD

[[ "${HYDE_SHELL_INIT}" -ne 1 ]] && eval "$(hyde-shell init)"

=======
[[ $HYDE_SHELL_INIT -ne 1 ]] && eval "$(hyde-shell init)"
>>>>>>> master
sleep 1
killall -e xdg-desktop-portal-hyprland
killall -e xdg-desktop-portal
sleep 1
<<<<<<< HEAD

# Use different directory on NixOS
=======
>>>>>>> master
if [ -d /run/current-system/sw/libexec ]; then
    libDir=/run/current-system/sw/libexec
else
    libDir=/usr/lib
fi
<<<<<<< HEAD

# We will run it safely as a service!
=======
>>>>>>> master
app2unit.sh -t service $libDir/xdg-desktop-portal-hyprland
sleep 1
app2unit.sh -t service $libDir/xdg-desktop-portal &

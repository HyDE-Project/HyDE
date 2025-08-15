#!/usr/bin/env sh

# # Qt Variables  - https://wiki.hyprland.org/Configuring/Environment-variables/#qt-variables
QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland;xcb}"                               # Qt: Use wayland if available, fall back to x11 if not.
QT_AUTO_SCREEN_SCALE_FACTOR="${QT_AUTO_SCREEN_SCALE_FACTOR:-1}"                 # Enables automatic scaling, based on the monitor’s pixel density
QT_WAYLAND_DISABLE_WINDOWDECORATION="${QT_WAYLAND_DISABLE_WINDOWDECORATION:-1}" # Disables window decorations on Qt applications
QT_QPA_PLATFORMTHEME="${QT_QPA_PLATFORMTHEME:-qt6ct}"                           # Tells Qt based applications to pick your theme from qt5ct, use with Kvantum.

# # HyDE Environment Variables
MOZ_ENABLE_WAYLAND="${MOZ_ENABLE_WAYLAND:-1}"                        # Enable Wayland for Firefox
GDK_SCALE="${GDK_SCALE:-1}"                                          # Set GDK scale to 1, for Xwayland on HiDPI displays
ELECTRON_OZONE_PLATFORM_HINT="${ELECTRON_OZONE_PLATFORM_HINT:-auto}" # Set Electron Ozone Platform Hint to auto, for Electron apps on Wayland

# HyDEs Compositor Configuration
HYPRLAND_CONFIG="${XDG_DATA_HOME:-$HOME/.local/share}/hypr/hyprland.conf"
HYPRLAND_NO_SD_NOTIFY=1 # If systemd, disables the sd_notify calls.
HYPRLAND_NO_SD_VARS=1   # Disables management of variables in systemd and dbus activation environments.

export ELECTRON_OZONE_PLATFORM_HINT GDK_SCALE MOZ_ENABLE_WAYLAND QT_QPA_PLATFORMTHEME \
    QT_WAYLAND_DISABLE_WINDOWDECORATION QT_QPA_PLATFORM QT_AUTO_SCREEN_SCALE_FACTOR \
    HYPRLAND_NO_SD_NOTIFY HYPRLAND_NO_SD_VARS HYPRLAND_CONFIG

# TODO Set this if some toolkit are not working properly. // To set create a 'toolkit.sh' file in the 'env-hyprland.d' folder. and add the following line to it:
#? Toolkit Backend Variables - https://wiki.hyprland.org/Configuring/Environment-variables/#toolkit-backend-variables
# export GDK_BACKEND="${GDK_BACKEND:-wayland,x11,*}"       # GTK: Use wayland if available. If not: try x11, then any other GDK backend.
# export SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-wayland}" # Run SDL2 applications on Wayland. Remove or set to x11 if games that provide older versions of SDL cause compatibility issues
# export CLUTTER_BACKEND="${CLUTTER_BACKEND:-wayland}" # Clutter package already has wayland enabled, this variable will force Clutter applications to try and use the Wayland backend

#!/usr/bin/env bash

# set variables

[[ "${HYDE_SHELL_INIT}" -ne 1 ]] && eval "$(hyde-shell init)"

# sync qt5 and qt6 colors

cp "${XDG_CONFIG_HOME}/qt5ct/colors.conf" "${XDG_CONFIG_HOME}/qt6ct/colors.conf"

# restart dolphin

#a_ws=$(hyprctl -j activeworkspace | jq '.id')
#dpid=$(hyprctl -j clients | jq --arg wid "$a_ws" '.[] | select(.workspace.id == ($wid | tonumber)) | select(.class == "org.kde.dolphin") | .pid')
#if [ ! -z ${dpid} ] ; then
#    hyprctl dispatch closewindow pid:${dpid}
#    hyprctl dispatch exec dolphin &
#fi

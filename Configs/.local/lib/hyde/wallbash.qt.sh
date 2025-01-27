#!/usr/bin/env bash

# set variables

scrDir=$(dirname "$(realpath "$0")")
source $scrDir/globalcontrol.sh

# sync qt5 and qt6 colors

cp "${confDir}/qt5ct/colors.conf" "${confDir}/qt6ct/colors.conf"

# restart dolphin

#a_ws=$(hyprctl -j activeworkspace | jq '.id')
#dpid=$(hyprctl -j clients | jq --arg wid "$a_ws" '.[] | select(.workspace.id == ($wid | tonumber)) | select(.class == "org.kde.dolphin") | .pid')
#if [ ! -z ${dpid} ] ; then
#    hyprctl dispatch closewindow pid:${dpid}
#    hyprctl dispatch exec dolphin &
#fi

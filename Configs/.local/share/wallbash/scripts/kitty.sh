#!/bin/bash

# source variables
confDir="${confDir:-$HOME/.config}"
kittyConf="${confDir}/kitty/kitty.conf"
hallwaydeKitty="${HALLWAYDE_DATA_HOME}/kitty.conf"

INC_LINE="include hallwayde.conf"

sed -i "/include .*share\/hallwayde\/kitty.conf.*/d" "$kittyConf"
# Ensure the line is at the top and remove duplicates
if ! grep -Fxq "$INC_LINE" "$kittyConf"; then
    sed -i "1i $INC_LINE" "$kittyConf"
fi

# Refresh kitty terminal
killall -SIGUSR1 kitty

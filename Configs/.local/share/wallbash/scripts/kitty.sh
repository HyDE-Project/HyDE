#!/bin/bash

# source variables
confDir="${confDir:-$HOME/.config}"
kittyConf="${confDir}/kitty/kitty.conf"
hydeKitty="${HYDE_DATA_HOME}/kitty.conf"

INC_LINE="include hyde.conf"

sed -i "/include .*share\/hyde\/kitty.conf.*/d" "$kittyConf"
# Ensure the line is at the top and remove duplicates
if ! grep -Fxq "$INC_LINE" "$kittyConf"; then
    sed -i "1i $INC_LINE" "$kittyConf"
fi

# Refresh kitty terminal
killall -SIGUSR1 kitty

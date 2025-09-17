#!/usr/bin/env bash

confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
btopConf="${confDir}/btop/btop.conf"

sed -i 's/color_theme = ".*"/color_theme = "hyde"/' "$btopConf"

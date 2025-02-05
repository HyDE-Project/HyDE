#!/bin/sh

mkdir -p ~/AGS
cd ~/AGS
git clone https://github.com/niumination/agsv1-hyprpanel.git
cd agsv1-hyprpanel
./make_agsv1.sh
agsv1 --init -c ~/.config/agsv1/config.js
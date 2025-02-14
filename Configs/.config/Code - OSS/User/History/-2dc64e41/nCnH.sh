#!/bin/bash
cd ~
git clone https://gitlab.freedesktop.org/hadess/iio-sensor-proxy/
cd iio-sensor-proxy
meson _build -Dprefix=/usr
ninja -v -C _build install

yay -S iio-hyprland
add to userprefs 
==> exec-once = iio-hyprland
monitor=eDP-1,preferred,auto,1,transform,0
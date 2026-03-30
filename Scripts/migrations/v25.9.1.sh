#!/usr/bin/env sh

<<<<<<< HEAD
echo "Replacing rofi-wayland with rofi"

sudo pacman -Sy
sudo pacman -Rns --noconfirm rofi-wayland
sudo pacman -S --noconfirm rofi
=======
echo "Please be sure to update rofi"
echo "Arch repo now support rofi-wayland inside rofi package"
echo "If you are using arch linux or an arch based distro please remove rofi-wayland and install rofi"
echo "sudo pacman -Syu should also do the trick"

>>>>>>> master

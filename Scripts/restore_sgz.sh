#!/bin/bash
#|---/ /+----------------------------+---/ /|#
#|--/ /-| Script to configure system |--/ /-|#
#|-/ /--| Prasanth Rangan            |-/ /--|#
#|/ /---+----------------------------+/ /---|#

source global_fn.sh

# sddm
if [ ! -d /etc/sddm.conf.d ]
    then
    sudo mkdir /etc/sddm.conf.d
fi

if [ `grep "Current=corners" /etc/sddm.conf.d/kde_settings.conf | wc -w` -eq 0 ]
    then
    sudo mv /usr/share/sddm/themes/corners/kde_settings.conf /etc/sddm.conf.d/
fi

# grub
if [ ! -f /etc/default/grub.t2.bkp ]
    then
    sudo cp /etc/default/grub /etc/default/grub.t2.bkp

    sudo sed -i "/^GRUB_DEFAULT=/c\GRUB_DEFAULT=saved
    /^GRUB_CMDLINE_LINUX_DEFAULT=/c\GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 quiet splash nvidia_drm.modeset=1\"
    /^GRUB_GFXMODE=/c\GRUB_GFXMODE=1280x1024x32,auto
    /^#GRUB_THEME=/c\GRUB_THEME=\"/usr/share/grub/themes/pochita/theme.txt\"
    /^#GRUB_SAVEDEFAULT=true/c\GRUB_SAVEDEFAULT=true" /etc/default/grub

    sudo cp /boot/grub/grub.cfg /boot/grub/grub.t2.bkp
    sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

# zsh
if [ "$SHELL" != "/usr/bin/zsh" ]
    then
    chsh -s $(which zsh)
fi

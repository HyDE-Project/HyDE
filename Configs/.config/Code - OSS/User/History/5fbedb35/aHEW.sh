#!/usr/bin/env bash
#|---/ /+-----------------------------+---/ /|#
#|--/ /-| Script to configure my apps |--/ /-|#
#|-/ /--| Prasanth Rangan             |-/ /--|#
#|/ /---+-----------------------------+/ /---|#

scrDir=$(dirname "$(dirname "$(realpath "$0")")")
source "${scrDir}/global_fn.sh"
if [ $? -ne 0 ]; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

cloneDir=$(dirname "$(realpath "$cloneDir")")


#// icons

if [ -f /usr/share/applications/rofi-theme-selector.desktop ] && [ -f /usr/share/applications/rofi.desktop ]; then
    sudo rm /usr/share/applications/rofi-theme-selector.desktop
    sudo rm /usr/share/applications/rofi.desktop
fi
sudo sed -i "/^Icon=/c\Icon=adjust-colors" /usr/share/applications/nwg-look.desktop
sudo sed -i "/^Icon=/c\Icon=spectacle" /usr/share/applications/swappy.desktop


#// firefox

#if pkg_installed firefox; then
#    FoxRel=$(find ~/.mozilla/firefox -maxdepth 1 -type d -name "*.default-release" | head -1)

#    if [ -z "${FoxRel}" ]; then
#        firefox &> /dev/null &
#        sleep 1
#        FoxRel=$(find ~/.mozilla/firefox -maxdepth 1 -type d -name "*.default-release" | head -1)
#    else
#        BkpDir="${HOME}/.config/cfg_backups/$(date +'%y%m%d_%Hh%Mm%Ss')_apps"
#        mkdir -p "${BkpDir}"
#        cp -r ~/.mozilla/firefox "${BkpDir}"
#    fi

#    tar -xzf ${cloneDir}/Source/arcs/Firefox_UserConfig.tar.gz -C "${FoxRel}"
#    tar -xzf ${cloneDir}/Source/arcs/Firefox_Extensions.tar.gz -C ~/.mozilla/

#    find ~/.mozilla/extensions -maxdepth 1 -type f -name "*.xpi" | while read fext
#    do
#        firefox -profile "${FoxRel}" "${fext}" &> /dev/null &
#    done
#fi


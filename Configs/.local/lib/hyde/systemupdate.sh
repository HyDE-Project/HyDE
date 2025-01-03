#!/usr/bin/env bash

# Check release
if [ ! -f /etc/arch-release ] ; then
    exit 0
fi

# source variables
scrDir=$(dirname "$(realpath "$0")")
source "$scrDir/globalcontrol.sh"
get_aurhlpr
export -f pkg_installed
fpk_exup="pkg_installed flatpak && flatpak update"

# Trigger upgrade
if [ "$1" == "up" ] ; then
    # trap 'pkill -RTMIN+20 waybar' EXIT
    command="
    fastfetch
    $0 upgrade &
    ${aurhlpr} -Syu
    $fpk_exup
    read -n 1 -p 'Press any key to continue...'
    "
    kitty --title systemupdate sh -c "${command}"
    exit 0
fi

# Check for AUR updates
aur=$(${aurhlpr} -Qua | wc -l) 
ofc=$(pacman -Qu | wc -l)

# Check for flatpak updates
if pkg_installed flatpak ; then
    fpk=$(flatpak remote-ls --updates | wc -l)
    fpk_disp="\n󰏓 Flatpak $fpk"
else
    fpk=0
    fpk_disp=""
fi

# Calculate total available updates
upd=$(( ofc + aur + fpk ))
[ "${1}" == upgrade ] && printf "\n[Official] %-10s\n[AUR]      %-10s\n[Flatpak]  %-10s\nEnter your password:" "$ofc" "$aur" "$fpk" && exit

# Show tooltip
if [ $upd -eq 0 ] ; then
    upd="" #Remove Icon completely
    # upd="󰮯"   #If zero Display Icon only
    echo "{\"text\":\"$upd\", \"tooltip\":\" Packages are up to date\"}"
else
    echo "{\"text\":\"󰮯 $upd\", \"tooltip\":\"󱓽 Official $ofc\n󱓾 AUR $aur$fpk_disp\"}"
fi

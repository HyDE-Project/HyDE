#!/usr/bin/env bash

#! REQUIRED ROOT
execName="$0 $*"
rootOpts=("--install" "--purge" "--revert" "fresh") #? List Of Flags that needs to be in sudo
vertL="$(printf '=%.0s' $(seq 1 "$(tput cols)"))"

box_me() {
    local s="Hyde: $*"
    tput setaf 3
    echo " ═${s//?/═}"
    echo "║$s ║"
    echo " ═${s//?/═}"
    tput sgr0
}

check_Root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Error: [ $execName ] must be run as root!"
        exit 1
    fi
}

check_Ping() {
    if ! ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
        box_me "Error: No internet connection."
        exit 1
    fi
}
write_ChaoticAUR() {
    is_ChaoticAUR=$(
        grep "chaotic-aur" /etc/pacman.conf >/dev/null 2>&1
        echo $?
    )

    if [ "$1" == "append" ]; then
        box_me "Appending Chaotic AUR"
        if [ "$is_ChaoticAUR" -eq 0 ]; then
            echo "Chaotic-AUR already in pacman.conf..."
        else
            echo "Appending Chaotic-AUR in pacman.conf..."
            echo -e "\r\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist" >>/etc/pacman.conf
        fi
    elif [ "$1" == "remove" ]; then
        box_me "Removing Chaotic AUR from pacman.conf"
        if grep -q 'chaotic-aur' /etc/pacman.conf; then
            box_me "Removing Chaotic AUR"
            echo "Removing Chaotic-AUR from pacman.conf..."
            sed -i '/chaotic-aur/d' /etc/pacman.conf
            sed -i '/chaotic-mirrorlist/d' /etc/pacman.conf
        else
            echo "Chaotic-AUR is not present in pacman.conf..."
        fi
    fi
}

check_Integrity() {
    is_ChaoticAUR=$(
        grep "chaotic-aur" /etc/pacman.conf >/dev/null 2>&1
        echo $?
    )

    if [ "$is_ChaoticAUR" -ne 0 ]; then
        echo "Chaotic AUR entry not found in pacman.conf"
        return 1
    fi

    if ! pacman-key -l | grep 3056513887B78AEB >/dev/null; then
        echo "Chaotic AUR key not found"
        return 1
    fi

    if ! pacman -Qq chaotic-keyring 2>/dev/null; then
        echo "Chaotic AUR keyring not found"
        return 1
    fi

    if ! pacman -Qq chaotic-mirrorlist 2>/dev/null; then
        echo "Chaotic AUR mirrorlist not found"
        return 1
    fi

    return 0
}

install() {
    handle_error() {
        tput setaf 1
        echo "ERROR :: Failed to install Chaotic AUR"
        tput sgr0
        echo "WARNING :: Reverting changes..."
        { purge && echo "Reverted successfully"; } || echo "Failed to revert"
        exit 1
    }

    box_me "Installing the key"
    pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com || {
        box_me "Failed to install the key"
        handle_error
    }
    pacman-key --lsign-key 3056513887B78AEB || {
        box_me "Failed to locally sign the key"
        handle_error
    }

    box_me "Downloading the keyring"
    pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' || {
        box_me "Failed to download the keyring"
        handle_error
    }

    box_me "Downloading the mirrorlist"
    pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' || {
        box_me "Failed to download the mirrorlist"
        handle_error
    }

    write_ChaoticAUR "append" || {
        box_me "Failed to append Chaotic AUR"
        handle_error
    }

    box_me "Refreshing the mirrorlists"
    pacman -Sy || {
        box_me "Failed to refresh the mirrorlists"
        handle_error
    }

    box_me "Chaotic-AUR has been successfully installed!"
}

purge() {
    if pacman-key -l | grep 3056513887B78AEB >/dev/null; then
        box_me "Deleting the key"
        pacman-key --delete EF925EA60F33D0CB85C44AD13056513887B78AEB
    fi

    if pacman -Qq chaotic-keyring 2>/dev/null; then
        box_me "Uninstalling the keyring"
        pacman -Rns --noconfirm chaotic-keyring
    fi

    if pacman -Qq chaotic-mirrorlist 2>/dev/null; then
        box_me "Uninstalling the mirrorlist"
        pacman -Rns --noconfirm chaotic-mirrorlist
    fi

    write_ChaoticAUR "remove"

    box_me "Refreshing the mirrorlists"
    pacman -Sy

    box_me "Chaotic-AUR has been successfully purged"
}

revertAUR() {
    to_be_Reverted_AUR="$(pacman -Qmq | grep chaotic-aur)"

    box_me "Revert Chaotic AUR to AUR Packages"

    if [[ -z "${to_be_Reverted_AUR// /}" ]]; then
        echo "No chaotic-aur package detected"
        echo "You are Good to go!"
        exit 0
    fi

    echo -e "Do you wish to reinstall your old Chaotic-AUR packages from AUR?\nThe following packages will be affected:\n$to_be_Reverted_AUR"
    echo -n "Proceed? [Y/n] "
    read ans

    if [ "$ans" == "n" ] || [ "$ans" == "N" ]; then
        box_me "Aborting..."
        exit 0
    fi

    for chaoticPackage in $to_be_Reverted_AUR; do
        convertedPackage="$(echo "$chaoticPackage" | sed 's/chaotic-aur/aur/')"

        if [ "$(pacman -Qs "$convertedPackage")" == "$convertedPackage" ]; then
            box_me "Reinstalling $convertedPackage..."
            pacman -S --noconfirm "$convertedPackage"
        else
            box_me "Could not find $convertedPackage in the AUR."
        fi
    done

    box_me "Your Chaotic-AUR packages have been reinstalled!"
    exit 0
}

fresh() {
    clear
    echo "Detected: Arch Linux"
    cat <<CHAOS

$(tput setaf 2)Would you like to add Chaotic AUR to your mirror list?$(tput sgr0)
Chaotic AUR provides prebuilt and precompiled packages,
which can make installing packages from Arch faster.

$vertL
$(tput setaf 6)About Chaotic AUR:$(tput sgr0)
Most packages available in this repo are automatically built from their respective AUR source package. However there are a few exceptions, check github.com/chaotic-aur/packages to find out which ones.
The primary building cluster is a node in UFSCars datacenter which is hosted in São Carlos, São Paulo, Brazil.

Feel free to create issues to suggest enhancements, flag database corruptions and all other requests: Issues
Please report build bugs to the AUR package maintainers.

Disclaimer:
This repo is generated on-demand from packages we use on our personal computers. If there are any package license infringements please notify us through email. The package will then be removed and blacklisted.

For more information, visit: https://aur.chaotic.cx/
$vertL

HyDE is not affiliated with Chaotic AUR.

CHAOS

    read -p "Type 'yes' to continue [default] No : " add_chaotic
    if [ ! "${add_chaotic}" == "yes" ]; then
        echo -e "$(tput setaf 1) Skipping Chaotic AUR$(tput sgr0)"
        exit 0
    fi
}

if ! command -v pacman >/dev/null 2>&1; then
    box_me "Error: pacman not detected"
    exit 1
fi

for option in "${rootOpts[@]}"; do
    if [ "$1" == "$option" ]; then
        check_Ping
        check_Root
        break
    fi
done

case "$1" in
--install)
    if [ "$2" == "fresh" ]; then fresh; fi
    if check_Integrity >/dev/null; then
        echo "Chaotic AUR already installed. Would you like a reinstall? [y/N]"
        read ans
        if [ "$ans" != "Y" ] && [ "$ans" != "y" ]; then
            echo "Chaotic AUR: Operation Cancelled."
            exit 0
        fi
    fi
    install
    ;;
--uninstall)
    purge
    revertAUR
    ;;
--revert)
    revertAUR
    ;;
*)
    cat <<HELP
Invalid option: $1
Usage: $0 [option]
    --install [fresh]  ﯦ  Install chaotic AUR ('fresh' assumes a fresh install)
    --uninstall        ﯦ  Uninstall chaotic AUR ( requires you to run $0 --revert after)
    --revert           ﯦ  Reinstall orphaned chaotic AUR packages
HELP
    ;;
esac

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
write_AthenaOS() {
    is_AthenaOS=$(
        grep "athena" /etc/pacman.conf >/dev/null 2>&1
        echo $?
    )

    if [ "$1" == "append" ]; then
        box_me "Appending Athena Repo"
        if [ "$is_AthenaOS" -eq 0 ]; then
            echo "Athena already in pacman.conf..."
        else
            echo "Appending Athena in pacman.conf..."
            echo -e "\r\n[athena]\nSigLevel = Optional TrustedOnly\nInclude = /etc/pacman.d/athena-mirrorlist" >>/etc/pacman.conf
        fi
    elif [ "$1" == "remove" ]; then
        box_me "Removing Athena from pacman.conf"
        if grep -q '\[athena\]' /etc/pacman.conf; then
            box_me "Removing Athena"
            echo "Removing Athena from pacman.conf..."
            # Remove the entire [athena] section including its SigLevel and Include lines
            sed -i '/\[athena\]/,/Include = \/etc\/pacman\.d\/athena-mirrorlist/d' /etc/pacman.conf
            # Remove any trailing empty lines that might be left
            sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' /etc/pacman.conf
        else
            echo "Athena is not present in pacman.conf..."
        fi
    fi
}

check_Integrity() {
    is_AthenaOS=$(
        grep "athena" /etc/pacman.conf >/dev/null 2>&1
        echo $?
    )

    if [ "$is_AthenaOS" -ne 0 ]; then
        echo "Athena entry not found in pacman.conf"
        return 1
    fi

    if ! pacman-key -l | grep A3F78B994C2171D5 >/dev/null; then
        echo "Athena key not found"
        return 1
    fi

    if [[ ! -e /etc/pacman.d/athena-mirrorlist ]]; then
        echo "Athena mirrorlist not found"
        return 1
    fi

    return 0
}

install() {
    handle_error() {
        tput setaf 1
        echo "ERROR :: Failed to install Athena"
        tput sgr0
        echo "WARNING :: Reverting changes..."
        { purge && echo "Reverted successfully"; } || echo "Failed to revert"
        exit 1
    }

    box_me "Installing the key"
    pacman-key --recv-key A3F78B994C2171D5 --keyserver keyserver.ubuntu.com || {
        box_me "Failed to install the key"
        handle_error
    }
    pacman-key --lsign-key A3F78B994C2171D5 || {
        box_me "Failed to locally sign the key"
        handle_error
    }

    box_me "Downloading the mirrorlist"
    curl https://raw.githubusercontent.com/Athena-OS/athena/main/packages/os-specific/system/athena-mirrorlist/athena-mirrorlist -o /etc/pacman.d/athena-mirrorlist || {
        box_me "Failed to download the mirrorlist"
        handle_error
    }

    write_AthenaOS "append" || {
        box_me "Failed to append Athena Repo"
        handle_error
    }

    box_me "Refreshing the mirrorlists"
    pacman -Sy || {
        box_me "Failed to refresh the mirrorlists"
        handle_error
    }

    box_me "Athena has been successfully installed!"
}

purge() {
    if pacman-key -l | grep A3F78B994C2171D5 >/dev/null; then
        box_me "Deleting the key"
        pacman-key --delete A3F78B994C2171D5 || {
            box_me "Failed to delete key"
            return 1
        }
    fi

    if [[ -e /etc/pacman.d/athena-mirrorlist ]]; then
        box_me "Removing the mirrorlist"
        rm -rf /etc/pacman.d/athena-mirrorlist || {
            box_me "Failed to remove mirrorlist"
            return 1
        }
    fi

    write_AthenaOS "remove"

    box_me "Refreshing the mirrorlists"
    pacman -Sy || {
        box_me "Failed to refresh mirrorlists"
        return 1
    }

    box_me "Athena has been successfully purged"
}

fresh() {
    clear
    echo "Detected: Arch Linux"
    cat <<CHAOS

$(tput setaf 2)Would you like to add Athena Repo to your mirror list?$(tput sgr0)

$vertL
$(tput setaf 6)About Athena Repo:$(tput sgr0)
Athena repository provides tools or pentesting packages. 
It started as a clone of BlackArch repository
$vertL

I just need this Repository for easy access to tools/packages for pentesting.

CHAOS

    read -p "Type 'yes' to continue [default] No : " add_athena
    if [ ! "${add_athena}" == "yes" ]; then
        echo -e "$(tput setaf 1) Skipping Athena Repo$(tput sgr0)"
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
        echo "Athena already installed. Would you like a reinstall? [y/N]"
        read ans
        if [ "$ans" != "Y" ] && [ "$ans" != "y" ]; then
            echo "Athena: Operation Cancelled."
            exit 0
        fi
    fi
    install
    ;;
--uninstall)
    purge
    ;;
*)
    cat <<HELP
Invalid option: $1
Usage: $0 [option]
    --install [fresh]  ﯦ  Install Athena repository ('fresh' assumes a fresh install)
    --uninstall        ﯦ  Uninstall Athena repository
HELP
    ;;
esac
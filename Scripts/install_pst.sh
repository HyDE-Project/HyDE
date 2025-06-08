#!/usr/bin/env bash
#|---/ /+--------------------------------------+---/ /|#
#|--/ /-| Script to apply post install configs |--/ /-|#
#|-/ /--| Prasanth Rangan                      |-/ /--|#
#|/ /---+--------------------------------------+/ /---|#

scrDir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

cloneDir="${cloneDir:-$CLONE_DIR}"
flg_DryRun=${flg_DryRun:-0}

# sddm
if pkg_installed sddm; then
    print_log -c "[DISPLAYMANAGER] " -b "detected :: " "sddm"
    if [ ! -d /etc/sddm.conf.d ]; then
        [ ${flg_DryRun} -eq 1 ] || sudo mkdir -p /etc/sddm.conf.d
    fi
    if [ ! -f /etc/sddm.conf.d/backup_the_hyde_project.conf ] || [ "${HYDE_INSTALL_SDDM}" = true ]; then
        print_log -g "[DISPLAYMANAGER] " -b " :: " "configuring sddm..."
        print_log -g "[DISPLAYMANAGER] " -b " :: " "Select sddm theme:" -r "\n[1]" -b " Candy" -r "\n[2]" -b " Corners"
        read -p " :: Enter option number : " -r sddmopt

        case $sddmopt in
        1) sddmtheme="Candy" ;;
        *) sddmtheme="Corners" ;;
        esac

        if [[ ${flg_DryRun} -ne 1 ]]; then
            sudo tar -xzf "${cloneDir}/Source/arcs/Sddm_${sddmtheme}.tar.gz" -C /usr/share/sddm/themes/
            sudo touch /etc/sddm.conf.d/the_hyde_project.conf
            sudo cp /etc/sddm.conf.d/the_hyde_project.conf /etc/sddm.conf.d/backup_the_hyde_project.conf
            sudo cp /usr/share/sddm/themes/${sddmtheme}/the_hyde_project.conf /etc/sddm.conf.d/
        fi

        print_log -g "[DISPLAYMANAGER] " -b " :: " "sddm configured with ${sddmtheme} theme..."
    else
        print_log -y "[DISPLAYMANAGER] " -b " :: " "sddm is already configured..."
    fi

    if [ ! -f "/usr/share/sddm/faces/${USER}.face.icon" ] && [ -f "${cloneDir}/Source/misc/${USER}.face.icon" ]; then
        sudo cp "${cloneDir}/Source/misc/${USER}.face.icon" /usr/share/sddm/faces/
        print_log -g "[DISPLAYMANAGER] " -b " :: " "avatar set for ${USER}..."
    fi

else
    print_log -y "[DISPLAYMANAGER] " -b " :: " "sddm is not installed..."
fi

# dolphin
if pkg_installed dolphin && pkg_installed xdg-utils; then
    print_log -c "[FILEMANAGER] " -b "detected :: " "dolphin"
    xdg-mime default org.kde.dolphin.desktop inode/directory
    print_log -g "[FILEMANAGER] " -b " :: " "setting $(xdg-mime query default "inode/directory") as default file explorer..."

else
    print_log -y "[FILEMANAGER]" -b " :: " "dolphin is not installed..."
    print_log -y "[FILEMANAGER]" -b " :: " "Setting $(xdg-mime query default "inode/directory") as default file explorer..."
fi

# shell
"${scrDir}/restore_shl.sh"

# flatpak
if ! pkg_installed flatpak; then
    echo ""
    print_log -g "[FLATPAK]" -b " list :: " "flatpak application"
    awk -F '#' '$1 != "" {print "["++count"]", $1}' "${scrDir}/extra/custom_flat.lst"
    prompt_timer 60 "Install these flatpaks? [Y/n]"
    fpkopt=${PROMPT_INPUT,,}

    if [ "${fpkopt}" = "y" ]; then
        print_log -g "[FLATPAK]" -b " install :: " "flatpaks"
        [ ${flg_DryRun} -eq 1 ] || "${scrDir}/extra/install_fpk.sh"
    else
        print_log -y "[FLATPAK]" -b " skip :: " "flatpak installation"
    fi

else
    print_log -y "[FLATPAK]" -b " :: " "flatpak is already installed"
fi

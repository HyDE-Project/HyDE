#!/usr/bin/env bash
# shellcheck disable=SC2154
#|---/ /+--------------------------+---/ /|#
#|--/ /-| Main installation script |--/ /-|#
#|-/ /--| Prasanth Rangan          |-/ /--|#
#|/ /---+--------------------------+/ /---|#

cat <<"EOF"

-------------------------------------------------
        .
       / \         _       _  _      ___  ___
      /^  \      _| |_    | || |_  _|   \| __|
     /  _  \    |_   _|   | __ | || | |) | _|
    /  | | ~\     |_|     |_||_|\_, |___/|___|
   /.-'   '-.\                  |__/

-------------------------------------------------

EOF

#--------------------------------#
# import variables and functions #
#--------------------------------#
scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

#------------------#
# evaluate options #
#------------------#
flg_Install=0
flg_Restore=0
flg_Service=0
flg_DryRun=0
flg_Shell=0
flg_Nvidia=1
flg_ThemeInstall=1

while getopts idrstmnh: RunStep; do
    case $RunStep in
    i) flg_Install=1 ;;
    d)
        flg_Install=1
        export use_default="--noconfirm"
        ;;
    r) flg_Restore=1 ;;
    s) flg_Service=1 ;;
    n)
        # shellcheck disable=SC2034
        export flg_Nvidia=0
        print_log -r "[nvidia] " -b "Ignored :: " "skipping Nvidia actions"
        ;;
    h)
        # shellcheck disable=SC2034
        export flg_Shell=0
        print_log -r "[shell] " -b "Reevaluate :: " "shell options"
        ;;
    t) flg_DryRun=1 ;;
    m) flg_ThemeInstall=0 ;;
    *)
        cat <<EOF
Usage: $0 [options]
            i : [i]nstall hyprland without configs
            d : install hyprland [d]efaults without configs --noconfirm
            r : [r]estore config files
            s : enable system [s]ervices
            n : ignore/[n]o [n]vidia actions
            h : re-evaluate S[h]ell
            m : no the[m]e reinstallations
            t : [t]est run without executing (-irst to dry run all)
EOF
        exit 1
        ;;
    esac
done

# Only export that are used outside this script
HYDE_LOG="$(date +'%y%m%d_%Hh%Mm%Ss')"
export flg_DryRun flg_Nvidia flg_Shell flg_Install flg_ThemeInstall HYDE_LOG

if [ "${flg_DryRun}" -eq 1 ]; then
    print_log -n "[test-run] " -b "enabled :: " "Testing without executing"
elif [ $OPTIND -eq 1 ]; then
    flg_Install=1
    flg_Restore=1
    flg_Service=1
fi

#--------------------#
# pre-install script #
#--------------------#
if [ ${flg_Install} -eq 1 ] && [ ${flg_Restore} -eq 1 ]; then
    cat <<"EOF"
                _         _       _ _
 ___ ___ ___   |_|___ ___| |_ ___| | |
| . |  _| -_|  | |   |_ -|  _| .'| | |
|  _|_| |___|  |_|_|_|___|_| |__,|_|_|
|_|

EOF

    "${scrDir}/install_pre.sh"
fi

#------------#
# installing #
#------------#
if [ ${flg_Install} -eq 1 ]; then
    cat <<"EOF"

 _         _       _ _ _
|_|___ ___| |_ ___| | |_|___ ___
| |   |_ -|  _| .'| | | |   | . |
|_|_|_|___|_| |__,|_|_|_|_|_|_  |
                            |___|

EOF

    #----------------------#
    # prepare package list #
    #----------------------#
    shift $((OPTIND - 1))
    custom_pkg=$1
    cp "${scrDir}/pkg_core.lst" "${scrDir}/install_pkg.lst"
    trap 'rm "${scrDir}/install_pkg.lst"' EXIT

    if [ -f "${custom_pkg}" ] && [ -n "${custom_pkg}" ]; then
        cat "${custom_pkg}" >>"${scrDir}/install_pkg.lst"
    fi
    #--------------------------------#
    # add nvidia drivers to the list #
    #--------------------------------#
    if nvidia_detect; then
        if [ ${flg_Nvidia} -eq 1 ]; then
            cat /usr/lib/modules/*/pkgbase | while read -r kernel; do
                echo "${kernel}-headers" >>"${scrDir}/install_pkg.lst"
            done
            nvidia_detect --drivers >>"${scrDir}/install_pkg.lst"
        else
            print_log -warn "Nvidia" " :: " "Nvidia GPU detected but ignored..."
        fi
    fi
    nvidia_detect --verbose

    #----------------#
    # get user prefs #
    #----------------#
    echo ""
    if ! chk_list "aurhlpr" "${aurList[@]}"; then
        print_log -c "\nAUR Helpers :: "
        for i in "${!aurList[@]}"; do
            print_log -sec "$((i + 1))" " ${aurList[$i]} "
        done

        prompt_timer 120 "Enter option number [default: yay-bin] | q to quit "

        case "${PROMPT_INPUT}" in
        1) export getAur="yay" ;;
        2) export getAur="yay-bin" ;;
        3) export getAur="paru" ;;
        4) export getAur="paru-bin" ;;
        q)
            print_log -sec "AUR" -crit "Quit" "Exiting..."
            exit 1
            ;;
        *)
            print_log -sec "AUR" -warn "Defaulting to yay-bin"
            print_log -sec "AUR" -stat "default" "yay-bin"
            export getAur="yay-bin"
            ;;
        esac
    fi
    if [[ -z "$aurhlpr" ]]; then
        print_log -sec "AUR" -crit "No AUR helper found..." "Log file at ${cacheDir}/logs/${HYDE_LOG}"
        exit 1
    fi

    if ! chk_list "myShell" "${shlList[@]}"; then
        print_log -c "Shell :: "
        for i in "${!shlList[@]}"; do
            print_log -sec "$((i + 1))" " ${shlList[$i]} "
        done
        prompt_timer 120 "Enter option number [default: zsh] | q to quit "

        case "${PROMPT_INPUT}" in
        1) export myShell="zsh" ;;
        2) export myShell="fish" ;;
        q)
            print_log -sec "shell" -crit "Quit" "Exiting..."
            exit 1
            ;;
        *)
            print_log -sec "hell" -warn "Defaulting to zsh"
            export myShell="zsh"
            ;;
        esac
        echo "${myShell}" >>"${scrDir}/install_pkg.lst"
    fi

    if [[ -z "$myShell" ]]; then
        print_log -sec "shell" -crit "No shell found..." "Log file at ${cacheDir}/logs/${HYDE_LOG}"
        exit 1
    else
        print_log -sec "shell" -stat "detected :: " "${myShell}"
    fi

    #--------------------------------#
    # install packages from the list #
    #--------------------------------#
    [ ${flg_DryRun} -eq 1 ] || "${scrDir}/install_pkg.sh" "${scrDir}/install_pkg.lst"
fi

#---------------------------#
# restore my custom configs #
#---------------------------#
if [ ${flg_Restore} -eq 1 ]; then
    cat <<"EOF"

             _           _
 ___ ___ ___| |_ ___ ___|_|___ ___
|  _| -_|_ -|  _| . |  _| |   | . |
|_| |___|___|_| |___|_| |_|_|_|_  |
                              |___|

EOF

    if [ "${flg_DryRun}" -ne 1 ] && [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
        hyprctl keyword misc:disable_autoreload 1 -q
    fi

    "${scrDir}/restore_fnt.sh"
    "${scrDir}/restore_cfg.sh"
    "${scrDir}/restore_thm.sh"

    if [ "${flg_DryRun}" -ne 1 ]; then
        "$HOME/.local/lib/hyde/swwwallcache.sh" -t ""
        "$HOME/.local/lib/hyde/themeswitch.sh" -q || true
        echo "[install] reload :: Hyprland"
    fi

fi

#---------------------#
# post-install script #
#---------------------#
if [ ${flg_Install} -eq 1 ] && [ ${flg_Restore} -eq 1 ]; then
    cat <<"EOF"

             _      _         _       _ _
 ___ ___ ___| |_   |_|___ ___| |_ ___| | |
| . | . |_ -|  _|  | |   |_ -|  _| .'| | |
|  _|___|___|_|    |_|_|_|___|_| |__,|_|_|
|_|

EOF

    "${scrDir}/install_pst.sh"
fi

#------------------------#
# enable system services #
#------------------------#
if [ ${flg_Service} -eq 1 ]; then
    cat <<"EOF"

                 _
 ___ ___ ___ _ _|_|___ ___ ___
|_ -| -_|  _| | | |  _| -_|_ -|
|___|___|_|  \_/|_|___|___|___|

EOF

    while read -r serviceChk; do

        if [[ $(systemctl list-units --all -t service --full --no-legend "${serviceChk}.service" | sed 's/^\s*//g' | cut -f1 -d' ') == "${serviceChk}.service" ]]; then
            print_log -y "[skip] " -b "active " "Service ${serviceChk}"
        else
            print_log -y "start" "Service ${serviceChk}"
            if [ $flg_DryRun -ne 1 ]; then
                sudo systemctl enable "${serviceChk}.service"
                sudo systemctl start "${serviceChk}.service"
            fi
        fi

    done <"${scrDir}/system_ctl.lst"
fi

print_log -g "\nInstallation" " :: " "completed"
print_log -g "Log" " :: " "View logs at ${cacheDir}/logs/${HYDE_LOG}"
print_log -g "HyDE" " :: " "Please restart your system to apply changes"

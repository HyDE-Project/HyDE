#!/usr/bin/env bash
# shellcheck disable=SC2154

cat <<"EOF"

-------------------------------------------------
 _   _           _      ____ ____  ____
| | | |_   _  __| | ___| __ ) ___||  _ \
| |_| | | | |/ _` |/ _ \  _ \___ \| | | |
|  _  | |_| | (_| |  __/ |_) |__) | |_| |
|_| |_|\__, |\__,_|\___|____/____/|____/
       |___/
-------------------------------------------------

EOF

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

if [[ "$(uname -s)" != "FreeBSD" ]]; then
    print_log -crit "unsupported" "install_freebsd.sh must be run on FreeBSD."
    exit 1
fi

flg_Install=0
flg_Restore=0
flg_DryRun=0
flg_ThemeInstall=1

while getopts idrtmh RunStep; do
    case $RunStep in
    i) flg_Install=1 ;;
    d)
        flg_Install=1
        export use_default="--noconfirm"
        ;;
    r) flg_Restore=1 ;;
    t) flg_DryRun=1 ;;
    m) flg_ThemeInstall=0 ;;
    *)
        cat <<EOF
Usage: $0 [options]
            i : [i]nstall hyprland without configs
            d : install hyprland [d]efaults without configs --noconfirm
            r : [r]estore config files
            m : no the[m]e reinstallations
            t : [t]est run without executing (-irt to dry run all)

NOTE:
        running without args is equivalent to -ir

EOF
        exit 1
        ;;
    esac
done

HYDE_LOG="$(date +'%y%m%d_%Hh%Mm%Ss')"
export flg_DryRun flg_Install flg_Restore flg_ThemeInstall HYDE_LOG

if [ "${flg_DryRun}" -eq 1 ]; then
    print_log -n "[test-run] " -b "enabled :: " "Testing without executing"
elif [ $OPTIND -eq 1 ]; then
    flg_Install=1
    flg_Restore=1
fi

if [ ${flg_Install} -eq 1 ]; then
    cat <<"EOF"

 _         _       _ _ _
|_|___ ___| |_ ___| | |_|___ ___
| |   |_ -|  _| .'| | | |   | . |
|_|_|_|___|_| |__,|_|_|_|_|_|_  |
                            |___|

EOF

    shift $((OPTIND - 1))
    custom_pkg=$1
    cp "${scrDir}/pkg_core_freebsd.lst" "${scrDir}/install_pkg.lst"
    trap 'mv "${scrDir}/install_pkg.lst" "${cacheDir}/logs/${HYDE_LOG}/install_pkg.lst"' EXIT

    echo -e "\n#user packages" >>"${scrDir}/install_pkg.lst"
    if [ -f "${custom_pkg}" ] && [ -n "${custom_pkg}" ]; then
        cat "${custom_pkg}" >>"${scrDir}/install_pkg.lst"
    fi

    echo ""
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
            print_log -sec "shell" -warn "Defaulting to zsh"
            export myShell="zsh"
            ;;
        esac
        print_log -sec "shell" -stat "Added as shell" "${myShell}"
        echo "${myShell}" >>"${scrDir}/install_pkg.lst"
    fi

    if ! grep -q "^#user packages" "${scrDir}/install_pkg.lst"; then
        print_log -sec "pkg" -crit "No user packages found..." "Log file at ${cacheDir}/logs/${HYDE_LOG}/install_freebsd.sh"
        exit 1
    fi

    "${scrDir}/install_pkg.sh" "${scrDir}/install_pkg.lst"
fi

if [ ${flg_Restore} -eq 1 ]; then
    cat <<"EOF"

             _           _
 ___ ___ ___| |_ ___ ___|_|___ ___
|  _| -_|_ -|  _| . |  _| |   | . |
|_| |___|___|_| |___|_| |_|_|_|_  |
                              |___|

EOF

    if [ "${flg_DryRun}" -ne 1 ] && [ -n "${HYPRLAND_INSTANCE_SIGNATURE}" ]; then
        hyprctl keyword misc:disable_autoreload 1 -q
    fi

    "${scrDir}/restore_fnt.sh"
    "${scrDir}/restore_cfg.sh"
    "${scrDir}/restore_thm.sh"
    "${scrDir}/restore_shl.sh"
    print_log -g "[generate] " "cache ::" "Wallpapers..."
    if [ "${flg_DryRun}" -ne 1 ]; then
        export PATH="$HOME/.local/lib/hyde:$HOME/.local/bin:${PATH}"
        "$HOME/.local/lib/hyde/swwwallcache.sh" -t ""
        "$HOME/.local/lib/hyde/theme.switch.sh" -q || true
        "$HOME/.local/lib/hyde/waybar.py" --update || true
        echo "[install] reload :: Hyprland"
    fi
fi

if [ $flg_Install -eq 1 ]; then
    echo ""
    print_log -g "Installation" " :: " "COMPLETED!"
fi
print_log -b "Log" " :: " -y "View logs at ${cacheDir}/logs/${HYDE_LOG}"
print_log -warn "Reboot" "Please reboot the system to apply all changes."

#!/usr/bin/env bash
#|---/ /+-------------------------------+---/ /|#
#|--/ /-| Script to remove HyDE configs |--/ /-|#
#|-/ /--| Prasanth Rangan               |-/ /--|#
#|/ /---+-------------------------------+/ /---|#

cat <<"EOF"

-------------------------------------------------
        .
       / \                 _  _      ___  ___
      /^  \      _____    | || |_  _|   \| __|
     /  _  \    |_____|   | __ | || | |) | _|
    /  | | ~\             |_||_|\_, |___/|___|
   /.-'   '-.\                  |__/

-------------------------------------------------


.: WARNING :: This will remove all config files related to HyDE :.

please type "DONT HYDE" to continue...
EOF

read -r PROMPT_INPUT
[ "${PROMPT_INPUT}" == "DONT HYDE" ] || exit 0

cat <<"EOF"

         _         _       _ _
 _ _ ___|_|___ ___| |_ ___| | |
| | |   | |   |_ -|  _| .'| | |
|___|_|_|_|_|_|___|_| |__,|_|_|


EOF

scrDir=$(dirname "$(realpath "$0")")
source "${scrDir}/global_fn.sh"
if [ $? -ne 0 ]; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

CfgLst="${scrDir}/restore_cfg.lst"
if [ ! -f "${CfgLst}" ]; then
    echo "ERROR: '${CfgLst}' does not exist..."
    exit 1
fi

BkpDir="${HOME}/.config/cfg_backups/$(date +'%y%m%d_%Hh%Mm%Ss')_remove"
mkdir -p "${BkpDir}"

cat "${CfgLst}" | while read lst; do
    pth=$(echo "${lst}" | awk -F '|' '{print $3}')
    pth=$(eval echo "${pth}")
    cfg=$(echo "${lst}" | awk -F '|' '{print $4}')

    echo "${cfg}" | xargs -n 1 | while read -r cfg_chk; do
        [[ -z "${pth}" ]] && continue
        if [ -d "${pth}/${cfg_chk}" ] || [ -f "${pth}/${cfg_chk}" ]; then
            tgt=$(echo "${pth}" | sed "s+^${HOME}++g")
            if [ ! -d "${BkpDir}${tgt}" ]; then
                mkdir -p "${BkpDir}${tgt}"
            fi
            mv "${pth}/${cfg_chk}" "${BkpDir}${tgt}"
            echo -e "\033[0;34m[removed]\033[0m ${pth}/${cfg_chk}"
        fi
    done
done

[ -d "$HOME/.config/hyde" ] && rm -rf "$HOME/.config/hyde"
[ -d "$HOME/.cache/hyde" ] && rm -rf "$HOME/.cache/hyde"
[ -d "$HOME/.local/state/hyde" ] && rm -rf "$HOME/.local/state/hyde"

cat <<"NOTE"
-------------------------------------------------------
.: Manual action required to complete uninstallation :.
-------------------------------------------------------

Remove HyDE related backups/icons/fonts/themes manually from these paths
$HOME/.config/cfg_backups               # remove all previous backups
$HOME/.local/share/fonts                # remove fonts from here
$HOME/.local/share/icons                # remove fonts from here
$HOME/.local/share/themes               # remove fonts from here
$HOME/.icons                            # remove icons from here
$HOME/.themes                           # remove themes from here

Revert back bootloader/pacman/sddm settings manually from these backups
/boot/loader/entries/*.conf.hyde.bkp    # restore systemd-boot from this backup
/etc/default/grub.hyde.bkp              # restore grub from this backup
/boot/grub/grub.hyde.bkp                # restore grub from this backup
/usr/share/grub/themes                  # remove grub themes from here
/etc/pacman.conf.hyde.bkp               # restore pacman from this backup
/etc/sddm.conf.d/kde_settings.hyde.bkp  # restore sddm from this backup
/usr/share/sddm/themes                  # remove sddm themes from here

Uninstall the packages manually that are no longer required based on these list
${scrDir}/pkg_core.lst
${scrDir}/pkg_extra.lst
NOTE

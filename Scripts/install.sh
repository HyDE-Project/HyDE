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

show_usage() {
	cat <<EOF
$(_t install.usage 'Usage: %s [options]' "$0")
            i : $(_t install.option.install '[i]nstall hyprland without configs')
            d : $(_t install.option.defaults 'install hyprland [d]efaults without configs --noconfirm')
            r : $(_t install.option.restore '[r]estore config files')
            s : $(_t install.option.services 'enable system [s]ervices')
            n : $(_t install.option.no_nvidia 'ignore/[n]o [n]vidia actions (-irsn to ignore nvidia)')
            h : $(_t install.option.shell 're-evaluate S[h]ell')
            m : $(_t install.option.no_theme 'no the[m]e reinstallations')
            t : $(_t install.option.dry_run '[t]est run without executing (-irst to dry run all)')

$(_t install.usage_note_title 'NOTE:')
        $(_t install.usage_note_default 'running without args is equivalent to -irs')
        $(_t install.usage_note_ignore_nvidia 'to ignore nvidia, run -irsn')

$(_t install.usage_wrong_title 'WRONG:')
        $(_t install.usage_wrong_nvidia 'install.sh -n # This will not work')

EOF
}

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

while getopts :idrstmnh RunStep; do
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
		print_log -r "[nvidia] " -b "$(_t install.ignored 'Ignored :: ')" "$(_t install.skipping_nvidia 'skipping Nvidia actions')"
		;;
	h)
		# shellcheck disable=SC2034
		export flg_Shell=1
		print_log -r "[shell] " -b "$(_t install.reevaluate 'Reevaluate :: ')" "shell options"
		;;
	t) flg_DryRun=1 ;;
	m) flg_ThemeInstall=0 ;;
	*)
		show_usage
		exit 1
		;;
	esac
done

# Only export that are used outside this script
HYDE_LOG="$(date +'%y%m%d_%Hh%Mm%Ss')"
export flg_DryRun flg_Nvidia flg_Shell flg_Install flg_ThemeInstall HYDE_LOG

if [ "${flg_DryRun}" -eq 1 ]; then
	print_log -n "[test-run] " -b "$(_t install.dry_run_enabled 'enabled :: ')" "$(_t install.testing_without_executing 'Testing without executing')"
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
	trap 'mv "${scrDir}/install_pkg.lst" "${cacheDir}/logs/${HYDE_LOG}/install_pkg.lst"' EXIT

	echo -e "\n#user packages" >>"${scrDir}/install_pkg.lst" # Add a marker for user packages
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
			print_log -warn "Nvidia" "$(_t install.warn_nvidia_ignored 'Nvidia GPU detected but ignored...')"
		fi
	fi
	nvidia_detect --verbose

	#----------------#
	# get user prefs #
	#----------------#
	echo ""
	if ! chk_list "aurhlpr" "${aurList[@]}"; then
		print_log -c "\n$(_t install.aur_helpers 'AUR Helpers :: ')"
		aurList+=("yay-bin" "paru-bin") # Add this here instead of in global_fn.sh
		for i in "${!aurList[@]}"; do
			print_log -sec "$((i + 1))" " ${aurList[$i]} "
		done

		prompt_timer 120 "$(_t install.enter_option_yay 'Enter option number [default: yay-bin] | q to quit ')"

		case "${PROMPT_INPUT}" in
		1) export getAur="yay" ;;
		2) export getAur="paru" ;;
		3) export getAur="yay-bin" ;;
		4) export getAur="paru-bin" ;;
		q)
			print_log -sec "AUR" -crit "Quit" "$(_t install.exiting 'Exiting...')"
			exit 1
			;;
		*)
			print_log -sec "AUR" -warn "$(_t install.defaulting_yay 'Defaulting to yay-bin')"
			print_log -sec "AUR" -stat "default" "yay-bin"
			export getAur="yay-bin"
			;;
		esac
		if [[ -z "$getAur" ]]; then
			print_log -sec "AUR" -crit "$(_t install.no_aur_helper 'No AUR helper found...')" "$(_t install.log_file_at 'Log file at %s' "${cacheDir}/logs/${HYDE_LOG}")"
			exit 1
		fi
	fi

	if ! chk_list "myShell" "${shlList[@]}"; then
		print_log -c "$(_t install.shell 'Shell :: ')"
		for i in "${!shlList[@]}"; do
			print_log -sec "$((i + 1))" " ${shlList[$i]} "
		done
		prompt_timer 120 "$(_t install.enter_option_zsh 'Enter option number [default: zsh] | q to quit ')"

		case "${PROMPT_INPUT}" in
		1) export myShell="zsh" ;;
		2) export myShell="fish" ;;
		q)
			print_log -sec "shell" -crit "Quit" "$(_t install.exiting 'Exiting...')"
			exit 1
			;;
		*)
			print_log -sec "shell" -warn "$(_t install.defaulting_zsh 'Defaulting to zsh')"
			export myShell="zsh"
			;;
		esac
		print_log -sec "shell" -stat "$(_t install.shell_added 'Added as shell')" "${myShell}"
		echo "${myShell}" >>"${scrDir}/install_pkg.lst"

		if [[ -z "$myShell" ]]; then
			print_log -sec "shell" -crit "$(_t install.no_shell 'No shell found...')" "$(_t install.log_file_at 'Log file at %s' "${cacheDir}/logs/${HYDE_LOG}")"
			exit 1
		else
			print_log -sec "shell" -stat "$(_t install.detected 'detected :: ')" "${myShell}"
		fi
	fi

	if ! grep -q "^#user packages" "${scrDir}/install_pkg.lst"; then
		print_log -sec "pkg" -crit "$(_t install.no_user_packages 'No user packages found...')" "$(_t install.log_file_at 'Log file at %s' "${cacheDir}/logs/${HYDE_LOG}/install.sh")"
		exit 1
	fi

	#--------------------------------#
	# install packages from the list #
	#--------------------------------#
	"${scrDir}/install_pkg.sh" "${scrDir}/install_pkg.lst"
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
	print_log -g "[generate] " "cache ::" "$(_t install.generate_wallpapers 'Wallpapers...')"
	if [ "${flg_DryRun}" -ne 1 ]; then
		export PATH="$HOME/.local/lib/hyde:$HOME/.local/bin:${PATH}"
		"$HOME/.local/lib/hyde/wallpaper/cache.sh" commence -t ""
		"$HOME/.local/lib/hyde/theme.switch.sh" -q || true
		"$HOME/.local/lib/hyde/waybar.py" --update || true
		_tn install.reload_hyprland '[install] reload :: Hyprland'
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

#---------------------------#
# run migrations            #
#---------------------------#
if [ ${flg_Restore} -eq 1 ]; then

	# migrationDir="$(realpath "$(dirname "$(realpath "$0")")/../migrations")"
	migrationDir="${scrDir}/migrations"

	if [ ! -d "${migrationDir}" ]; then
		print_log -warn "Migrations" "Directory not found: ${migrationDir}"
	fi

	_tn install.migration_running 'Running migrations from: %s' "${migrationDir}"

	if [ -d "${migrationDir}" ] && find "${migrationDir}" -type f | grep -q .; then
		migrationFile=$(find "${migrationDir}" -maxdepth 1 -type f -printf '%f\n' | sort -r | head -n 1)

		if [[ -n "${migrationFile}" && -f "${migrationDir}/${migrationFile}" ]]; then
			_tn install.migration_found 'Found migration file: %s' "${migrationFile}"
			sh "${migrationDir}/${migrationFile}" || { true && print_log -warn "Migration" "$(_t install.migration_failed 'Failed to execute %s' "${migrationFile}")"; }
		else
			_tn install.migration_none 'No migration file found in %s. Skipping migrations.' "${migrationDir}"
		fi
	fi

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

	"${scrDir}/restore_svc.sh"
fi

if [ $flg_Install -eq 1 ]; then
	echo ""
	print_log -g "Installation" " :: " "$(_t install.installation_completed 'COMPLETED!')"
fi
print_log -b "Log" " :: " -y "$(_t install.log_view 'View logs at %s' "${cacheDir}/logs/${HYDE_LOG}")"
if [ $flg_Install -eq 1 ] ||
	[ $flg_Restore -eq 1 ] ||
	[ $flg_Service -eq 1 ] &&
	[ $flg_DryRun -ne 1 ]; then

	if [[ -z "${HYPRLAND_CONFIG:-}" ]] || [[ ! -f "${HYPRLAND_CONFIG}" ]]; then
		print_log -warn "$(_t install.hyprland_config_missing 'Hyprland config not found! Might be a new install or upgrade.')"
		print_log -warn "$(_t install.reboot.apply_changes 'Please reboot the system to apply new changes.')"
	fi

	print_log -stat "HyDE" "$(_t install.reboot.prompt 'It is not recommended to use newly installed or upgraded HyDE without rebooting the system. Do you want to reboot the system? (y/N)')"
	read -r answer

	if [[ "$answer" == [Yy] ]]; then
		_tn install.rebooting 'Rebooting system'
		systemctl reboot
	else
		_tn install.not_rebooting 'The system will not reboot'
	fi
fi

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
#------------------

show_help() {
	cat <<EOF
Usage: $0 [OPTIONS]

Options:
    -i, --install          Install packages only
    -d, --defaults         Install packages with defaults (noconfirm)
    -r, --restore          Restore configs and dotfiles
    -s, --services         Enable system services
    -p, --pre              Run pre-install only (Python environment setup)
    -n, --no-nvidia        Ignore nvidia actions
    -h, --shell            Re-evaluate shell configuration
    -m, --no-theme         Skip theme installation
    -t, --test             Test run (dry-run)
    --help                 Show this help message

Common combinations:
    ./install.sh              # Full installation (default)
    ./install.sh -p           # Pre-install only (run first if restore fails)
    ./install.sh -r           # Restore configs and dotfiles only
    ./install.sh -irs         # Install, restore, and services
    ./install.sh -irsn       # Full install without nvidia

NOTE:
    If restore fails with "deez-dots not found", run: ./install.sh -p
    The -p flag sets up Python environment and deez-dots

EOF
	exit 0
}

operations=()
dry_run=0
nvidia=1
theme_install=1

while [[ $# -gt 0 ]]; do
	case $1 in
		-i|--install)
			operations+=("install")
			shift
			;;
		-d|--defaults)
			operations+=("install")
			export use_default="--noconfirm"
			shift
			;;
		-r|--restore)
			operations+=("restore")
			shift
			;;
		-s|--services)
			operations+=("services")
			shift
			;;
		-p|--pre)
			operations+=("pre")
			shift
			;;
		-n|--no-nvidia)
			nvidia=0
			print_log -r "[nvidia] " -b "Ignored :: " "skipping Nvidia actions"
			shift
			;;
		-h|--shell)
			export flg_Shell=1
			print_log -r "[shell] " -b "Reevaluate :: " "shell options"
			shift
			;;
		-m|--no-theme)
			theme_install=0
			shift
			;;
		-t|--test)
			dry_run=1
			shift
			;;
		--help)
			show_help
			;;
		*)
			echo "Unknown option: $1"
			show_help
			;;
	esac
done

if [ ${#operations[@]} -eq 0 ]; then
	operations=("install" "restore" "services")
fi

export flg_DryRun=$dry_run
export flg_Nvidia=$nvidia
export flg_ThemeInstall=$theme_install
HYDE_LOG="$(date +'%y%m%d_%Hh%Mm%Ss')"
export HYDE_LOG

if [ $dry_run -eq 1 ]; then
	print_log -n "[test-run] " -b "enabled :: " "Testing without executing"
fi

#--------------------#
# Helper functions #
#--------------------
has_operation() {
	local op="$1"
	[[ " ${operations[*]} " =~ " ${op} " ]]
}

#--------------------#
# pre-install script #
#--------------------
if has_operation "pre"; then
	cat <<"EOF"
                _         _       _ _
 ___ ___ ___   |_|___ ___| |_ ___| | |
| . |  _| -_|  | |   |_ -|  _| .'| | |
|  _|_| |___|  |_|_|_|___|_| |__,|_|_|
|_|

EOF

	"${scrDir}/install_pre.sh"
	exit 0
fi

if has_operation "install" && has_operation "restore"; then
	"${scrDir}/install_pre.sh"
fi

#------------#
# installing #
#------------
if has_operation "install"; then
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
			print_log -warn "Nvidia" "Nvidia GPU detected but ignored..."
		fi
	fi
	nvidia_detect --verbose

	#----------------#
	# get user prefs #
	#----------------#
	echo ""
	if ! chk_list "aurhlpr" "${aurList[@]}"; then
		print_log -c "\nAUR Helpers :: "
		aurList+=("yay-bin" "paru-bin") # Add this here instead of in global_fn.sh
		for i in "${!aurList[@]}"; do
			print_log -sec "$((i + 1))" " ${aurList[$i]} "
		done

		prompt_timer 120 "Enter option number [default: yay-bin] | q to quit "

		case "${PROMPT_INPUT}" in
		1) export getAur="yay" ;;
		2) export getAur="paru" ;;
		3) export getAur="yay-bin" ;;
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
		if [[ -z "$getAur" ]]; then
			print_log -sec "AUR" -crit "No AUR helper found..." "Log file at ${cacheDir}/logs/${HYDE_LOG}"
			exit 1
		fi
	fi

	# if ! chk_list "myShell" "${shlList[@]}"; then
	# 	print_log -c "Shell :: "
	# 	for i in "${!shlList[@]}"; do
	# 		print_log -sec "$((i + 1))" " ${shlList[$i]} "
	# 	done
	# 	prompt_timer 120 "Enter option number [default: zsh] | q to quit "

	# 	case "${PROMPT_INPUT}" in
	# 	1) export myShell="zsh" ;;
	# 	2) export myShell="fish" ;;
	# 	q)
	# 		print_log -sec "shell" -crit "Quit" "Exiting..."
	# 		exit 1
	# 		;;
	# 	*)
	# 		print_log -sec "shell" -warn "Defaulting to zsh"
	# 		export myShell="zsh"
	# 		;;
	# 	esac
	# 	print_log -sec "shell" -stat "Added as shell" "${myShell}"
	# 	echo "${myShell}" >>"${scrDir}/install_pkg.lst"

	# 	if [[ -z "$myShell" ]]; then
	# 		print_log -sec "shell" -crit "No shell found..." "Log file at ${cacheDir}/logs/${HYDE_LOG}"
	# 		exit 1
	# 	else
	# 		print_log -sec "shell" -stat "detected :: " "${myShell}"
	# 	fi
	# fi

	if ! grep -q "^#user packages" "${scrDir}/install_pkg.lst"; then
		print_log -sec "pkg" -crit "No user packages found..." "Log file at ${cacheDir}/logs/${HYDE_LOG}/install.sh"
		exit 1
	fi

	#--------------------------------#
	# install packages from the list #
	#--------------------------------#
	"${scrDir}/install_pkg.sh" "${scrDir}/install_pkg.lst"
fi

#---------------------------#
# restore my custom configs #
#---------------------------
if has_operation "restore"; then
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

	# Deploy dotfiles using deez-dots
	if [ "${flg_DryRun}" -eq 1 ]; then
		print_log -y "[DEEZ-DOTS] " -b "dry-run :: " "Would deploy dotfiles"
	else
		python_env_dir="${HOME}/.local/state/hyde/python_env"
		deez_exe="${python_env_dir}/bin/deez"

		[ ! -f "${deez_exe}" ] && {
			print_log -err "[DEEZ-DOTS] " -crit "ERROR" "deez-dots not found in Python environment"
			print_log -err "[DEEZ-DOTS] " -crit "FIX" "Run: ./install.sh -p (pre-install only)"
			exit 1
		}

		print_log -g "[DEEZ-DOTS] " -b "deploy :: " "Installing core dotfiles..."
		"${deez_exe}" --source "${cloneDir}" --config "${scrDir}/dots-groups/core.toml" dots --skip-git --deploy all || exit 1

		print_log -g "[DEEZ-DOTS] " -b "deploy :: " "Installing extra dotfiles..."
		"${deez_exe}" --source "${cloneDir}" --config "${scrDir}/dots-groups/extra.toml" dots --skip-git --deploy || exit 1

		print_log -g "[DEEZ-DOTS] " -b "complete :: " "Dotfiles deployed"
	fi

	"${scrDir}/restore_thm.sh"
	print_log -g "[generate] " "cache ::" "Wallpapers..."
	if [ "${flg_DryRun}" -ne 1 ]; then
		export PATH="$HOME/.local/lib/hyde:$HOME/.local/bin:${PATH}"
		"$HOME/.local/lib/hyde/wallpaper/cache.sh" commence -t ""
		"$HOME/.local/lib/hyde/theme.switch.sh" -q || true
		"$HOME/.local/lib/hyde/waybar.py" --update || true
		echo "[install] reload :: Hyprland"
	fi

fi

#---------------------#
# post-install script #
#---------------------#
if has_operation "install" && has_operation "restore"; then
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
if has_operation "restore"; then

	# migrationDir="$(realpath "$(dirname "$(realpath "$0")")/../migrations")"
	migrationDir="${scrDir}/migrations"

	if [ ! -d "${migrationDir}" ]; then
		print_log -warn "Migrations" "Directory not found: ${migrationDir}"
	fi

	echo "Running migrations from: ${migrationDir}"

	if [ -d "${migrationDir}" ] && find "${migrationDir}" -type f | grep -q .; then
		migrationFile=$(find "${migrationDir}" -maxdepth 1 -type f -printf '%f\n' | sort -r | head -n 1)

		if [[ -n "${migrationFile}" && -f "${migrationDir}/${migrationFile}" ]]; then
			echo "Found migration file: ${migrationFile}"
			sh "${migrationDir}/${migrationFile}" || { true && print_log -warn "Migration" "Failed to execute ${migrationFile}"; }
		else
			echo "No migration file found in ${migrationDir}. Skipping migrations."
		fi
	fi

fi

#------------------------#
# enable system services #
#------------------------#
if has_operation "services"; then
	cat <<"EOF"

                 _
 ___ ___ ___ _ _|_|___ ___ ___
|_ -| -_|  _| | | |  _| -_|_ -|
|___|___|_|  \_/|_|___|___|___|

EOF

	"${scrDir}/restore_svc.sh"
fi

if has_operation "install"; then
	echo ""
	print_log -g "Installation" " :: " "COMPLETED!"
fi
print_log -b "Log" " :: " -y "View logs at ${cacheDir}/logs/${HYDE_LOG}"
if has_operation "install" ||
	has_operation "restore" ||
	has_operation "services" &&
	[ $dry_run -ne 1 ]; then

	if [[ -z "${HYPRLAND_CONFIG:-}" ]] || [[ ! -f "${HYPRLAND_CONFIG}" ]]; then
		print_log -warn "Hyprland config not found! Might be a new install or upgrade."
		print_log -warn "Please reboot the system to apply new changes."
	fi

	print_log -stat "HyDE" "It is not recommended to use newly installed or upgraded HyDE without rebooting the system. Do you want to reboot the system? (y/N)"
	read -r answer

	if [[ "$answer" == [Yy] ]]; then
		echo "Rebooting system"
		systemctl reboot
	else
		echo "The system will not reboot"
	fi
fi

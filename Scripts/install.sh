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
	-i | --install)
		operations+=("install")
		shift
		;;
	-d | --defaults)
		operations+=("install")
		export use_default="--noconfirm"
		shift
		;;
	-r | --restore)
		operations+=("restore")
		shift
		;;
	-s | --services)
		operations+=("services")
		shift
		;;
	-p | --pre)
		operations+=("pre")
		shift
		;;
	-n | --no-nvidia)
		nvidia=0
		print_log -r "[nvidia] " -b "Ignored :: " "skipping Nvidia actions"
		shift
		;;
	-h | --shell)
		export flg_Shell=1
		print_log -r "[shell] " -b "Reevaluate :: " "shell options"
		shift
		;;
	-m | --no-theme)
		theme_install=0
		shift
		;;
	-t | --test)
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

	#----------------#
	# get user prefs #
	#----------------#
	echo ""

	if ! chk_list "aurhlpr" "${aurList[@]}"; then
		print_log -c "\nAUR Helpers :: "
		aurList+=("yay-bin" "paru-bin")
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
		print_log -sec "shell" -stat "detected" "${myShell}"
	fi

	#------------------------------------#
	# install AUR helper via pacman first #
	#------------------------------------#
	"${scrDir}/install_aur.sh" "${getAur}" 2>&1

	deez_exe="${HOME}/.local/state/hyde/python_env/bin/deez"

	#------------------------------------------#
	# build transient TOML: core deps + nvidia  #
	#------------------------------------------#
	core_toml="$(mktemp --suffix=-core.toml)"
	trap 'rm -f "${core_toml}"' RETURN EXIT

	cat > "${core_toml}" <<-TOML
		# Auto-generated by install.sh — core deps
		include = [
		    "${scrDir}/dots-groups/core.toml",
		]

		[[global.dependency]]
		pacman = [
	TOML

# TODO: This is arch specific; A separate install script should be written
	if nvidia_detect; then
		if [ "${flg_Nvidia}" -eq 1 ]; then
			cat /usr/lib/modules/*/pkgbase 2>/dev/null | while read -r kernel; do
				echo "\"${kernel}-headers\","
			done >> "${core_toml}"
			nvidia_detect --drivers | while read -r pkg; do
				[ -n "${pkg}" ] && echo "\"${pkg}\","
			done >> "${core_toml}"
		else
			print_log -warn "Nvidia" "Nvidia GPU detected but ignored..."
		fi
	fi
	nvidia_detect --verbose
	echo "]" >> "${core_toml}"

	#--------------------------------#
	# install core deps (+ nvidia)   #
	#--------------------------------#
	if [ "${flg_DryRun}" -eq 1 ]; then
		print_log -y "[CORE] " -b "dry-run :: " "Would install core packages"
	else
		print_log -g "[CORE] " -b "install :: " "Core system packages..."
		"${deez_exe}" deps --install --config "${core_toml}" --source "${cloneDir}" || {
			print_log -err "[CORE] " -crit "ERROR" "Core package installation failed"
			exit 1
		}
		print_log -g "[CORE] " -b "complete :: " "Core packages installed"
	fi
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

	deez_exe="${HOME}/.local/state/hyde/python_env/bin/deez"
	deploy_failed=0

	#------------------------------------------#
	# rebuild transient TOML: core deps+nvidia  #
	#------------------------------------------#
	core_toml="$(mktemp --suffix=-core.toml)"
	trap 'rm -f "${core_toml}"' RETURN EXIT

	cat > "${core_toml}" <<-TOML
		include = [
		    "${scrDir}/dots-groups/core.toml",
		]

		[[global.dependency]]
		pacman = [
	TOML
	if nvidia_detect && [ "${flg_Nvidia}" -eq 1 ]; then
		cat /usr/lib/modules/*/pkgbase 2>/dev/null | while read -r kernel; do
			echo "\"${kernel}-headers\","
		done >> "${core_toml}"
		nvidia_detect --drivers | while read -r pkg; do
			[ -n "${pkg}" ] && echo "\"${pkg}\","
		done >> "${core_toml}"
	fi
	echo "]" >> "${core_toml}"

	#------------------------------------------#
	# rebuild transient TOML: extra deps+shell  #
	#------------------------------------------#
	extra_toml="$(mktemp --suffix=-extra.toml)"
	trap 'rm -f "${extra_toml}"' RETURN EXIT

	cat > "${extra_toml}" <<-TOML
		include = [
		    "${scrDir}/dots-groups/extra.toml",
		]

		[[global.dependency]]
		pacman = [
	TOML
	# starship is needed for both zsh and fish prompts
	echo "\"starship\"," >> "${extra_toml}"
	echo "]" >> "${extra_toml}"

	#-------------------------------#
	# re-check / install core deps  #
	#-------------------------------#
	if [ "${flg_DryRun}" -eq 1 ]; then
		print_log -y "[CORE] " -b "dry-run :: " "Would re-check core deps"
	else
		print_log -g "[CORE] " -b "verify :: " "Verifying core packages..."
		"${deez_exe}" deps --install --config "${core_toml}" --source "${cloneDir}" || {
			print_log -err "[CORE] " -crit "ERROR" "Core package verification failed"
			exit 1
		}
	fi

	#-------------------------------#
	# re-check / install extra deps #
	#-------------------------------#
	if [ "${flg_DryRun}" -eq 1 ]; then
		print_log -y "[EXTRA] " -b "dry-run :: " "Would re-check extra deps"
	else
		print_log -g "[EXTRA] " -b "verify :: " "Verifying extra packages..."
		"${deez_exe}" deps --install --config "${extra_toml}" --source "${cloneDir}" || {
			print_log -err "[EXTRA] " -crit "ERROR" "Extra package verification failed"
			exit 1
		}
		print_log -g "[DEPS] " -b "verify :: " "All packages verified"
	fi

	# Lua environment setup
	if [ "${flg_DryRun}" -eq 1 ]; then
		print_log -y "[LUA] " -b "dry-run :: " "Would setup Lua environment"
	else
		if ! python3 "${cloneDir}/Configs/.local/lib/hyde/pyutils/lua_env.py" create; then
			print_log -err "[LUA] " -crit "ERROR" "Failed to create Lua environment"
			exit 1
		fi
		print_log -g "[LUA] " -b "complete :: " "Environment setup complete"
	fi

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

		# A failed deployment used to end the run here, which cost the user
		# every step below it — the theme, the wallpaper cache, the migrations,
		# the services. Those are what bring a partly deployed tree back into
		# shape, so they are exactly what should still run. The failure is
		# carried to the end of the restore and reported there.
		print_log -g "[DEEZ-DOTS] " -b "deploy :: " "Installing core dotfiles..."
		"${deez_exe}" --source "${cloneDir}" --config "${scrDir}/dots-groups/core.toml" dots --skip-git --deploy all || {
			print_log -err "[DEEZ-DOTS] " -crit "ERROR" "Core dotfiles deployed with failures"
			deploy_failed=1
		}

		print_log -g "[DEEZ-DOTS] " -b "deploy :: " "Installing extra dotfiles..."
		"${deez_exe}" --source "${cloneDir}" --config "${scrDir}/dots-groups/extra.toml" dots --skip-git --deploy || {
			print_log -err "[DEEZ-DOTS] " -crit "ERROR" "Extra dotfiles deployed with failures"
			deploy_failed=1
		}

		if [ "${deploy_failed}" -eq 0 ]; then
			print_log -g "[DEEZ-DOTS] " -b "complete :: " "Dotfiles deployed"
		fi
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

	migrationStateFile="${XDG_STATE_HOME:-${HOME}/.local/state}/hyde/migration/applied"

	run_pending_migrations "${migrationDir}" "${migrationStateFile}"

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

# Reported here rather than where it happened, so the theme, the migrations and
# the services above still run against the dots that did land.
if [ "${deploy_failed:-0}" -ne 0 ]; then
	print_log -err "[DEEZ-DOTS] " -crit "ERROR" "Some dots were not deployed. Deal with the failures reported above and run the restore again."
	print_log -b "Log" " :: " -y "View logs at ${cacheDir}/logs/${HYDE_LOG}"
	exit 1
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

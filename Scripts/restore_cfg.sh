#!/usr/bin/env bash
# shellcheck disable=SC2154
# shellcheck disable=SC1091
#|---/ /+--------------------------------+---/ /|#
#|--/ /-| Script to restore hyde configs |--/ /-|#
#|-/ /--| Prasanth Rangan                |-/ /--|#
#|/ /---+--------------------------------+/ /---|#

# Optional rsync. The logic for now looks very explicit as it helps  in debugging just in case. In future, if more options are added, this can be refactored to be more modular.
if command -v rsync >/dev/null 2>&1; then
	USE_RSYNC=${USE_RSYNC:-0}
else
	USE_RSYNC=0
fi

deploy_list() {

	while read -r lst; do

		if [ "$(awk -F '|' '{print NF}' <<<"${lst}")" -ne 5 ]; then
			continue
		fi
		# Skip lines that start with '#' or any space followed by '#'
		if [[ "${lst}" =~ ^[[:space:]]*# ]]; then
			continue
		fi

		ovrWrte=$(awk -F '|' '{print $1}' <<<"${lst}")
		bkpFlag=$(awk -F '|' '{print $2}' <<<"${lst}")
		pth=$(awk -F '|' '{print $3}' <<<"${lst}")
		pth=$(eval echo "${pth}")
		cfg=$(awk -F '|' '{print $4}' <<<"${lst}")
		pkg=$(awk -F '|' '{print $5}' <<<"${lst}")

		while read -r pkg_chk; do
			if ! pkg_installed "${pkg_chk}"; then
				echo -e "\033[0;33m[skip]\033[0m ${pth}/${cfg} as dependency ${pkg_chk} is not installed..."
				continue 2
			fi
		done < <(echo "${pkg}" | xargs -n 1)

		echo "${cfg}" | xargs -n 1 | while read -r cfg_chk; do
			if [[ -z "${pth}" ]]; then continue; fi
			tgt="${pth/#$HOME/}"

			if { [ -d "${pth}/${cfg_chk}" ] || [ -f "${pth}/${cfg_chk}" ]; } && [ "${bkpFlag}" == "Y" ]; then

				if [ ! -d "${BkpDir}${tgt}" ]; then
					[[ ${flg_DryRun} -ne 1 ]] && mkdir -p "${BkpDir}${tgt}"
				fi

				if [ "${ovrWrte}" == "Y" ]; then
					[[ ${flg_DryRun} -ne 1 ]] && mv "${pth}/${cfg_chk}" "${BkpDir}${tgt}"
				else

					[[ ${flg_DryRun} -ne 1 ]] && cp -r "${pth}/${cfg_chk}" "${BkpDir}${tgt}"
				fi
				echo -e "\033[0;34m[backup]\033[0m ${pth}/${cfg_chk} --> ${BkpDir}${tgt}..."
			fi

			if [ ! -d "${pth}" ]; then
				[[ ${flg_DryRun} -ne 1 ]] && mkdir -p "${pth}"
			fi

			if [ ! -f "${pth}/${cfg_chk}" ]; then
				[[ ${flg_DryRun} -ne 1 ]] && cp -r "${CfgDir}${tgt}/${cfg_chk}" "${pth}"
				echo -e "\033[0;32m[restore]\033[0m ${pth} <-- ${CfgDir}${tgt}/${cfg_chk}..."
			elif [ "${ovrWrte}" == "Y" ]; then
				[[ ${flg_DryRun} -ne 1 ]] && cp -r "${CfgDir}${tgt}/${cfg_chk}" "${pth}"
				echo -e "\033[0;33m[overwrite]\033[0m ${pth} <-- ${CfgDir}${tgt}/${cfg_chk}..."
			else
				echo -e "\033[0;33m[preserve]\033[0m Skipping ${pth}/${cfg_chk} to preserve user setting..."
			fi
		done

	done <<<"$(cat "${CfgLst}")"
}

deploy_psv() {
	print_log -g "[file extension]" -b " :: " "File: ${CfgLst}"
	while read -r lst; do

		# Skip lines that do not have exactly 4 columns
		if [ "$(awk -F '|' '{print NF}' <<<"${lst}")" -ne 4 ]; then
			if [[ "${lst}" =~ ^\  ]]; then
				echo ""
				print_log -b "${lst}"
			fi
			continue
		fi
		# Skip lines that start with '#' or any space followed by '#'
		if [[ "${lst}" =~ ^[[:space:]]*# ]]; then
			continue
		fi

		ctlFlag=$(awk -F '|' '{print $1}' <<<"${lst}")
		pth=$(awk -F '|' '{print $2}' <<<"${lst}")
		pth=$(eval "echo ${pth}")
		cfg=$(awk -F '|' '{print $3}' <<<"${lst}")
		pkg=$(awk -F '|' '{print $4}' <<<"${lst}")

		# Check if ctlFlag is not one of the values 'O', 'R', 'B', 'S', or 'P'
		if [[ "${ctlFlag}" = "I" ]]; then
			print_log -r "[ignore] :: " "${pth}/${cfg}"
			continue 2
		fi

		# Start a loop that reads each line from the output of the command enclosed within the process substitution '< <(...)'
		while read -r pkg_chk; do

			# Call the function pkg_installed with the argument pkg_chk. If the function returns false (the package is not installed), then...
			if ! pkg_installed "${pkg_chk}"; then
				# Print a message stating that the current configuration is being skipped because a dependency is not installed
				print_log -y "[skip] " -r "missing" -b " :: " -y "missing dependency" -g " '${pkg_chk}'" -r " --> " "${pth}/${cfg}"
				# Skip the rest of the current loop iteration and proceed to the next iteration
				continue 2
			fi
		done < <(echo "${pkg}" | xargs -n 1)

		[[ "${USE_RSYNC}" -eq 1 ]] && print_log -g "Using rsync"

		# Pipe the value of cfg to xargs, which splits it into separate arguments based on spaces, and then pipe the output to a while loop
		echo "${cfg}" | xargs -n 1 | while read -r cfg_chk; do

			# Check if the variable pth is empty, if it is, skip the current iteration
			if [[ -z "${pth}" ]]; then continue; fi

			# Remove the HOME directory from the beginning of the path stored in pth and store the result in tgt
			tgt="${pth//${HOME}/}"
			crnt_cfg="${pth}/${cfg_chk}"

			# Handle Trash Cleanup
			if [ "${ctlFlag}" = "T" ]; then
				# For Trash flag, act solely on the target's existence
				[[ ! -d "${BkpDir}${tgt}" ]] && [[ ${flg_DryRun} -ne 1 ]] && mkdir -p "${BkpDir}${tgt}"
				if [ -e "${crnt_cfg}" ]; then
					if [ "${flg_DryRun}" -ne 1 ]; then
						if mv "${crnt_cfg}" "${BkpDir}${tgt}"; then
							print_log -r "[trash]" -b " :: " "${crnt_cfg} --> ${BkpDir}${tgt}"
						else
							print_log -r "[error]" -b " :: " "Failed to move ${crnt_cfg} to ${BkpDir}${tgt}"
						fi
					else
						print_log -y "[dry-run]" -b " :: " "Would trash ${crnt_cfg} --> ${BkpDir}${tgt}"
					fi
				else
					print_log -y "[trash]" -b " :: " "Target missing, nothing to move: ${crnt_cfg}"
				fi
				# Skip further processing for Trash
				continue
			fi

			if [ ! -e "${CfgDir}${tgt}/${cfg_chk}" ] && [ "${ctlFlag}" != "B" ]; then
				echo "Source: ${CfgDir}${tgt}/${cfg_chk} does not exist, skipping..."
				print_log -y "[skip]" -b "no source" "${CfgDir}${tgt}/${cfg_chk} does not exist"
				continue
			fi

			[[ ! -d "${pth}" ]] && [[ ${flg_DryRun} -ne 1 ]] && mkdir -p "${pth}"

			if [ -e "${crnt_cfg}" ]; then
				# echo "Files exist: ${crnt_cfg}"
				# Check if the directory specified by BkpDir and tgt exists, if it doesn't, create it
				[[ ! -d "${BkpDir}${tgt}" ]] && [[ ${flg_DryRun} -ne 1 ]] && mkdir -p "${BkpDir}${tgt}"

				case "${ctlFlag}" in
				"B") # Backup only
					if [ "${flg_DryRun}" -ne 1 ]; then
						if [ "$USE_RSYNC" -eq 1 ]; then
							rsync -a "${pth}/${cfg_chk}" "${BkpDir}${tgt}"
						else
							cp -r "${pth}/${cfg_chk}" "${BkpDir}${tgt}"
						fi
					fi
					print_log -g "[copy backup]" -b " :: " "${pth}/${cfg_chk} --> ${BkpDir}${tgt}..."
					;;
				"O") # Overwrite
					if [ "${flg_DryRun}" -ne 1 ]; then
						if [ "$USE_RSYNC" -eq 1 ]; then
							rsync -a --remove-source-files "${pth}/${cfg_chk}" "${BkpDir}${tgt}"
						else
							mv "${pth}/${cfg_chk}" "${BkpDir}${tgt}"
						fi
						if [ "$USE_RSYNC" -eq 1 ]; then
							rsync -a "${CfgDir}${tgt}/${cfg_chk}" "${pth}"
						else
							cp -r "${CfgDir}${tgt}/${cfg_chk}" "${pth}"
						fi
					fi
					print_log -r "[move to backup]" " > " -r "[overwrite]" -b " :: " "${pth}" -r " <-- " "${CfgDir}${tgt}/${cfg_chk}"
					;;
				"S") # Sync
					if [ "${flg_DryRun}" -ne 1 ]; then
						if [ "$USE_RSYNC" -eq 1 ]; then
							rsync -a "${pth}/${cfg_chk}" "${BkpDir}${tgt}"
							rsync -a "${CfgDir}${tgt}/${cfg_chk}" "${pth}"
						else
							cp -r "${pth}/${cfg_chk}" "${BkpDir}${tgt}"
							cp -rf "${CfgDir}${tgt}/${cfg_chk}" "${pth}"
						fi
					fi
					print_log -g "[copy to backup]" " > " -y "[sync]" -b " :: " "${pth}" -r " <--  " "${CfgDir}${tgt}/${cfg_chk}"
					;;
				"P") # Preserve
					if [ "${flg_DryRun}" -ne 1 ]; then
						if [ "$USE_RSYNC" -eq 1 ]; then
							rsync -a "${pth}/${cfg_chk}" "${BkpDir}${tgt}"
							rsync -a --ignore-existing "${CfgDir}${tgt}/${cfg_chk}" "${pth}" 2>/dev/null
						else
							cp -r "${pth}/${cfg_chk}" "${BkpDir}${tgt}"
							cp -rn "${CfgDir}${tgt}/${cfg_chk}" "${pth}" 2>/dev/null
						fi
					fi
					if [ "$USE_RSYNC" -eq 1 ]; then
						if [ $? -eq 0 ]; then
							print_log -g "[copy to backup]" " > " -y "[populate]" -b " :: " "${pth}${tgt}/${cfg_chk}"
						else
							print_log -g "[copy to backup]" " > " -y "[preserved]" -b " :: " "${pth}" + 208 " <--  " "${CfgDir}${tgt}/${cfg_chk}"
						fi
					else
						if ! [ "${flg_DryRun}" -ne 1 ] && cp -rn "${CfgDir}${tgt}/${cfg_chk}" "${pth}" 2>/dev/null; then
							print_log -g "[copy to backup]" " > " -y "[populate]" -b " :: " "${pth}${tgt}/${cfg_chk}"
						else
							print_log -g "[copy to backup]" " > " -y "[preserved]" -b " :: " "${pth}" + 208 " <--  " "${CfgDir}${tgt}/${cfg_chk}"
						fi
					fi
					;;
				esac
			else
				if [ "${ctlFlag}" != "B" ]; then
					[ "${flg_DryRun}" -ne 1 ] && cp -r "${CfgDir}${tgt}/${cfg_chk}" "${pth}"
					print_log -y "[*populate*]" -b " :: " "${pth}" -r " <--  " "${CfgDir}${tgt}/${cfg_chk}"
				fi
			fi

		done

	done <"${1}"
}

ensure_hyq() {
	# Check if hyq is already available
	if command -v hyq >/dev/null 2>&1 && [ -x "$(command -v hyq)" ]; then
		return 0
	fi

	print_log -y "[hook] " -b "hyprland :: " "'hyq' not found in PATH, trying package install..."

	# Try pm.sh or pacmanCmd if available
	if [[ -x "${pacmanCmd}" ]]; then
		"${pacmanCmd}" install --no-confirm hyprquery || "${pacmanCmd}" install --no-confirm hyprquery-git
	fi

	# Check again if hyq is now available
	if command -v hyq >/dev/null 2>&1 && [ -x "$(command -v hyq)" ]; then
		return 0
	fi

	print_log -r "[error] :: " "Required executable 'hyq' is not available. Install 'hyprquery-git' (or 'hyprquery')."
	return 1
}

hyprland_hook() {

	local hyde_config="${cloneDir}/Configs/.config/hypr/hyprland.conf"
	local hyprland_default_config="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland.conf"
	local hyq_exec

	ensure_hyq || return 1
	hyq_exec="$(command -v hyq 2>/dev/null || true)"

	if ! "${hyq_exec}" "${hyprland_default_config}" --query "\$HYDE_HYPRLAND"; then
		mkdir -p "$(dirname "${hyprland_default_config}")" "${BkpDir}/.config/hypr"
		print_log -g "[hook] " -b "hyprland :: " "No HYDE_HYPRLAND variable found in ${hyprland_default_config}, restoring default HyDE marker..."

		if [[ ${flg_DryRun} -ne 1 && -f "${hyprland_default_config}" ]]; then
			cp -f "${hyprland_default_config}" "${BkpDir}/.config/hypr/hyprland.conf"
		fi

		print_log -r "[backup] :: " "${hyprland_default_config} to ${BkpDir}/.config/hypr/hyprland.conf"
		[[ ${flg_DryRun} -ne 1 ]] && cp -f "${hyde_config}" "${hyprland_default_config}"
		print_log -g "[restore] :: " "${hyde_config} to ${hyprland_default_config}"
	fi
}


uv_hook() {
	print_log -g "[uv]" -b " :: " "Checking uv availability..."
	if command -v uv &>/dev/null; then
		return 0
	fi
	print_log -warn "[uv]" "uv not found, installing..."
	if [[ -x "${pacmanCmd}" ]]; then
		"${pacmanCmd}" install --no-confirm uv || true
	elif command -v pacman &>/dev/null; then
		sudo pacman -S --noconfirm uv || true
	else
		curl -LsSf https://astral.sh/uv/install.sh | sh
		# shellcheck disable=SC1091
		source "$HOME/.local/bin/env" 2>/dev/null || true
		# Ensure uv is available after installation
		if ! command -v uv &>/dev/null; then
			export PATH="$HOME/.local/bin:$PATH"
		fi
	fi
}

# shellcheck disable=SC2034
log_section="deploy"
flg_DryRun=${flg_DryRun:-0}

scrDir=$(dirname "$(realpath "$0")")
if ! source "${scrDir}/global_fn.sh"; then
	echo "Error: unable to source global_fn.sh..."
	exit 1
fi

[ -f "${scrDir}/restore_cfg.lst" ] && defaultLst="restore_cfg.lst"
[ -f "${scrDir}/restore_cfg.psv" ] && defaultLst="restore_cfg.psv"
[ -f "${scrDir}/restore_cfg.json" ] && defaultLst="restore_cfg.json"
[ -f "${scrDir}/${USER}-restore_cfg.psv" ] && defaultLst="$USER-restore_cfg.psv"

CfgLst="${1:-"${scrDir}/${defaultLst}"}"
CfgDir="${2:-${cloneDir}/Configs}"
ThemeOverride="${3:-}"

if [ ! -f "${CfgLst}" ] || [ ! -d "${CfgDir}" ]; then
	echo "ERROR: '${CfgLst}' or '${CfgDir}' does not exist..."
	exit 1
fi

BkpDir="${HOME}/.config/cfg_backups/$(date +'%y%m%d_%Hh%Mm%Ss')${ThemeOverride}"

if [ -d "${BkpDir}" ]; then
	echo "ERROR: ${BkpDir} exists!"
	exit 1
else
	[[ ${flg_DryRun} -ne 1 ]] && mkdir -p "${BkpDir}"
fi

file_extension="${CfgLst##*.}"
echo ""
print_log -g "[file extension]" -b " :: " "${file_extension}"
case "${file_extension}" in
"lst")
	deploy_list "${CfgLst}"
	;;
"psv")
	deploy_psv "${CfgLst}"
	;;
json)
	deploy_json "${CfgLst}"
	;;
esac
echo ""

hyprland_hook

uv_hook

print_log -g "[python env]" -b " :: " "Rebuilding HyDE Python environment..."
if command -v hyde-shell >/dev/null 2>&1; then
	hyde-shell pyinit
else
	"${HOME}/.local/bin/hyde-shell" pyinit
fi

print_log -g "[version]" -b " :: " "saving version info..."
"${scrDir}/version.sh" --cache || echo "Failed to save version info."

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hyde"
clone_dir=$(git rev-parse --show-toplevel 2>/dev/null || echo "${HOME}/HyDE")
[[ -f ${clone_dir}/CHANGELOG.md ]] && cp -f "${clone_dir}/CHANGELOG.md" "${state_dir}/CHANGELOG.md"

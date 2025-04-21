#!/usr/bin/env bash
#|---/ /+------------------------------+---/ /|#
#|--/ /-| Script to patch custom theme |--/ /-|#
#|-/ /--| kRHYME7                      |-/ /--|#
#|/ /---+------------------------------+/ /---|#

script_dir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
# if [ $? -ne 0 ]; then
if ! source "${script_dir}/globalcontrol.sh"; then
    echo "Error: unable to source globalcontrol.sh..."
    exit 1
fi

export VERBOSE="${4}"
set +e

# error function
ask_help() {
    cat <<HELP
Usage:
    $(print_log "$0 " -y "Theme-Name " -c "/Path/to/Configs")
    $(print_log "$0 " -y "Theme-Name " -c "https://github.com/User/Repository")
    $(print_log "$0 " -y "Theme-Name " -c "https://github.com/User/Repository/tree/branch")

Envs:
    'export FULL_THEME_UPDATE=true'       Overwrites the archived files (useful for updates and changes in archives)

Supported Archive Format:
    | File prefix        | Hyprland variable | Target Directory                |
    | ---------------    | ----------------- | --------------------------------|
    | Gtk_               | \$GTK_THEME        | \$HOME/.local/share/themes     |
    | Icon_              | \$ICON_THEME       | \$HOME/.local/share/icons      |
    | Cursor_            | \$CURSOR_THEME     | \$HOME/.local/share/icons      |
    | Sddm_              | \$SDDM_THEME       | /usr/share/sddm/themes         |
    | Font_              | \$FONT             | \$HOME/.local/share/fonts      |
    | Document-Font_     | \$DOCUMENT_FONT    | \$HOME/.local/share/fonts      |
    | Monospace-Font_    | \$MONOSPACE_FONT   | \$HOME/.local/share/fonts      |
    | Notification-Font_ | \$NOTIFICATION_FONT | \$HOME/.local/share/fonts  |
    | Bar-Font_          | \$BAR_FONT         | \$HOME/.local/share/fonts      |
    | Menu-Font_         | \$MENU_FONT        | \$HOME/.local/share/fonts      |

Note:
    Target directories without enough permissions will be skipped.
        run 'sudo chmod -R 777 <target directory>'
            example: 'sudo chmod -R 777 /usr/share/sddm/themes'
HELP
}

if [[ -z $1 || -z $2 ]]; then
    ask_help
    exit 1
fi

WALLBASH_DIRS=(
    "${XDG_CONFIG_HOME:-$HOME.config}/hyde/wallbash"
    "${XDG_DATA_HOME:-$HOME/.local/share}/hyde/wallbash"
    "/usr/local/share/hyde/wallbash"
    "/usr/share/hyde/wallbash"
)

# set parameters
THEME_NAME="$1"

if [ -d "$2" ]; then
    THEME_DIR="$2"
else
    git_repo=${2%/}
    if echo "$git_repo" | grep -q "/tree/"; then
        branch=${git_repo#*tree/}
        git_repo=${git_repo%/tree/*}
    else
        branches_array=$(curl -s "https://api.github.com/repos/${git_repo#*://*/}/branches" | jq -r '.[].name')
        # shellcheck disable=SC2206
        branches_array=($branches_array)
        if [[ ${#branches_array[@]} -le 1 ]]; then
            branch=${branches_array[0]}
        else
            echo "Select a Branch"
            select branch in "${branches_array[@]}"; do
                [[ -n $branch ]] && break || echo "Invalid selection. Please try again."
            done
        fi
    fi

    git_path=${git_repo#*://*/}
    git_owner=${git_path%/*}
    git_theme=${git_path#*/}
    branch_dir=${branch//\//_}
    cache_dir="${XDG_CACHE_HOME:-"$HOME/.cache"}/hyde"
    dir_suffix=${git_owner}-${branch_dir}-${git_theme}
    dir_suffix=${dir_suffix//[ \/]/_}
    THEME_DIR="${cache_dir}/themepatcher/${dir_suffix}"

    if [ -d "$THEME_DIR" ]; then
        print_log "Directory $THEME_DIR" -y " already exists. Using existing directory."
        if cd "$THEME_DIR"; then
            git fetch --all &>/dev/null
            git reset --hard "@{upstream}" &>/dev/null
            cd - &>/dev/null || exit
        else
            print_log -y "Could not navigate to $THEME_DIR. Skipping git pull."
        fi
    else
        print_log "Directory $THEME_DIR does not exist. Cloning repository into new directory."
        if ! git clone -b "$branch" --depth 1 "$git_repo" "$THEME_DIR" &>/dev/null; then
            print_log "Git clone failed"
            exit 1
        fi
    fi
fi

print_log "Patching" -g " --// ${THEME_NAME} //-- " "from " -b "${THEME_DIR}\n"

FAV_THEME_DIR="${THEME_DIR}/Configs/.config/hyde/themes/${THEME_NAME}"
[ ! -d "${FAV_THEME_DIR}" ] && print_log -r "[ERROR] " "'${FAV_THEME_DIR}'" -y " Do not Exist" && exit 1

# config=$(find "${dcolDir}" -type f -name "*.dcol" | awk -v favTheme="${THEME_NAME}" -F 'theme/' '{gsub(/\.dcol$/, ".theme"); print ".config/hyde/themes/" favTheme "/" $2}')
config=$(find "${WALLBASH_DIRS[@]}" -type f -path "*/theme*" -name "*.dcol" 2>/dev/null | awk '!seen[substr($0, match($0, /[^/]+$/))]++' | awk -v favTheme="${THEME_NAME}" -F 'theme/' '{gsub(/\.dcol$/, ".theme"); print ".config/hyde/themes/" favTheme "/" $2}')
restore_list=""

while IFS= read -r fileCheck; do
    if [[ -e "${THEME_DIR}/Configs/${fileCheck}" ]]; then
        print_log -g "[pass]  " "${fileCheck}"
        file_base=$(basename "${fileCheck}")
        file_dir=$(dirname "${fileCheck}")
        restore_list+="Y|Y|\${HOME}/${file_dir}|${file_base}|hyprland\n"
    else
        print_log -y "[note] " "${fileCheck} --> " -r "do not exist in " "${THEME_DIR}/Configs/"
    fi
done <<<"$config"
if [ -f "${FAV_THEME_DIR}/theme.dcol" ]; then
    print_log -n "[note] " "found theme.dcol to override wallpaper dominant colors"
    restore_list+="Y|Y|\${HOME}/.config/hyde/themes/${THEME_NAME}|theme.dcol|hyprland\n"
fi
readonly restore_list

# Get Wallpapers
wallpapers=$(
    find "${FAV_THEME_DIR}" -type f \( -iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) ! -path "*/logo/*"
)
wpCount="$(wc -l <<<"${wallpapers}")"
{ [ -z "${wallpapers}" ] && print_log -r "[ERROR] " "No wallpapers found" && exit_flag=true; } || { readonly wallpapers && print_log -g "\n[pass]  " "wallpapers :: [count] ${wpCount} (.gif+.jpg+.jpeg+.png)"; }

# Get logos
if [ -d "${FAV_THEME_DIR}/logo" ]; then
    logos=$(
        find "${FAV_THEME_DIR}/logo" -type f \( -iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \)
    )
    logosCount="$(wc -l <<<"${logos}")"
    { [ -z "${logos}" ] && print_log -y "[note] " "No logos found"; } || { readonly logos && print_log -g "[pass]  " "logos :: [count] ${logosCount}\n"; }
fi

# parse thoroughly 😁
check_tars() {
    local trVal
    local inVal="${1}"
    local gsLow
    local gsVal
    gsLow=$(echo "${inVal}" | tr '[:upper:]' '[:lower:]')
    # Use hyprland variables that are set in the hypr.theme file
    # Using case we can have a predictable output
    gsVal="$(
        case "${gsLow}" in
        sddm)
            grep "^[[:space:]]*\$SDDM[-_]THEME\s*=" "${FAV_THEME_DIR}/hypr.theme" | cut -d '=' -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
            ;;
        gtk)
            grep "^[[:space:]]*\$GTK[-_]THEME\s*=" "${FAV_THEME_DIR}/hypr.theme" | cut -d '=' -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
            ;;
        icon)
            grep "^[[:space:]]*\$ICON[-_]THEME\s*=" "${FAV_THEME_DIR}/hypr.theme" | cut -d '=' -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
            ;;
        cursor)
            grep "^[[:space:]]*\$CURSOR[-_]THEME\s*=" "${FAV_THEME_DIR}/hypr.theme" | cut -d '=' -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
            ;;
        font)
            grep "^[[:space:]]*\$FONT\s*=" "${FAV_THEME_DIR}/hypr.theme" | cut -d '=' -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
            ;;
        document-font)
            grep "^[[:space:]]*\$DOCUMENT[-_]FONT\s*=" "${FAV_THEME_DIR}/hypr.theme" | cut -d '=' -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
            ;;
        monospace-font)
            grep "^[[:space:]]*\$MONOSPACE[-_]FONT\s*=" "${FAV_THEME_DIR}/hypr.theme" | cut -d '=' -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
            ;;
        bar-font)
            grep "^[[:space:]]*\$BAR[-_]FONT\s*=" "${FAV_THEME_DIR}/hypr.theme" | cut -d '=' -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
            ;;
        menu-font)
            grep "^[[:space:]]*\$MENU[-_]FONT\s*=" "${FAV_THEME_DIR}/hypr.theme" | cut -d '=' -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
            ;;
        notification-font)
            grep "^[[:space:]]*\$NOTIFICATION[-_]FONT\s*=" "${FAV_THEME_DIR}/hypr.theme" | cut -d '=' -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
            ;;

        *) # fallback to older method
            awk -F"[\"']" '/^[[:space:]]*exec[[:space:]]*=[[:space:]]*gsettings[[:space:]]*set[[:space:]]*org.gnome.desktop.interface[[:space:]]*'"${gsLow}"'-theme[[:space:]]*/ {last=$2} END {print last}' "${FAV_THEME_DIR}/hypr.theme"
            ;;
        esac
    )"

    # fallback to older method
    gsVal=${gsVal:-$(awk -F"[\"']" '/^[[:space:]]*exec[[:space:]]*=[[:space:]]*gsettings[[:space:]]*set[[:space:]]*org.gnome.desktop.interface[[:space:]]*'"${gsLow}"'-theme[[:space:]]*/ {last=$2} END {print last}' "${FAV_THEME_DIR}/hypr.theme")}

    if [ -n "${gsVal}" ]; then

        if [[ "${gsVal}" =~ ^\$\{?[A-Za-z_][A-Za-z0-9_]*\}?$ ]]; then # check is a variable is set into a variable eg $FONT=$DOCUMENT_FONT
            print_log -warn "Variable ${gsVal} detected! " "be sure ${gsVal} is set as a different name or on a different file, skipping check"
        else
            print_log -g "[pass]  " "hypr.theme :: [${gsLow}]" -b " ${gsVal}"
            trArc="$(find "${THEME_DIR}" -type f -name "${inVal}_*.tar.*")"
            [ -f "${trArc}" ] && [ "$(echo "${trArc}" | wc -l)" -eq 1 ] && trVal="$(basename "$(tar -tf "${trArc}" | cut -d '/' -f1 | sort -u)")" && trVal="$(echo "${trVal}" | grep -w "${gsVal}")"
            print_log -g "[pass]  " "../*.tar.* :: [${gsLow}]" -b " ${trVal}"
            [ "${trVal}" != "${gsVal}" ] && print_log -r "[ERROR] " "${gsLow} set in hypr.theme does not exist in ${inVal}_*.tar.*" && exit_flag=true
        fi
    else
        [ "${2}" == "--mandatory" ] && print_log -r "[ERROR] " "hypr.theme :: [${gsLow}]" -r " Not Found" && exit_flag=true && return 0
        print_log -y "[note] " "hypr.theme :: [${gsLow}] " -r "Not Found, " -y "📣 OPTIONAL package, continuing... "
    fi
}

check_tars Gtk --mandatory
check_tars Icon
check_tars Cursor
check_tars Sddm
check_tars Font
check_tars Document-Font
check_tars Monospace-Font
check_tars Bar-Font
check_tars Menu-Font
check_tars Notification-Font
print_log "" && [[ "${exit_flag}" = true ]] && exit 1

# extract arcs
declare -A archive_map=(
    ["Gtk"]="${HOME}/.local/share/themes"
    ["Icon"]="${HOME}/.local/share/icons"
    ["Cursor"]="${HOME}/.local/share/icons"
    ["Sddm"]="/usr/share/sddm/themes"
    ["Font"]="${HOME}/.local/share/fonts"
    ["Document-Font"]="${HOME}/.local/share/fonts"
    ["Monospace-Font"]="${HOME}/.local/share/fonts"
    ["Bar-Font"]="${HOME}/.local/share/fonts"
    ["Menu-Font"]="${HOME}/.local/share/fonts"
    ["Notification-Font"]="${HOME}/.local/share/fonts"
)

for prefix in "${!archive_map[@]}"; do
    tarFile="$(find "${THEME_DIR}" -type f -name "${prefix}_*.tar.*")"
    [ -f "${tarFile}" ] || continue
    tgtDir="${archive_map[$prefix]}"

    if [[ "${tgtDir}" =~ /(usr|usr\/local)\/share/ && -d /run/current-system/sw/share/ ]]; then
        print_log -y "Detected NixOS system, changing target to /run/current-system/sw/share/..."
        tgtDir="/run/current-system/sw/share/"
    fi

    if [ ! -d "${tgtDir}" ]; then
        if ! mkdir -p "${tgtDir}"; then
            print_log -y "Creating directory as root instead..."
            sudo mkdir -p "${tgtDir}"
        fi
    fi

    tgtChk="$(basename "$(tar -tf "${tarFile}" | cut -d '/' -f1 | sort -u)")"
    [[ "${FULL_THEME_UPDATE}" = true ]] || { [ -d "${tgtDir}/${tgtChk}" ] && print_log -y "[skip] " "\"${tgtDir}/${tgtChk}\"" -y " already exists" && continue; }
    print_log -g "[extracting] " "${tarFile} --> ${tgtDir}"

    if [ -w "${tgtDir}" ]; then
        tar -xf "${tarFile}" -C "${tgtDir}"
    else
        print_log -y "Not writable. Extracting as root: ${tgtDir}"
        if ! sudo tar -xf "${tarFile}" -C "${tgtDir}" 2>/dev/null; then
            print_log -r "Extraction by root FAILED. Giving up..."
            print_log "The above error can be ignored if the '${tgtDir}' is not writable..."
        fi
    fi

done

confDir=${XDG_CONFIG_HOME:-"$HOME/.config"}

# populate wallpaper
theme_wallpapers="${confDir}/hyde/themes/${THEME_NAME}/wallpapers"
[ ! -d "${theme_wallpapers}" ] && mkdir -p "${theme_wallpapers}"
while IFS= read -r walls; do
    cp -f "${walls}" "${theme_wallpapers}"
done <<<"${wallpapers}"

# populate logos
theme_logos="${confDir}/hyde/themes/${THEME_NAME}/logo"
if [ -n "${logos}" ]; then
    [ ! -d "${theme_logos}" ] && mkdir -p "${theme_logos}"
    while IFS= read -r logo; do
        if [ -f "${logo}" ]; then
            cp -f "${logo}" "${theme_logos}"
        else
            print_log -y "[note] " "${logo} --> do not exist"
        fi
    done <<<"${logos}"
fi

# restore configs with theme override
echo -en "${restore_list}" >"${THEME_DIR}/restore_cfg.lst"
print_log -g "\n[exec] " "restore.config.sh \"${THEME_DIR}/restore_cfg.lst\" \"${THEME_DIR}/Configs\" \"${THEME_NAME}\"\n"
bash "${script_dir}/restore.config.sh" "${THEME_DIR}/restore_cfg.lst" "${THEME_DIR}/Configs" "${THEME_NAME}" &>/dev/null || {
    print_log -r "[ERROR] " "restore.config.sh failed"
    exit 1
}
if [ "${3}" != "--skipcaching" ]; then
    bash "${script_dir}/swwwallcache.sh" -t "${THEME_NAME}"
    bash "${script_dir}/theme.switch.sh"
fi

print_log -y "\nNote: " "Warnings are not errors. Review the output to check if it concerns you."

exit 0

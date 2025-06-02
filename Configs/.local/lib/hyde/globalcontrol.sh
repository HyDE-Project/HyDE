#!/usr/bin/env bash
# shellcheck disable=SC1091

# xdg resolution
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
# ! export XDG_DATA_DIRS="$XDG_DATA_HOME/hyde:/usr/local/share/hyde/:/usr/share/hyde/:$XDG_DATA_DIRS" # Causes issues https://github.com/HyDE-Project/HyDE/issues/308#issuecomment-2691229673

# hyde envs
export HYDE_CONFIG_HOME="${XDG_CONFIG_HOME}/hyde"
export HYDE_DATA_HOME="${XDG_DATA_HOME}/hyde"
export HYDE_CACHE_HOME="${XDG_CACHE_HOME}/hyde"
export HYDE_STATE_HOME="${XDG_STATE_HOME}/hyde"
export HYDE_RUNTIME_DIR="${XDG_RUNTIME_DIR}/hyde"
export ICONS_DIR="${XDG_DATA_HOME}/icons"
export FONTS_DIR="${XDG_DATA_HOME}/fonts"
export THEMES_DIR="${XDG_DATA_HOME}/themes"

#legacy hyde envs // should be deprecated

export confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
export hydeConfDir="$HYDE_CONFIG_HOME"
export cacheDir="$HYDE_CACHE_HOME"
export thmbDir="$HYDE_CACHE_HOME/thumbs"
export dcolDir="$HYDE_CACHE_HOME/dcols"
export iconsDir="$ICONS_DIR"
export themesDir="$THEMES_DIR"
export fontsDir="$FONTS_DIR"
export hashMech="sha1sum"

print_log() {
    # [ -t 1 ] && return 0 # Skip if not in the terminal
    while (("$#")); do
        # [ "${colored}" == "true" ]
        case "$1" in
        -r | +r)
            echo -ne "\e[31m$2\e[0m" >&2
            shift 2
            ;; # Red
        -g | +g)
            echo -ne "\e[32m$2\e[0m" >&2
            shift 2
            ;; # Green
        -y | +y)
            echo -ne "\e[33m$2\e[0m" >&2
            shift 2
            ;; # Yellow
        -b | +b)
            echo -ne "\e[34m$2\e[0m" >&2
            shift 2
            ;; # Blue
        -m | +m)
            echo -ne "\e[35m$2\e[0m" >&2
            shift 2
            ;; # Magentass
        -c | +c)
            echo -ne "\e[36m$2\e[0m" >&2
            shift 2
            ;; # Cyan
        -wt | +w)
            echo -ne "\e[37m$2\e[0m" >&2
            shift 2
            ;; # White
        -n | +n)
            echo -ne "\e[96m$2\e[0m" >&2
            shift 2
            ;; # Neon
        -stat)
            echo -ne "\e[4;30;46m $2 \e[0m :: " >&2
            shift 2
            ;; # status
        -crit)
            echo -ne "\e[30;41m $2 \e[0m :: " >&2
            shift 2
            ;; # critical
        -warn)
            echo -ne "WARNING :: \e[30;43m $2 \e[0m :: " >&2
            shift 2
            ;; # warning
        +)
            echo -ne "\e[38;5;$2m$3\e[0m" >&2
            shift 3
            ;; # Set color manually
        -sec)
            echo -ne "\e[32m[$2] \e[0m" >&2
            shift 2
            ;; # section use for logs
        -err)
            echo -ne "ERROR :: \e[4;31m$2 \e[0m" >&2
            shift 2
            ;; #error
        *)
            echo -ne "$1" >&2
            shift
            ;;
        esac
    done
    echo "" >&2
}

get_hashmap() {
    unset wallHash
    unset wallList
    unset skipStrays
    unset filetypes

    list_extensions() {
        # Define supported file extensions
        supported_files=(
            "gif"
            "jpg"
            "jpeg"
            "png"
            "${WALLPAPER_FILETYPES[@]}"
        )
        if [ -n "${WALLPAPER_OVERRIDE_FILETYPES}" ]; then
            supported_files=("${WALLPAPER_OVERRIDE_FILETYPES[@]}")
        fi

        printf -- "-iname \"*.%s\" -o " "${supported_files[@]}" | sed 's/ -o $//'

    }

    find_wallpapers() {
        local wallSource="$1"

        if [ -z "${wallSource}" ]; then
            print_log -err "ERROR: wallSource is empty"
            return 1
        fi

        local find_command
        find_command="find \"${wallSource}\" -type f \\( $(list_extensions) \\) ! -path \"*/logo/*\" -exec \"${hashMech}\" {} +"

        [ "${LOG_LEVEL}" == "debug" ] && print_log -g "DEBUG:" -b "Running command:" "${find_command}"

        tmpfile=$(mktemp)
        eval "${find_command}" 2>"$tmpfile" | sort -k2
        error_output=$(<"$tmpfile") && rm -f "$tmpfile"
        [ -n "${error_output}" ] && print_log -err "ERROR:" -b "found an error: " -r "${error_output}" -y " skipping..."

    }

    for wallSource in "$@"; do

        [ "${LOG_LEVEL}" == "debug" ] && print_log -g "DEBUG:" -b "arg:" "${wallSource}"

        [ -z "${wallSource}" ] && continue
        [ "${wallSource}" == "--no-notify" ] && no_notify=1 && continue
        [ "${wallSource}" == "--skipstrays" ] && skipStrays=1 && continue
        [ "${wallSource}" == "--verbose" ] && verboseMap=1 && continue

        wallSource="$(realpath "${wallSource}")"

        [ -e "${wallSource}" ] || {
            print_log -err "ERROR:" -b "wallpaper source does not exist:" "${wallSource}" -y " skipping..."
            continue
        }

        [ "${LOG_LEVEL}" == "debug" ] && print_log -g "DEBUG:" -b "wallSource path:" "${wallSource}"

        hashMap=$(find_wallpapers "${wallSource}") # Enable debug mode for testing

        # hashMap=$(
        # find "${wallSource}" -type f \( -iname "*.gif" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.mkv"  \) ! -path "*/logo/*" -exec "${hashMech}" {} + | sort -k2
        # )

        if [ -z "${hashMap}" ]; then
            no_wallpapers+=("${wallSource}")
            print_log -warn "No compatible wallpapers found in: " "${wallSource}"
            continue
        fi

        while read -r hash image; do
            wallHash+=("${hash}")
            wallList+=("${image}")
        done <<<"${hashMap}"
    done

    # Notify the list of directories without compatible wallpapers
    if [ "${#no_wallpapers[@]}" -gt 0 ]; then
        # [ -n "${no_notify}" ] && notify-send -a "HyDE Alert" "WARNING: No compatible wallpapers found in: ${no_wallpapers[*]}"
        print_log -warn "No compatible wallpapers found in:" "${no_wallpapers[*]}"
    fi

    if [ -z "${#wallList[@]}" ] || [[ "${#wallList[@]}" -eq 0 ]]; then
        if [[ "${skipStrays}" -eq 1 ]]; then
            return 1
        else
            echo "ERROR: No image found in any source"
            [ -n "${no_notify}" ] && notify-send -a "HyDE Alert" "WARNING: No compatible wallpapers found in: ${no_wallpapers[*]}"
            exit 1
        fi
    fi

    if [[ "${verboseMap}" -eq 1 ]]; then
        echo "// Hash Map //"
        for indx in "${!wallHash[@]}"; do
            echo ":: \${wallHash[${indx}]}=\"${wallHash[indx]}\" :: \${wallList[${indx}]}=\"${wallList[indx]}\""
        done
    fi
}

# shellcheck disable=SC2120
get_themes() {
    unset thmSortS
    unset thmListS
    unset thmWallS
    unset thmSort
    unset thmList
    unset thmWall

    while read -r thmDir; do
        local realWallPath
        realWallPath="$(readlink "${thmDir}/wall.set")"
        if [ ! -e "${realWallPath}" ]; then
            get_hashmap "${thmDir}" --skipstrays || continue
            echo "fixing link :: ${thmDir}/wall.set"
            ln -fs "${wallList[0]}" "${thmDir}/wall.set"
        fi
        [ -f "${thmDir}/.sort" ] && thmSortS+=("$(head -1 "${thmDir}/.sort")") || thmSortS+=("0")
        thmWallS+=("${realWallPath}")
        thmListS+=("${thmDir##*/}") # Use this instead of basename
    done < <(find "${HYDE_CONFIG_HOME}/themes" -mindepth 1 -maxdepth 1 -type d)

    while IFS='|' read -r sort theme wall; do
        thmSort+=("${sort}")
        thmList+=("${theme}")
        thmWall+=("${wall}")
    done < <(paste -d '|' <(printf "%s\n" "${thmSortS[@]}") <(printf "%s\n" "${thmListS[@]}") <(printf "%s\n" "${thmWallS[@]}") | sort -n -k 1 -k 2)
    #!  done < <(parallel --link echo "{1}\|{2}\|{3}" ::: "${thmSortS[@]}" ::: "${thmListS[@]}" ::: "${thmWallS[@]}" | sort -n -k 1 -k 2) # This is overkill and slow
    if [ "${1}" == "--verbose" ]; then
        echo "// Theme Control //"
        for indx in "${!thmList[@]}"; do
            echo -e ":: \${thmSort[${indx}]}=\"${thmSort[indx]}\" :: \${thmList[${indx}]}=\"${thmList[indx]}\" :: \${thmWall[${indx}]}=\"${thmWall[indx]}\""
        done
    fi
}

[ -f "${HYDE_RUNTIME_DIR}/environment" ] && source "${HYDE_RUNTIME_DIR}/environment"
[ -f "$HYDE_STATE_HOME/staterc" ] && source "$HYDE_STATE_HOME/staterc"
[ -f "$HYDE_STATE_HOME/config" ] && source "$HYDE_STATE_HOME/config"

case "${enableWallDcol}" in
0 | 1 | 2 | 3) ;;
*) enableWallDcol=0 ;;
esac

if [ -z "${HYDE_THEME}" ] || [ ! -d "${HYDE_CONFIG_HOME}/themes/${HYDE_THEME}" ]; then
    get_themes
    HYDE_THEME="${thmList[0]}"
fi

HYDE_THEME_DIR="${HYDE_CONFIG_HOME}/themes/${HYDE_THEME}"
wallbashDirs=(
    "${HYDE_CONFIG_HOME}/wallbash"
    "${XDG_DATA_HOME}/hyde/wallbash"
    "/usr/local/share/hyde/wallbash"
    "/usr/share/hyde/wallbash"
)

export HYDE_THEME \
    HYDE_THEME_DIR \
    wallbashDirs \
    enableWallDcol

#// hypr vars

if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    hypr_border="$(hyprctl -j getoption decoration:rounding | jq '.int')"
    hypr_width="$(hyprctl -j getoption general:border_size | jq '.int')"

    export hypr_border=${hypr_border:-0}
    export hypr_width=${hypr_width:-0}
fi

#// extra fns

pkg_installed() {
    local pkgIn=$1
    if command -v "${pkgIn}" &>/dev/null; then
        return 0
    elif command -v "flatpak" &>/dev/null && flatpak info "${pkgIn}" &>/dev/null; then
        return 0
    elif hyde-shell pm.sh pq "${pkgIn}" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

get_aurhlpr() {
    if pkg_installed yay; then
        aurhlpr="yay"
    elif pkg_installed paru; then
        # shellcheck disable=SC2034
        aurhlpr="paru"
    fi
}

set_conf() {
    local varName="${1}"
    local varData="${2}"
    touch "${XDG_STATE_HOME}/hyde/staterc"

    if [ "$(grep -c "^${varName}=" "${XDG_STATE_HOME}/hyde/staterc")" -eq 1 ]; then
        sed -i "/^${varName}=/c${varName}=\"${varData}\"" "${XDG_STATE_HOME}/hyde/staterc"
    else
        echo "${varName}=\"${varData}\"" >>"${XDG_STATE_HOME}/hyde/staterc"
    fi
}

set_hash() {
    local hashImage="${1}"
    "${hashMech}" "${hashImage}" | awk '{print $1}'
}

check_package() {

    local lock_file="${XDG_RUNTIME_DIR:-/tmp}/hyde/__package.lock"
    mkdir -p "${XDG_RUNTIME_DIR:-/tmp}/hyde"

    if [ -f "$lock_file" ]; then
        return 0
    fi

    for pkg in "$@"; do
        if ! pkg_installed "${pkg}"; then
            print_log -err "Package is not installed" "'${pkg}'"
            rm -f "$lock_file"
            exit 1
        fi
    done

    touch "$lock_file"
}

# Yes this is so slow but it's the only way to ensure that parsing behaves correctly
get_hyprConf() {
    local hyVar="${1}"
    local file="${2:-"$HYDE_THEME_DIR/hypr.theme"}"

    # First try using hyq for fast config parsing if available
    if command -v hyq &>/dev/null; then
        local hyq_result
        # Try with source option for accurate results
        hyq_result=$(hyq -s --query "\$${hyVar}" "${file}" 2>/dev/null)
        # If empty, try without source option
        if [ -z "${hyq_result}" ]; then
            hyq_result=$(hyq --query "\$${hyVar}" "${file}" 2>/dev/null)
        fi
        # Return result if not empty
        [ -n "${hyq_result}" ] && echo "${hyq_result}" && return 0

    fi

    # Fall back to traditional parsing if hyq fails or isn't available
    local gsVal
    gsVal="$(grep "^[[:space:]]*\$${hyVar}\s*=" "${file}" | cut -d '=' -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -n "${gsVal}" ] && [[ "${gsVal}" != \$* ]] && echo "${gsVal}" && return 0
    declare -A gsMap=(
        [GTK_THEME]="gtk-theme"
        [ICON_THEME]="icon-theme"
        [COLOR_SCHEME]="color-scheme"
        [CURSOR_THEME]="cursor-theme"
        [CURSOR_SIZE]="cursor-size"
        [FONT]="font-name"
        [DOCUMENT_FONT]="document-font-name"
        [MONOSPACE_FONT]="monospace-font-name"
        [FONT_SIZE]="font-size"
        [DOCUMENT_FONT_SIZE]="document-font-size"
        [MONOSPACE_FONT_SIZE]="monospace-font-size"
        # [CODE_THEME]="Wallbash"
        # [SDDM_THEME]=""
    )

    # Try parse gsettings
    if [[ -n "${gsMap[$hyVar]}" ]]; then
        gsVal="$(awk -F"[\"']" '/^[[:space:]]*exec[[:space:]]*=[[:space:]]*gsettings[[:space:]]*set[[:space:]]*org.gnome.desktop.interface[[:space:]]*'"${gsMap[$hyVar]}"'[[:space:]]*/ {last=$2} END {print last}' "${file}")"
    fi

    if [ -z "${gsVal}" ] || [[ "${gsVal}" == \$* ]]; then
        case "${hyVar}" in
        "CODE_THEME") echo "Wallbash" ;;
        "SDDM_THEME") echo "" ;;
        *)
            grep "^[[:space:]]*\$default.${hyVar}\s*=" \
                "XDG_DATA_HOME/hyde/hyde.conf" \
                "$XDG_DATA_HOME/hyde/hyprland.conf" \
                "/usr/local/share/hyde/hyde.conf" \
                "/usr/local/share/hyde/hyprland.conf" \
                "/usr/share/hyde/hyde.conf" \
                "/usr/share/hyde/hyprland.conf" 2>/dev/null |
                cut -d '=' -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | head -n 1
            ;;
        esac
    else
        echo "${gsVal}"
    fi

}

# rofi spawn location
get_rofi_pos() {
    readarray -t curPos < <(hyprctl cursorpos -j | jq -r '.x,.y')
    eval "$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) |
        "monRes=(\(.width) \(.height) \(.scale) \(.x) \(.y)) offRes=(\(.reserved | join(" ")))"')"

    monRes[2]="${monRes[2]//./}"
    monRes[0]=$((monRes[0] * 100 / monRes[2]))
    monRes[1]=$((monRes[1] * 100 / monRes[2]))
    curPos[0]=$((curPos[0] - monRes[3]))
    curPos[1]=$((curPos[1] - monRes[4]))
    offRes=("${offRes// / }")

    if [ "${curPos[0]}" -ge "$((monRes[0] / 2))" ]; then
        local x_pos="east"
        local x_off="-$((monRes[0] - curPos[0] - offRes[2]))"
    else
        local x_pos="west"
        local x_off="$((curPos[0] - offRes[0]))"
    fi

    if [ "${curPos[1]}" -ge "$((monRes[1] / 2))" ]; then
        local y_pos="south"
        local y_off="-$((monRes[1] - curPos[1] - offRes[3]))"
    else
        local y_pos="north"
        local y_off="$((curPos[1] - offRes[1]))"
    fi

    local coordinates="window{location:${x_pos} ${y_pos};anchor:${x_pos} ${y_pos};x-offset:${x_off}px;y-offset:${y_off}px;}"
    echo "${coordinates}"
}

#? handle pasting
paste_string() {
    if ! command -v wtype >/dev/null; then exit 0; fi
    if [ -t 1 ]; then return 0; fi
    ignore_paste_file="$HYDE_STATE_HOME/ignore.paste"

    if [[ ! -e "${ignore_paste_file}" ]]; then
        cat <<EOF >"${ignore_paste_file}"
kitty
org.kde.konsole
terminator
XTerm
Alacritty
xterm-256color
EOF
    fi

    ignore_class=$(echo "$@" | awk -F'--ignore=' '{print $2}')
    [ -n "${ignore_class}" ] && echo "${ignore_class}" >>"${ignore_paste_file}" && print_log -y "[ignore]" "'$ignore_class'" && exit 0
    class=$(hyprctl -j activewindow | jq -r '.initialClass')
    if ! grep -q "${class}" "${ignore_paste_file}"; then
        hyprctl -q dispatch exec 'wtype -M ctrl V -m ctrl'
    fi
}

#? Checks if the cursor is hovered on a window
is_hovered() {
    data=$(hyprctl --batch -j "cursorpos;activewindow" | jq -s '.[0] * .[1]')
    # evaulate the output of the JSON data into shell variables
    eval "$(echo "$data" | jq -r '@sh "cursor_x=\(.x) cursor_y=\(.y) window_x=\(.at[0]) window_y=\(.at[1]) window_size_x=\(.size[0]) window_size_y=\(.size[1])"')"

    # Handle variables in case they are null
    cursor_x=${cursor_x:-$(jq -r '.x // 0' <<<"$data")}
    cursor_y=${cursor_y:-$(jq -r '.y // 0' <<<"$data")}
    window_x=${window_x:-$(jq -r '.at[0] // 0' <<<"$data")}
    window_y=${window_y:-$(jq -r '.at[1] // 0' <<<"$data")}
    window_size_x=${window_size_x:-$(jq -r '.size[0] // 0' <<<"$data")}
    window_size_y=${window_size_y:-$(jq -r '.size[1] // 0' <<<"$data")}
    # Check if the cursor is hovered in the active window
    if ((cursor_x >= window_x && cursor_x <= window_x + window_size_x && cursor_y >= window_y && cursor_y <= window_y + window_size_y)); then
        return 0
    fi
    return 1
}

toml_write() {
    # Use kwriteconfig6 to write to config files in toml format
    local config_file=$1
    local group=$2
    local key=$3
    local value=$4

    if ! kwriteconfig6 --file "${config_file}" --group "${group}" --key "${key}" "${value}" 2>/dev/null; then
        if ! grep -q "^\[${group}\]" "${config_file}"; then
            echo -e "\n[${group}]\n${key}=${value}" >>"${config_file}"
        elif ! grep -q "^${key}=" "${config_file}"; then
            sed -i "/^\[${group}\]/a ${key}=${value}" "${config_file}"
        fi
    fi
}

# Function to extract thumbnail from video
# shellcheck disable=SC2317
extract_thumbnail() {
    local x_wall="${1}"
    x_wall=$(realpath "${x_wall}")
    local temp_image="${2}"
    ffmpeg -y -i "${x_wall}" -vf "thumbnail,scale=1000:-1" -frames:v 1 -update 1 "${temp_image}" &>/dev/null
}

# Function to check if the file is supported by the wallpaper backend
accepted_mime_types() {
    local mime_types_array=${1}
    local file=${2}

    for mime_type in "${mime_types_array[@]}"; do
        if file --mime-type -b "${file}" | grep -q "^${mime_type}"; then
            return 0
        else
            print_log -err "File type not supported for this wallpaper backend."
            notify-send -u critical -a "HyDE-Alert" "File type not supported for this wallpaper backend."
        fi

    done

}

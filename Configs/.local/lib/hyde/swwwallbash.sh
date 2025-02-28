#!/usr/bin/env bash
# shellcheck disable=SC2154

#// set variables

scrDir="$(dirname "$(realpath "$0")")"
export scrDir
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"
wallbashImg="${1}"

# Parse arguments
dcol_colors=""
while [[ $# -gt 0 ]]; do
    case "$1" in
    --dcol)
        dcol_colors="$2"
        if [ -f "${dcol_colors}" ]; then
            echo "[Source] ${dcol_colors}"
            # shellcheck disable=SC1090
            source "${dcol_colors}"
            shift 2
        else
            dcol_colors="$(find "${dcolDir}" -type f -name "*.dcol" | shuf -n 1)"
            echo "[Dcol Colors] ${dcol_colors}"
            shift
        fi
        ;;
    --wall)
        wallbashImg="$2"
        shift 2
        ;;
    --single)
        [ -f "${wallbashImg}" ] || wallbashImg="${cacheDir}/wall.set"
        single_template="$2"
        echo "[wallbash] Single template: ${single_template}"
        echo "[wallbash] Wallpaper: ${wallbashImg}"
        shift 2
        #     ;;
        # --mode)
        #     enableWallDcol="$2"
        #     shift 2
        ;;
    -*)
        echo "Usage: $0 [--dcol <mode>] [--wall <image>] [--single] [--mode <mode>] [--help]"
        exit 0
        ;;
    *) break ;;
    esac
done

#// validate input

if [ -z "${wallbashImg}" ] || [ ! -f "${wallbashImg}" ]; then
    echo "Error: Input wallpaper not found!"
    exit 1
fi
# shellcheck disable=SC2154
wallbashOut="${dcolDir}/$(set_hash "${wallbashImg}").dcol"

if [ ! -f "${wallbashOut}" ]; then
    "${scrDir}/swwwallcache.sh" -w "${wallbashImg}" &>/dev/null
fi

set -a
# shellcheck disable=SC1090
source "${wallbashOut}"
# shellcheck disable=SC2154
if [ -f "${HYDE_THEME_DIR}/theme.dcol" ] && [ "${enableWallDcol}" -eq 0 ]; then
    # shellcheck disable=SC1091
    source "${HYDE_THEME_DIR}/theme.dcol"
    print_log -sec "wallbash" -stat "override" "dominant colors from ${HYDE_THEME} theme"
    print_log -sec "wallbash" -stat " NOTE" "Remove \"${HYDE_THEME_DIR}/theme.dcol\" to use wallpaper dominant colors"
fi
# shellcheck disable=SC2154
[ "${dcol_mode}" == "dark" ] && dcol_invt="light" || dcol_invt="dark"
set +a

if [ -z "$gtkTheme" ]; then
    if [ "${enableWallDcol}" -eq 0 ]; then
        gtkTheme="$(get_hyprConf "GTK_THEME")"
    else
        gtkTheme="Wallbash-Gtk"
    fi
fi
[ -z "$gtkIcon" ] && gtkIcon="$(get_hyprConf "ICON_THEME")"
[ -z "$cursorTheme" ] && cursorTheme="$(get_hyprConf "CURSOR_THEME")"
export gtkTheme gtkIcon cursorTheme

#// deploy wallbash colors

fn_wallbash() {
    local template="${1}"
    local temp_target_file exec_command
    WALLBASH_SCRIPTS="${template%%hyde/wallbash*}hyde/wallbash/scripts"
    if [[ "${template}" == *.theme ]]; then
        # This is approach is to handle the theme files
        # We don't want themes to launch the exec_command or any arbitrary codes
        # To enable this we should have a *.dcol file as a companion to the theme file
        IFS=':' read -r -a wallbashDirs <<<"$WALLBASH_DIRS"
        template_name="${template##*/}"
        template_name="${template_name%.*}"
        # echo "${wallbashDirs[@]}"
        dcolTemplate=$(find "${wallbashDirs[@]}" -type f -path "*/theme*" -name "${template_name}.dcol" 2>/dev/null | awk '!seen[substr($0, match($0, /[^/]+$/))]++')
        if [[ -n "${dcolTemplate}" ]]; then
            eval target_file="$(head -1 "${dcolTemplate}" | awk -F '|' '{print $1}')"
            exec_command="$(head -1 "${dcolTemplate}" | awk -F '|' '{print $2}')"
            WALLBASH_SCRIPTS="${dcolTemplate%%hyde/wallbash*}hyde/wallbash/scripts"

        fi
    fi

    # shellcheck disable=SC1091
    # shellcheck disable=SC2154
    [ -f "$HYDE_STATE_HOME/state" ] && source "$HYDE_STATE_HOME/state"
    # shellcheck disable=SC1091
    [ -f "$HYDE_STATE_HOME/config" ] && source "$HYDE_STATE_HOME/config"
    if [[ -n "${WALLBASH_SKIP_TEMPLATE[*]}" ]]; then
        for skip in "${WALLBASH_SKIP_TEMPLATE[@]}"; do
            if [[ "${template}" =~ ${skip} ]]; then
                print_log -sec "wallbash" -warn "skip '$skip' template " "Template: ${template}"
                return 0
            fi
        done
    fi

    [ -z "${target_file}" ] && eval target_file="$(head -1 "${template}" | awk -F '|' '{print $1}')"
    [ ! -d "$(dirname "${target_file}")" ] && print_log -sec "wallbash" -warn "skip 'missing directory'" "${target_file} // Do you have the dependency installed?" && return 0
    export wallbashScripts="${WALLBASH_SCRIPTS}"
    export WALLBASH_SCRIPTS confDir hydeConfDir cacheDir thmbDir dcolDir iconsDir themesDir fontsDir wallbashDirs enableWallDcol HYDE_THEME_DIR HYDE_THEME gtkIcon gtkTheme cursorTheme
    export -f pkg_installed print_log
    # exec_command="$(head -1 "${template}" | awk -F '|' '{print $2}')"
    exec_command="${exec_command:-"$(head -1 "${template}" | awk -F '|' '{print $2}')"}"
    temp_target_file="$(mktemp)"
    sed '1d' "${template}" >"${temp_target_file}"
    if [[ ${revert_colors} -eq 1 ]] || [[ "${enableWallDcol}" -eq 2 && "${dcol_mode}" == "light" ]] || [[ "${enableWallDcol}" -eq 3 && "${dcol_mode}" == "dark" ]]; then
        sed -i 's/<wallbash_mode>/'"${dcol_invt}"'/g
                s/<wallbash_pry1>/'"${dcol_pry4}"'/g
                s/<wallbash_txt1>/'"${dcol_txt4}"'/g
                s/<wallbash_1xa1>/'"${dcol_4xa9}"'/g
                s/<wallbash_1xa2>/'"${dcol_4xa8}"'/g
                s/<wallbash_1xa3>/'"${dcol_4xa7}"'/g
                s/<wallbash_1xa4>/'"${dcol_4xa6}"'/g
                s/<wallbash_1xa5>/'"${dcol_4xa5}"'/g
                s/<wallbash_1xa6>/'"${dcol_4xa4}"'/g
                s/<wallbash_1xa7>/'"${dcol_4xa3}"'/g
                s/<wallbash_1xa8>/'"${dcol_4xa2}"'/g
                s/<wallbash_1xa9>/'"${dcol_4xa1}"'/g
                s/<wallbash_pry2>/'"${dcol_pry3}"'/g
                s/<wallbash_txt2>/'"${dcol_txt3}"'/g
                s/<wallbash_2xa1>/'"${dcol_3xa9}"'/g
                s/<wallbash_2xa2>/'"${dcol_3xa8}"'/g
                s/<wallbash_2xa3>/'"${dcol_3xa7}"'/g
                s/<wallbash_2xa4>/'"${dcol_3xa6}"'/g
                s/<wallbash_2xa5>/'"${dcol_3xa5}"'/g
                s/<wallbash_2xa6>/'"${dcol_3xa4}"'/g
                s/<wallbash_2xa7>/'"${dcol_3xa3}"'/g
                s/<wallbash_2xa8>/'"${dcol_3xa2}"'/g
                s/<wallbash_2xa9>/'"${dcol_3xa1}"'/g
                s/<wallbash_pry3>/'"${dcol_pry2}"'/g
                s/<wallbash_txt3>/'"${dcol_txt2}"'/g
                s/<wallbash_3xa1>/'"${dcol_2xa9}"'/g
                s/<wallbash_3xa2>/'"${dcol_2xa8}"'/g
                s/<wallbash_3xa3>/'"${dcol_2xa7}"'/g
                s/<wallbash_3xa4>/'"${dcol_2xa6}"'/g
                s/<wallbash_3xa5>/'"${dcol_2xa5}"'/g
                s/<wallbash_3xa6>/'"${dcol_2xa4}"'/g
                s/<wallbash_3xa7>/'"${dcol_2xa3}"'/g
                s/<wallbash_3xa8>/'"${dcol_2xa2}"'/g
                s/<wallbash_3xa9>/'"${dcol_2xa1}"'/g
                s/<wallbash_pry4>/'"${dcol_pry1}"'/g
                s/<wallbash_txt4>/'"${dcol_txt1}"'/g
                s/<wallbash_4xa1>/'"${dcol_1xa9}"'/g
                s/<wallbash_4xa2>/'"${dcol_1xa8}"'/g
                s/<wallbash_4xa3>/'"${dcol_1xa7}"'/g
                s/<wallbash_4xa4>/'"${dcol_1xa6}"'/g
                s/<wallbash_4xa5>/'"${dcol_1xa5}"'/g
                s/<wallbash_4xa6>/'"${dcol_1xa4}"'/g
                s/<wallbash_4xa7>/'"${dcol_1xa3}"'/g
                s/<wallbash_4xa8>/'"${dcol_1xa2}"'/g
                s/<wallbash_4xa9>/'"${dcol_1xa1}"'/g
                s/<wallbash_pry1_rgba(\([^)]*\))>/'"${dcol_pry4_rgba}"'/g
                s/<wallbash_txt1_rgba(\([^)]*\))>/'"${dcol_txt4_rgba}"'/g
                s/<wallbash_1xa1_rgba(\([^)]*\))>/'"${dcol_4xa9_rgba}"'/g
                s/<wallbash_1xa2_rgba(\([^)]*\))>/'"${dcol_4xa8_rgba}"'/g
                s/<wallbash_1xa3_rgba(\([^)]*\))>/'"${dcol_4xa7_rgba}"'/g
                s/<wallbash_1xa4_rgba(\([^)]*\))>/'"${dcol_4xa6_rgba}"'/g
                s/<wallbash_1xa5_rgba(\([^)]*\))>/'"${dcol_4xa5_rgba}"'/g
                s/<wallbash_1xa6_rgba(\([^)]*\))>/'"${dcol_4xa4_rgba}"'/g
                s/<wallbash_1xa7_rgba(\([^)]*\))>/'"${dcol_4xa3_rgba}"'/g
                s/<wallbash_1xa8_rgba(\([^)]*\))>/'"${dcol_4xa2_rgba}"'/g
                s/<wallbash_1xa9_rgba(\([^)]*\))>/'"${dcol_4xa1_rgba}"'/g
                s/<wallbash_pry2_rgba(\([^)]*\))>/'"${dcol_pry3_rgba}"'/g
                s/<wallbash_txt2_rgba(\([^)]*\))>/'"${dcol_txt3_rgba}"'/g
                s/<wallbash_2xa1_rgba(\([^)]*\))>/'"${dcol_3xa9_rgba}"'/g
                s/<wallbash_2xa2_rgba(\([^)]*\))>/'"${dcol_3xa8_rgba}"'/g
                s/<wallbash_2xa3_rgba(\([^)]*\))>/'"${dcol_3xa7_rgba}"'/g
                s/<wallbash_2xa4_rgba(\([^)]*\))>/'"${dcol_3xa6_rgba}"'/g
                s/<wallbash_2xa5_rgba(\([^)]*\))>/'"${dcol_3xa5_rgba}"'/g
                s/<wallbash_2xa6_rgba(\([^)]*\))>/'"${dcol_3xa4_rgba}"'/g
                s/<wallbash_2xa7_rgba(\([^)]*\))>/'"${dcol_3xa3_rgba}"'/g
                s/<wallbash_2xa8_rgba(\([^)]*\))>/'"${dcol_3xa2_rgba}"'/g
                s/<wallbash_2xa9_rgba(\([^)]*\))>/'"${dcol_3xa1_rgba}"'/g
                s/<wallbash_pry3_rgba(\([^)]*\))>/'"${dcol_pry2_rgba}"'/g
                s/<wallbash_txt3_rgba(\([^)]*\))>/'"${dcol_txt2_rgba}"'/g
                s/<wallbash_3xa1_rgba(\([^)]*\))>/'"${dcol_2xa9_rgba}"'/g
                s/<wallbash_3xa2_rgba(\([^)]*\))>/'"${dcol_2xa8_rgba}"'/g
                s/<wallbash_3xa3_rgba(\([^)]*\))>/'"${dcol_2xa7_rgba}"'/g
                s/<wallbash_3xa4_rgba(\([^)]*\))>/'"${dcol_2xa6_rgba}"'/g
                s/<wallbash_3xa5_rgba(\([^)]*\))>/'"${dcol_2xa5_rgba}"'/g
                s/<wallbash_3xa6_rgba(\([^)]*\))>/'"${dcol_2xa4_rgba}"'/g
                s/<wallbash_3xa7_rgba(\([^)]*\))>/'"${dcol_2xa3_rgba}"'/g
                s/<wallbash_3xa8_rgba(\([^)]*\))>/'"${dcol_2xa2_rgba}"'/g
                s/<wallbash_3xa9_rgba(\([^)]*\))>/'"${dcol_2xa1_rgba}"'/g
                s/<wallbash_pry4_rgba(\([^)]*\))>/'"${dcol_pry1_rgba}"'/g
                s/<wallbash_txt4_rgba(\([^)]*\))>/'"${dcol_txt1_rgba}"'/g
                s/<wallbash_4xa1_rgba(\([^)]*\))>/'"${dcol_1xa9_rgba}"'/g
                s/<wallbash_4xa2_rgba(\([^)]*\))>/'"${dcol_1xa8_rgba}"'/g
                s/<wallbash_4xa3_rgba(\([^)]*\))>/'"${dcol_1xa7_rgba}"'/g
                s/<wallbash_4xa4_rgba(\([^)]*\))>/'"${dcol_1xa6_rgba}"'/g
                s/<wallbash_4xa5_rgba(\([^)]*\))>/'"${dcol_1xa5_rgba}"'/g
                s/<wallbash_4xa6_rgba(\([^)]*\))>/'"${dcol_1xa4_rgba}"'/g
                s/<wallbash_4xa7_rgba(\([^)]*\))>/'"${dcol_1xa3_rgba}"'/g
                s/<wallbash_4xa8_rgba(\([^)]*\))>/'"${dcol_1xa2_rgba}"'/g
                s/<wallbash_4xa9_rgba(\([^)]*\))>/'"${dcol_1xa1_rgba}"'/g' "${temp_target_file}"
    else
        sed -i 's/<wallbash_mode>/'"${dcol_mode}"'/g
                s/<wallbash_pry1>/'"${dcol_pry1}"'/g
                s/<wallbash_txt1>/'"${dcol_txt1}"'/g
                s/<wallbash_1xa1>/'"${dcol_1xa1}"'/g
                s/<wallbash_1xa2>/'"${dcol_1xa2}"'/g
                s/<wallbash_1xa3>/'"${dcol_1xa3}"'/g
                s/<wallbash_1xa4>/'"${dcol_1xa4}"'/g
                s/<wallbash_1xa5>/'"${dcol_1xa5}"'/g
                s/<wallbash_1xa6>/'"${dcol_1xa6}"'/g
                s/<wallbash_1xa7>/'"${dcol_1xa7}"'/g
                s/<wallbash_1xa8>/'"${dcol_1xa8}"'/g
                s/<wallbash_1xa9>/'"${dcol_1xa9}"'/g
                s/<wallbash_pry2>/'"${dcol_pry2}"'/g
                s/<wallbash_txt2>/'"${dcol_txt2}"'/g
                s/<wallbash_2xa1>/'"${dcol_2xa1}"'/g
                s/<wallbash_2xa2>/'"${dcol_2xa2}"'/g
                s/<wallbash_2xa3>/'"${dcol_2xa3}"'/g
                s/<wallbash_2xa4>/'"${dcol_2xa4}"'/g
                s/<wallbash_2xa5>/'"${dcol_2xa5}"'/g
                s/<wallbash_2xa6>/'"${dcol_2xa6}"'/g
                s/<wallbash_2xa7>/'"${dcol_2xa7}"'/g
                s/<wallbash_2xa8>/'"${dcol_2xa8}"'/g
                s/<wallbash_2xa9>/'"${dcol_2xa9}"'/g
                s/<wallbash_pry3>/'"${dcol_pry3}"'/g
                s/<wallbash_txt3>/'"${dcol_txt3}"'/g
                s/<wallbash_3xa1>/'"${dcol_3xa1}"'/g
                s/<wallbash_3xa2>/'"${dcol_3xa2}"'/g
                s/<wallbash_3xa3>/'"${dcol_3xa3}"'/g
                s/<wallbash_3xa4>/'"${dcol_3xa4}"'/g
                s/<wallbash_3xa5>/'"${dcol_3xa5}"'/g
                s/<wallbash_3xa6>/'"${dcol_3xa6}"'/g
                s/<wallbash_3xa7>/'"${dcol_3xa7}"'/g
                s/<wallbash_3xa8>/'"${dcol_3xa8}"'/g
                s/<wallbash_3xa9>/'"${dcol_3xa9}"'/g
                s/<wallbash_pry4>/'"${dcol_pry4}"'/g
                s/<wallbash_txt4>/'"${dcol_txt4}"'/g
                s/<wallbash_4xa1>/'"${dcol_4xa1}"'/g
                s/<wallbash_4xa2>/'"${dcol_4xa2}"'/g
                s/<wallbash_4xa3>/'"${dcol_4xa3}"'/g
                s/<wallbash_4xa4>/'"${dcol_4xa4}"'/g
                s/<wallbash_4xa5>/'"${dcol_4xa5}"'/g
                s/<wallbash_4xa6>/'"${dcol_4xa6}"'/g
                s/<wallbash_4xa7>/'"${dcol_4xa7}"'/g
                s/<wallbash_4xa8>/'"${dcol_4xa8}"'/g
                s/<wallbash_4xa9>/'"${dcol_4xa9}"'/g
                s/<wallbash_pry1_rgba(\([^)]*\))>/'"${dcol_pry1_rgba}"'/g
                s/<wallbash_txt1_rgba(\([^)]*\))>/'"${dcol_txt1_rgba}"'/g
                s/<wallbash_1xa1_rgba(\([^)]*\))>/'"${dcol_1xa1_rgba}"'/g
                s/<wallbash_1xa2_rgba(\([^)]*\))>/'"${dcol_1xa2_rgba}"'/g
                s/<wallbash_1xa3_rgba(\([^)]*\))>/'"${dcol_1xa3_rgba}"'/g
                s/<wallbash_1xa4_rgba(\([^)]*\))>/'"${dcol_1xa4_rgba}"'/g
                s/<wallbash_1xa5_rgba(\([^)]*\))>/'"${dcol_1xa5_rgba}"'/g
                s/<wallbash_1xa6_rgba(\([^)]*\))>/'"${dcol_1xa6_rgba}"'/g
                s/<wallbash_1xa7_rgba(\([^)]*\))>/'"${dcol_1xa7_rgba}"'/g
                s/<wallbash_1xa8_rgba(\([^)]*\))>/'"${dcol_1xa8_rgba}"'/g
                s/<wallbash_1xa9_rgba(\([^)]*\))>/'"${dcol_1xa9_rgba}"'/g
                s/<wallbash_pry2_rgba(\([^)]*\))>/'"${dcol_pry2_rgba}"'/g
                s/<wallbash_txt2_rgba(\([^)]*\))>/'"${dcol_txt2_rgba}"'/g
                s/<wallbash_2xa1_rgba(\([^)]*\))>/'"${dcol_2xa1_rgba}"'/g
                s/<wallbash_2xa2_rgba(\([^)]*\))>/'"${dcol_2xa2_rgba}"'/g
                s/<wallbash_2xa3_rgba(\([^)]*\))>/'"${dcol_2xa3_rgba}"'/g
                s/<wallbash_2xa4_rgba(\([^)]*\))>/'"${dcol_2xa4_rgba}"'/g
                s/<wallbash_2xa5_rgba(\([^)]*\))>/'"${dcol_2xa5_rgba}"'/g
                s/<wallbash_2xa6_rgba(\([^)]*\))>/'"${dcol_2xa6_rgba}"'/g
                s/<wallbash_2xa7_rgba(\([^)]*\))>/'"${dcol_2xa7_rgba}"'/g
                s/<wallbash_2xa8_rgba(\([^)]*\))>/'"${dcol_2xa8_rgba}"'/g
                s/<wallbash_2xa9_rgba(\([^)]*\))>/'"${dcol_2xa9_rgba}"'/g
                s/<wallbash_pry3_rgba(\([^)]*\))>/'"${dcol_pry3_rgba}"'/g
                s/<wallbash_txt3_rgba(\([^)]*\))>/'"${dcol_txt3_rgba}"'/g
                s/<wallbash_3xa1_rgba(\([^)]*\))>/'"${dcol_3xa1_rgba}"'/g
                s/<wallbash_3xa2_rgba(\([^)]*\))>/'"${dcol_3xa2_rgba}"'/g
                s/<wallbash_3xa3_rgba(\([^)]*\))>/'"${dcol_3xa3_rgba}"'/g
                s/<wallbash_3xa4_rgba(\([^)]*\))>/'"${dcol_3xa4_rgba}"'/g
                s/<wallbash_3xa5_rgba(\([^)]*\))>/'"${dcol_3xa5_rgba}"'/g
                s/<wallbash_3xa6_rgba(\([^)]*\))>/'"${dcol_3xa6_rgba}"'/g
                s/<wallbash_3xa7_rgba(\([^)]*\))>/'"${dcol_3xa7_rgba}"'/g
                s/<wallbash_3xa8_rgba(\([^)]*\))>/'"${dcol_3xa8_rgba}"'/g
                s/<wallbash_3xa9_rgba(\([^)]*\))>/'"${dcol_3xa9_rgba}"'/g
                s/<wallbash_pry4_rgba(\([^)]*\))>/'"${dcol_pry4_rgba}"'/g
                s/<wallbash_txt4_rgba(\([^)]*\))>/'"${dcol_txt4_rgba}"'/g
                s/<wallbash_4xa1_rgba(\([^)]*\))>/'"${dcol_4xa1_rgba}"'/g
                s/<wallbash_4xa2_rgba(\([^)]*\))>/'"${dcol_4xa2_rgba}"'/g
                s/<wallbash_4xa3_rgba(\([^)]*\))>/'"${dcol_4xa3_rgba}"'/g
                s/<wallbash_4xa4_rgba(\([^)]*\))>/'"${dcol_4xa4_rgba}"'/g
                s/<wallbash_4xa5_rgba(\([^)]*\))>/'"${dcol_4xa5_rgba}"'/g
                s/<wallbash_4xa6_rgba(\([^)]*\))>/'"${dcol_4xa6_rgba}"'/g
                s/<wallbash_4xa7_rgba(\([^)]*\))>/'"${dcol_4xa7_rgba}"'/g
                s/<wallbash_4xa8_rgba(\([^)]*\))>/'"${dcol_4xa8_rgba}"'/g
                s/<wallbash_4xa9_rgba(\([^)]*\))>/'"${dcol_4xa9_rgba}"'/g' "${temp_target_file}"
    fi

    # Option to make dcol templates handle basic environment variables
    sed -i 's|<<HOME>>|'"${HOME}"'|g' "${temp_target_file}"

    if [ -s "${temp_target_file}" ]; then
        mv "${temp_target_file}" "${target_file}"
    fi
    [ -z "${exec_command}" ] || bash -c "${exec_command}"
}

WALLBASH_DIRS=""
for dir in "${wallbashDirs[@]}"; do
    [ -d "${dir}" ] || wallbashDirs=("${wallbashDirs[@]//$dir/}")
    [ -d "$dir" ] && WALLBASH_DIRS+="$dir:"
done
WALLBASH_DIRS="${WALLBASH_DIRS%:}"

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then PATH="$HOME/.local/bin:${PATH}"; fi
export WALLBASH_DIRS PATH
export -f fn_wallbash print_log pkg_installed

if [ -n "${dcol_colors}" ]; then
    set -a
    # shellcheck disable=SC1090
    source "${dcol_colors}"
    print_log -sec "wallbash" -stat "single instance" "Wallbash Colors: ${dcol_colors}"
    set +a
fi

# Single template mode
if [ -n "${single_template}" ]; then
    fn_wallbash "${single_template}"
    exit 0
fi

# Run when hyprland is running
if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    hyprctl keyword misc:disable_autoreload 1 -q
    export HYPRLAND_RELOAD=1
fi
# Print to terminal the colors
[ -t 1 ] && "${scrDir}/wallbash.print.colors.sh"

#// switch theme <//> wall based colors

# shellcheck disable=SC2154
if [ "${enableWallDcol}" -eq 0 ] && [[ "${reload_flag}" -eq 1 ]]; then

    print_log -sec "wallbash" -stat "apply ${dcol_mode} colors" "${HYDE_THEME} theme"
    mapfile -d '' -t deployList < <(find "${HYDE_THEME_DIR}" -type f -name "*.theme" -print0)

    while read -r pKey; do
        fKey="$(find "${HYDE_THEME_DIR}" -type f -name "$(basename "${pKey%.dcol}.theme")")"
        [ -z "${fKey}" ] && deployList+=("${pKey}")
    done < <(find "${wallbashDirs[@]}" -type f -path "*/theme*" -name "*.dcol" 2>/dev/null | awk '!seen[substr($0, match($0, /[^/]+$/))]++')

    parallel fn_wallbash ::: "${deployList[@]}"

elif [ "${enableWallDcol}" -gt 0 ]; then
    print_log -sec "wallbash" -stat "apply ${dcol_mode} colors" "Wallbash theme"
    # This is the reason we avoid SPACES for the wallbash template names
    find "${wallbashDirs[@]}" -type f -path "*/theme*" -name "*.dcol" 2>/dev/null | awk '!seen[substr($0, match($0, /[^/]+$/))]++' | parallel fn_wallbash {}
fi

#  Theme mode: detects the color-scheme set in hypr.theme and falls back if nothing is parsed.
revert_colors=0
[ "${enableWallDcol}" -eq 0 ] && { grep -q "${dcol_mode}" <<<"$(get_hyprConf "COLOR_SCHEME")" || revert_colors=1; }
export revert_colors

find "${wallbashDirs[@]}" -type f -path "*/always*" -name "*.dcol" 2>/dev/null | sort | awk '!seen[substr($0, match($0, /[^/]+$/))]++' | parallel fn_wallbash {}

# Add post processing here

toml_write "${confDir}/kdeglobals" "Colors:View" "BackgroundNormal" "#${dcol_pry1:-000000}"

if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] && [ "$HYPRLAND_RELOAD" -eq 1 ]; then
    hyprctl reload -q
fi

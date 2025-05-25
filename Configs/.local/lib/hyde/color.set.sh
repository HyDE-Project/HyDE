#!/usr/bin/env bash
# shellcheck disable=SC2154

# Function to create wallbash substitutions
create_wallbash_substitutions() {
    local use_inverted=$1
    local sed_script
    sed_script="s|<wallbash_mode>|$(${use_inverted} && printf "%s" "${dcol_invt:-light}" || printf "%s" "${dcol_mode:-dark}")|g;"

    # Add substitutions for all color variables
    for i in {1..4}; do
        # Determine if colors should be reversed
        if ${use_inverted}; then
            rev_i=$((5 - i))
            src_i=$rev_i
        else
            src_i=$i
        fi

        # Get values directly using indirect reference
        local pry_var="dcol_pry${src_i}"
        local txt_var="dcol_txt${src_i}"

        # Add RGBA variables
        local pry_rgba_var="dcol_pry${src_i}_rgba"
        local txt_rgba_var="dcol_txt${src_i}_rgba"

        # Add RGB variables by converting from RGBA if they exist
        local pry_rgb_var="dcol_pry${src_i}_rgb"
        local txt_rgb_var="dcol_txt${src_i}_rgb"

        # If RGB vars don't exist but RGBA does, create RGB from RGBA
        if [[ -n "${!pry_rgba_var:-}" && -z "${!pry_rgb_var:-}" ]]; then
            # Convert RGBA to RGB and export as new variable
            declare -g "${pry_rgb_var}=$(sed -E 's/rgba\(([0-9]+,[0-9]+,[0-9]+),.*/\1/' <<<"${!pry_rgba_var}")"
            export "${pry_rgb_var?}"
        fi

        if [[ -n "${!txt_rgba_var:-}" && -z "${!txt_rgb_var:-}" ]]; then
            # Convert RGBA to RGB and export as new variable
            declare -g "${txt_rgb_var}=$(sed -E 's/rgba\(([0-9]+,[0-9]+,[0-9]+),.*/\1/' <<<"${!txt_rgba_var}")"
            export "${txt_rgb_var?}"
        fi

        # Add to sed script if variables exist
        [ -n "${!pry_var:-}" ] && sed_script+="s|<wallbash_pry${i}>|${!pry_var}|g;"
        [ -n "${!txt_var:-}" ] && sed_script+="s|<wallbash_txt${i}>|${!txt_var}|g;"
        [ -n "${!pry_rgba_var:-}" ] && sed_script+="s|<wallbash_pry${i}_rgba(\([^)]*\))>|${!pry_rgba_var}|g;"
        [ -n "${!txt_rgba_var:-}" ] && sed_script+="s|<wallbash_txt${i}_rgba(\([^)]*\))>|${!txt_rgba_var}|g;"
        [ -n "${!pry_rgb_var:-}" ] && sed_script+="s|<wallbash_pry${i}_rgb>|${!pry_rgb_var}|g;"
        [ -n "${!txt_rgb_var:-}" ] && sed_script+="s|<wallbash_txt${i}_rgb>|${!txt_rgb_var}|g;"

        # Add xa colors with direct variable expansion
        for j in {1..9}; do
            local xa_var="dcol_${src_i}xa${j}"
            local xa_rgba_var="dcol_${src_i}xa${j}_rgba"
            local xa_rgb_var="dcol_${src_i}xa${j}_rgb"

            # Create RGB from RGBA if needed
            if [[ -n "${!xa_rgba_var:-}" && -z "${!xa_rgb_var:-}" ]]; then
                declare -g "${xa_rgb_var}=$(sed -E 's/rgba\(([0-9]+,[0-9]+,[0-9]+),.*/\1/' <<<"${!xa_rgba_var}")"
                export "${xa_rgb_var?}"
            fi

            [ -n "${!xa_var:-}" ] && sed_script+="s|<wallbash_${i}xa${j}>|${!xa_var}|g;"
            [ -n "${!xa_rgba_var:-}" ] && sed_script+="s|<wallbash_${i}xa${j}_rgba(\([^)]*\))>|${!xa_rgba_var}|g;"
            [ -n "${!xa_rgb_var:-}" ] && sed_script+="s|<wallbash_${i}xa${j}_rgb>|${!xa_rgb_var}|g;"
        done
    done

    # Add home directory substitution
    sed_script+="s|<<HOME>>|${HOME}|g"

    printf "%s" "$sed_script"
}

# Preprocess sed scripts for both normal and inverted modes
preprocess_substitutions() {
    NORMAL_SED_SCRIPT=$(create_wallbash_substitutions false)
    INVERTED_SED_SCRIPT=$(create_wallbash_substitutions true)
    export NORMAL_SED_SCRIPT INVERTED_SED_SCRIPT
}

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
    export WALLBASH_SCRIPTS confDir hydeConfDir cacheDir thmbDir dcolDir iconsDir themesDir fontsDir wallbashDirs enableWallDcol HYDE_THEME_DIR HYDE_THEME GTK_ICON GTK_THEME CURSOR_THEME
    export -f pkg_installed print_log
    exec_command="${exec_command:-"$(head -1 "${template}" | awk -F '|' '{print $2}')"}"
    temp_target_file="$(mktemp)"
    sed '1d' "${template}" >"${temp_target_file}"

    # Check if we need inverted colors
    if [[ "${revert_colors:-0}" -eq 1 ]] ||
        [[ "${enableWallDcol:-0}" -eq 2 && "${dcol_mode:-}" == "light" ]] ||
        [[ "${enableWallDcol:-0}" -eq 3 && "${dcol_mode:-}" == "dark" ]]; then
        # Use the preprocessed inverted sed script
        sed -i "${INVERTED_SED_SCRIPT}" "${temp_target_file}"
    else
        # Use the preprocessed normal sed script
        sed -i "${NORMAL_SED_SCRIPT}" "${temp_target_file}"
    fi

    if [ -s "${temp_target_file}" ]; then
        mv "${temp_target_file}" "${target_file}"
    fi
    [ -z "${exec_command}" ] || {
        bash -c "${exec_command}" &
        disown
    }
}

scrDir="$(dirname "$(realpath "$0")")"
export scrDir
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"
confDir="${XDG_CONFIG_HOME:-$(xdg-user-dir CONFIG)}"
wallbash_image="${1}"

# Parse arguments
dcol_colors=""
while [[ $# -gt 0 ]]; do
    case "$1" in
    --dcol)
        dcol_colors="$2"
        if [ -f "${dcol_colors}" ]; then
            printf "[Source] %s\n" "${dcol_colors}"
            # shellcheck disable=SC1090
            source "${dcol_colors}"
            shift 2
        else
            dcol_colors="$(find "${dcolDir}" -type f -name "*.dcol" | shuf -n 1)"
            printf "[Dcol Colors] %s\n" "${dcol_colors}"
            shift
        fi
        ;;
    --wall)
        wallbash_image="$2"
        shift 2
        ;;
    --single)
        [ -f "${wallbash_image}" ] || wallbash_image="${cacheDir}/wall.set"
        single_template="$2"
        printf "[wallbash] Single template: %s\n" "${single_template}"
        printf "[wallbash] Wallpaper: %s\n" "${wallbash_image}"
        shift 2
        #     ;;
        # --mode)
        #     enableWallDcol="$2"
        #     shift 2
        ;;
    -*)
        printf "Usage: %s [--dcol <mode>] [--wall <image>] [--single] [--mode <mode>] [--help]\n" "$0"
        exit 0
        ;;
    *) break ;;
    esac
done

#// validate input

if [ -z "${wallbash_image}" ] || [ ! -f "${wallbash_image}" ]; then
    printf "Error: Input wallpaper not found!\n"
    exit 1
fi
# shellcheck disable=SC2154
dcol_file="${dcolDir}/$(set_hash "${wallbash_image}").dcol"

if [ ! -f "${dcol_file}" ]; then
    "${scrDir}/swwwallcache.sh" -w "${wallbash_image}" &>/dev/null
fi

set -a
# shellcheck disable=SC1090
source "${dcol_file}"
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

if [ -z "$GTK_THEME" ]; then
    if [ "${enableWallDcol}" -eq 0 ]; then
        GTK_THEME="$(get_hyprConf "GTK_THEME")"
    else
        GTK_THEME="Wallbash-Gtk"
    fi
fi
[ -z "$GTK_ICON" ] && GTK_ICON="$(get_hyprConf "ICON_THEME")"
[ -z "$CURSOR_THEME" ] && CURSOR_THEME="$(get_hyprConf "CURSOR_THEME")"
export GTK_THEME GTK_ICON CURSOR_THEME

# Preprocess substitutions once before processing any templates
preprocess_substitutions
print_log -sec "wallbash" -stat "preprocessed" "color substitutions"

#// deploy wallbash colors

WALLBASH_DIRS=""
for dir in "${wallbashDirs[@]}"; do
    [ -d "${dir}" ] || wallbashDirs=("${wallbashDirs[@]//$dir/}")
    [ -d "$dir" ] && WALLBASH_DIRS+="$dir:"
done
WALLBASH_DIRS="${WALLBASH_DIRS%:}"

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then PATH="$HOME/.local/bin:${PATH}"; fi
export WALLBASH_DIRS PATH
export -f fn_wallbash print_log pkg_installed create_wallbash_substitutions preprocess_substitutions

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

# Print to terminal the colors
[ -t 1 ] && "${scrDir}/wallbash.print.colors.sh"

#// switch theme <//> wall based colors

[[ -n $HYPRLAND_INSTANCE_SIGNATURE ]] && {
    hyprctl keyword misc:disable_autoreload 1 -q
    trap "hyprctl reload config-only -q" EXIT
}
# shellcheck disable=SC2154
if [ "${enableWallDcol}" -eq 0 ] && [[ "${reload_flag}" -eq 1 ]]; then

    print_log -sec "wallbash" -stat "apply ${dcol_mode} colors" "${HYDE_THEME} theme"
    mapfile -d '' -t deployList < <(find "${HYDE_THEME_DIR}" -type f -name "*.theme" -print0)

    while read -r pKey; do
        fKey="$(find "${HYDE_THEME_DIR}" -type f -name "$(basename "${pKey%.dcol}.theme")")"
        [ -z "${fKey}" ] && deployList+=("${pKey}")
    done < <(find "${wallbashDirs[@]}" -type f -path "*/theme*" -name "*.dcol" 2>/dev/null | awk '!seen[substr($0, match($0, /[^/]+$/))]++')

    # Process templates in parallel
    parallel fn_wallbash ::: "${deployList[@]}" || true

elif [ "${enableWallDcol}" -gt 0 ]; then
    print_log -sec "wallbash" -stat "apply ${dcol_mode} colors" "Wallbash theme"
    # This is the reason we avoid SPACES for the wallbash template names
    find "${wallbashDirs[@]}" -type f -path "*/theme*" -name "*.dcol" 2>/dev/null | awk '!seen[substr($0, match($0, /[^/]+$/))]++' | parallel fn_wallbash {} || true
fi

#  Theme mode: detects the color-scheme set in hypr.theme and falls back if nothing is parsed.
revert_colors=0
[ "${enableWallDcol}" -eq 0 ] && { grep -q "${dcol_mode}" <<<"$(get_hyprConf "COLOR_SCHEME")" || revert_colors=1; }
export revert_colors

# Process "always" templates in parallel
find "${wallbashDirs[@]}" -type f -path "*/always*" -name "*.dcol" 2>/dev/null | sort | awk '!seen[substr($0, match($0, /[^/]+$/))]++' | parallel fn_wallbash {} || true

# Add configuration hooks
toml_write "${confDir}/kdeglobals" "Colors:View" "BackgroundNormal" "#${dcol_pry1:-000000}FF"
toml_write "${confDir}/Kvantum/wallbash/wallbash.kvconfig" '%General' 'reduce_menu_opacity' 0

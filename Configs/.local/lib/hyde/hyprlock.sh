#! /bin/bash

# shellcheck source=$HOME/.local/bin/hyde-shell
# shellcheck disable=SC1091
if ! source "$(which hyde-shell)"; then
    echo "[wallbash] code :: Error: hyde-shell not found."
    echo "[wallbash] code :: Is HyDE installed?"
    exit 1
fi
scrDir=${scrDir:-$HOME/.local/lib/hyde}
confDir="${confDir:-$XDG_CONFIG_HOME}"
cacheDir="${HYDE_CACHE_HOME:-"${XDG_CACHE_HOME}/hyde"}"
WALLPAPER="${cacheDir}/wall.set"

# Converts and ensures background to be a png
fn_background() {
    WP="$(realpath "${WALLPAPER}")"
    BG="${cacheDir}/wall.set.png"
    cp -f "${WP}" "${BG}"
    mime=$(file --mime-type "${WP}" | grep -E "image/(png|jpg|webp)")
    #? Run this in the background because converting takes time
    ([[ -z ${mime} ]] && magick "${BG}"[0] "${BG}") &
}

fn_profile() {
    local profilePath="${cacheDir}/landing/profile"
    if [ -f "$HOME/.face.icon" ]; then
        cp "$HOME/.face.icon" "${profilePath}.png"
    else
        cp "$XDG_DATA_HOME/icons/Wallbash-Icon/hyde.png" "${profilePath}.png"
    fi
    return 0
}

fn_mpris() {
    local player=${1:-spotify}
    THUMB="${cacheDir}/landing/mpris"
    if [ "$(playerctl -p "${player}" status)" == "Playing" ]; then
        playerctl -p "${player}" metadata --format "{{xesam:title}} $(mpris_icon "${player}")  {{xesam:artist}}"
        mpris_thumb "${player}"
    else

        if [ -f "$HOME/.face.icon" ]; then
            cp -f "$HOME/.face.icon" "${THUMB}".png
        else
            cp "$XDG_DATA_HOME/icons/Wallbash-Icon/hyde.png" "${THUMB}".png
        fi
        pkill -USR2 hyprlock &>/dev/null # updates the mpris thumbnail

    fi
}

mpris_icon() {

    local player=${1:-default}
    declare -A player_dict=(
        ["default"]=""
        ["spotify"]=""
        ["firefox"]=""
        ["vlc"]="嗢"
        ["google-chrome"]=""
        ["opera"]=""
        ["brave"]=""
    )

    for key in "${!player_dict[@]}"; do
        if [[ ${player} == "$key"* ]]; then
            echo "${player_dict[$key]}"
            return
        fi
    done
    echo "" # Default icon if no match is found

}

mpris_thumb() { # Generate thumbnail for mpris
    local player=${1:-spotify}
    artUrl=$(playerctl -p "${player}" metadata --format '{{mpris:artUrl}}')
    [ "${artUrl}" == "$(cat "${THUMB}".lnk)" ] && [ -f "${THUMB}".png ] && exit 0
    echo "${artUrl}" >"${THUMB}".lnk
    curl -Lso "${THUMB}".art "$artUrl"
    magick "${THUMB}.art" -quality 50 "${THUMB}.png"
    pkill -USR2 hyprlock &>/dev/null # updates the mpris thumbnail
}

fn_cava() {
    local tempFile=/tmp/hyprlock-cava
    [ -f "${tempFile}" ] && tail -n 1 "${tempFile}"
    config_file="$HYDE_RUNTIME_DIR/cava.hyprlock"
    if [ "$(pgrep -c -f "cava -p ${config_file}")" -eq 0 ]; then
        "$scrDir/cava.sh" hyprlock >${tempFile} 2>&1
    fi
}

fn_art() {
    echo "$XDG_CACHE_HOME/hyde/landing/mpris.art"
}

# hyprlock selector
fn_select() {
    # Set rofi scaling

    [[ "${rofiScale}" =~ ^[0-9]+$ ]] || rofiScale=${ROFI_SCALE:-10}
    r_scale="configuration {font: \"JetBrainsMono Nerd Font ${rofiScale}\";}"

    # Window and element styling
    hypr_border=${hypr_border:-"$(hyprctl -j getoption decoration:rounding | jq '.int')"}
    wind_border=$((hypr_border * 3 / 2))
    elem_border=$((hypr_border == 0 ? 5 : hypr_border))
    hypr_width=${hypr_width:-"$(hyprctl -j getoption general:border_size | jq '.int')"}
    r_override="window{border:${hypr_width}px;border-radius:${wind_border}px;} wallbox{border-radius:${elem_border}px;} element{border-radius:${elem_border}px;}"

    # List available .conf files in hyprlock directory
    layout_dir="$confDir/hypr/hyprlock"
    layout_items=$(find "${layout_dir}" -name "*.conf" ! -name "theme.conf" 2>/dev/null | sed 's/\.conf$//')

    if [ -z "$layout_items" ]; then
        notify-send -i "preferences-desktop-display" "Error" "No .conf files found in ${layout_dir}"
        exit 1
    fi

    layout_items="Theme Preference
$layout_items"

    rofi_config="$confDir/rofi/clipboard.rasi"
    selected_layout=$(awk -F/ '{print $NF}' <<<"$layout_items" |
        rofi -dmenu \
            -p "Select hyprlock layout" \
            -theme-str "entry { placeholder: \"🔒 Hyprlock Layout...\"; }" \
            -theme-str "${r_scale}" \
            -theme-str "${r_override}" \
            -theme-str "$(get_rofi_pos)" \
            -theme "$rofi_config")
    if [ -z "$selected_layout" ]; then
        echo "No selection made"
        exit 0
    elif [ "$selected_layout" == "Theme Preference" ]; then
        selected_layout="theme"
    fi
    hyde_conf="$confDir/hypr/hyprlock.conf"
    # shellcheck disable=SC2016
    if grep -qE '^\s*\$HYPRLOCK_LAYOUT\s*=\s*.*' "$hyde_conf"; then
        sed -i "s/^\s*\$HYPRLOCK_LAYOUT\s*=\s*.*/\$HYPRLOCK_LAYOUT=$selected_layout/" "$hyde_conf"
    else
        echo "\$HYPRLOCK_LAYOUT=$selected_layout" >>"$hyde_conf"
    fi
    "${scrDir}/font.sh" resolve "${layout_dir}/${selected_layout}.conf"
    fn_profile
    # Notify the user
    notify-send -i "system-lock-screen" "Hyprlock layout:" "${selected_layout}"

}

fn_help() {
    echo "Usage: hyprlock.sh [command]"
    echo "Commands:"
    echo "  background   - Converts and ensures background to be a png"
    echo "  mpris        - Handles mpris thumbnail generation"
    echo "  profile      - Generates the profile picture"
    echo "  cava         - Placeholder function for cava"
    echo "  art          - Prints the path to the mpris art"
    echo "  select       - Selects the hyprlock layout"
    echo "  help         - Displays this help message"
}

if declare -f "fn_${1}" >/dev/null; then
    "fn_${1}"
else
    hyprlock
fi

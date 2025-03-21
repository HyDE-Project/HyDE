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

USAGE() {
    cat <<EOF
    Usage: $(basename "${0}") --[arg]

    arguments:
      --background -b    - Converts and ensures background to be a png
                            : \$BACKGROUND_PATH
      --mpris <player>   - Handles mpris thumbnail generation
                            : \$MPRIS_IMAGE
      --profile          - Generates the profile picture
                            : \$PROFILE_IMAGE
      --cava             - Placeholder function for cava
                            : \$CAVA_CMD
      --art              - Prints the path to the mpris art"
                            : \$MPRIS_ART
      --select      -s     - Selects the hyprlock layout"
                            : \$LAYOUT_PATH
      --help       -h    - Displays this help message"
EOF
}

# Converts and ensures background to be a png
fn_background() {
    WP="$(realpath "${WALLPAPER}")"
    BG="${cacheDir}/wall.set.png"

    is_video=$(file --mime-type -b "${WP}" | grep -c '^video/')
    if [ "${is_video}" -eq 1 ]; then
        print_log -sec "wallpaper" -stat "converting video" "$WP"
        mkdir -p "${HYDE_CACHE_HOME}/wallpapers/thumbnails"
        cached_thumb="$HYDE_CACHE_HOME/wallpapers/$(${hashMech:-sha1sum} "${WP}" | cut -d' ' -f1).png"
        extract_thumbnail "${WP}" "${cached_thumb}"
        WP="${cached_thumb}"
    fi

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
    local player=${1:-$(playerctl --list-all 2>/dev/null | head -n 1)}
    THUMB="${cacheDir}/landing/mpris"
    player_status="$(playerctl -p "${player}" status 2>/dev/null)"
    if [[ "${player_status}" == "Playing" ]]; then
        playerctl -p "${player}" metadata --format "{{xesam:title}} $(mpris_icon "${player}")  {{xesam:artist}}"
        mpris_thumb "${player}"
    else
        if [ -f "$HOME/.face.icon" ]; then
            if ! cmp -s "$HOME/.face.icon" "${THUMB}.png"; then
                cp -f "$HOME/.face.icon" "${THUMB}.png"
                pkill -USR2 hyprlock >/dev/null 2>&1 # updates the mpris thumbnail
            fi
        else
            if ! cmp -s "$XDG_DATA_HOME/icons/Wallbash-Icon/hyde.png" "${THUMB}.png"; then
                cp "$XDG_DATA_HOME/icons/Wallbash-Icon/hyde.png" "${THUMB}.png"
                pkill -USR2 hyprlock >/dev/null 2>&1 # updates the mpris thumbnail
            fi
        fi
        exit 1
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
    local player=${1:-""}
    artUrl=$(playerctl -p "${player}" metadata --format '{{mpris:artUrl}}')
    [ "${artUrl}" == "$(cat "${THUMB}".lnk)" ] && [ -f "${THUMB}".png ] && exit 0
    echo "${artUrl}" >"${THUMB}".lnk
    curl -Lso "${THUMB}".art "$artUrl"
    magick "${THUMB}.art" -quality 50 "${THUMB}.png"
    pkill -USR2 hyprlock >/dev/null 2>&1 # updates the mpris thumbnail
}

fn_cava() {
    local tempFile=/tmp/hyprlock-cava
    [ -f "${tempFile}" ] && tail -n 1 "${tempFile}"
    config_file="$HYDE_RUNTIME_DIR/cava.hyprlock"
    if [ "$(pgrep -c -f "cava -p ${config_file}")" -eq 0 ]; then
        trap 'rm -f ${tempFile}' EXIT
        "$scrDir/cava.sh" hyprlock >${tempFile} 2>&1
    fi
}

fn_art() {
    echo "${cacheDir}/landing/mpris.art"
}

# hyprlock selector
fn_select() {
    # Set rofi scaling
    font_scale="${ROFI_HYPRLOCK_SCALE}"
    [[ "${font_scale}" =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}

    # set font name
    font_name=${ROFI_HYPRLOCK_FONT:-$ROFI_FONT}
    font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
    font_name=${font_name:-$(get_hyprConf "FONT")}

    # set rofi font override
    font_override="* {font: \"${font_name:-"JetBrainsMono Nerd Font"} ${font_scale}\";}"

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

    selected_layout=$(awk -F/ '{print $NF}' <<<"$layout_items" |
        rofi -dmenu -i -select "${HYPRLOCK_LAYOUT}" \
            -p "Select hyprlock layout" \
            -theme-str "entry { placeholder: \"🔒 Hyprlock Layout...\"; }" \
            -theme-str "${font_override}" \
            -theme-str "${r_override}" \
            -theme-str "$(get_rofi_pos)" \
            -theme "${ROFI_HYPRLOCK_STYLE:-clipboard}")
    if [ -z "$selected_layout" ]; then
        echo "No selection made"
        exit 0
    fi
    set_conf "HYPRLOCK_LAYOUT" "${selected_layout}"
    if [ "$selected_layout" == "Theme Preference" ]; then
        selected_layout="theme"
    fi
    generate_conf "${layout_dir}/${selected_layout}.conf"
    "${scrDir}/font.sh" resolve "${layout_dir}/${selected_layout}.conf"
    fn_profile

    # Notify the user
    notify-send -i "system-lock-screen" "Hyprlock layout:" "${selected_layout}"

}

generate_conf() {
    local path="${1:-$confDir/hypr/hyprlock/theme.conf}"
    local hyde_hyprlock_conf=${SHARE_DIR:-$XDG_DATA_HOME}/hyde/hyprlock.conf

    cat <<CONF >"$confDir/hypr/hyprlock.conf"
#! █░█ █▄█ █▀█ █▀█ █░░ █▀█ █▀▀ █▄▀
#! █▀█ ░█░ █▀▀ █▀▄ █▄▄ █▄█ █▄▄ █░█

#*  Hyprlock Configuration File 
# Please do not edit this file manually.
# Follow the instructions below on how to make changes.


#* Hyprlock active layout path:
# Set the layout path to be used by Hyprlock.
# Check the available layouts in the './hyprlock/' directory.
# Example: /$LAYOUT_PATH=/path/to/anurati
\$LAYOUT_PATH=${path}

#*  Persistent layout declaration 
# If a persistent layout path is declared in \$XDG_CONFIG_HOME/hypr/hyde.conf,
# the above layout setting will be ignored.
# this should be the full path to the layout file.

#*  All boilerplate configurations are handled by HyDE 
source = ${hyde_hyprlock_conf}

#*  Making a custom layout 
# To create a custom layout, make a file in the './hyprlock/' directory.
# Example: './hyprlock/your_custom.conf'
# To use the custom layout, set the following variable:
# \$LAYOUT_PATH=your_custom
# The custom layout will be sourced automatically.
# Alternatively, you can statically source the layout in '~/.config/hypr/hyde.conf'.
# This will take precedence over the variable in '~/.config/hypr/hyprlock.conf'.


#*  Command Variables 
# Hyprlock ships with there default variables that can be used to customize the lock screen.
# - https://wiki.hyprland.org/Hypr-Ecosystem/hyprlock/#label
# HyDE also provides custom variables that extend the functionality of Hyprlock.

# \$BACKGROUND_PATH
# - The path to the wallpaper image.

# \$HYPRLOCK_BACKGROUND
# - The path to the static hyprlock wallpaper image.
# - Can be set to set a static wallpaper for Hyprlock.

# \$MPRIS_IMAGE
# - The path to the MPRIS image.
# - If MPRIS is not available, it will show the ~/.face.icon image
# - if available, otherwise, it will show the HyDE logo.

# \$PROFILE_IMAGE
# - The path to the profile image.
# - If the image is not available, it will show the ~/.face.icon image
# - if available, otherwise, it will show the HyDE logo.

# \$GREET_TEXT
# - A greeting text to be displayed on the lock screen.
# - The text will be updated every hour.

# \$resolve.font
# - Resolves the font name and download link.
# - HyDE will run 'font.sh resolve' to install the font for you.
# - Note that you needed to have a network connection to download the font.
# - You also need to restart Hyprlock to apply the font.

# cmd [update:1000] \$MPRIS_TEXT
# - Text from media players in "Title  Author" format.


# cmd [update:1000] \$SPLASH_CMD
# - Outputs the song title when MPRIS is available,
# - otherwise, it will output the splash command.

# cmd [update:1] \$CAVA_CMD
# - The command to be executed to get the CAVA output.
# - ⚠️ (Use with caution as it eats up the CPU.)

# cmd [update:5000] \$BATTERY_ICON
# - The battery icon to be displayed on the lock screen.
# - Only works if the battery is available.

# cmd [update:1000] \$KEYBOARD_LAYOUT
# - The current keyboard layout
# - SUPER + K to change the keyboard layout (or any binding you set)

CONF
}

if [ -z "${*}" ]; then
    if [ ! -f "$HYDE_CACHE_HOME/wallpapers/hyprlock.png" ]; then
        print_log -sec "hyprlock" -stat "setting" " $HYDE_CACHE_HOME/wallpapers/hyprlock.png"
        "${scrDir}/wallpaper.sh" -s "$(readlink "${HYDE_THEME_DIR}/wall.set")" --backend hyprlock
    fi
    hyprlock
fi

# Define long options
LONGOPTS="select,background,profile,mpris:,cava,art,help"

# Parse options
PARSED=$(
    if ! getopt --options shb --longoptions $LONGOPTS --name "$0" -- "$@"; then
        exit 2
    fi
)

# Apply parsed options
eval set -- "$PARSED"

while true; do
    case "$1" in
    select | -s | --select)
        fn_select
        exit 0
        ;;
    background | --background | -b)
        fn_background
        exit 0
        ;;
    profile | --profile)
        fn_profile
        exit 0
        ;;
    mpris | --mpris)
        fn_mpris "${2}"
        exit 0
        ;;
    cava | --cava) # Placeholder function for cava
        fn_cava
        exit 0
        ;;
    art | --art)
        fn_art
        exit 0
        ;;
    help | --help | -h)
        USAGE
        exit 0
        ;;
    --)
        shift
        break
        ;;
    *)
        break
        ;;
    esac
    shift
done

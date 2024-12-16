#! /bin/bash

# shellcheck source=$HOME/.local/bin/hyde-shell
# shellcheck disable=SC1091
if ! source "$(which hyde-shell)"; then
    echo "[wallbash] code :: Error: hyde-shell not found."
    echo "[wallbash] code :: Is HyDE installed?"
    exit 1
fi

confDir="${confDir:-$XD_CONFIG_HOME}"
cacheDir="${cacheDir:-"${XDG_CACHE_HOME}/hyde"}"
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

mpris_thumb() { # Generate thumbnail for mpris
    artUrl=$(playerctl -p spotify metadata --format '{{mpris:artUrl}}')
    [ "${artUrl}" == "$(cat "${THUMB}".lnk)" ] && [ -f "${THUMB}".png ] && exit 0
    echo "${artUrl}" >"${THUMB}".lnk
    curl -Lso "${THUMB}".art "$artUrl"
    magick "${THUMB}.art" -quality 50 "${THUMB}.png"
    pkill -USR2 hyprlock # updates the mpris thumbnail
}

fn_mpris() {
    THUMB="${cacheDir}/landing/mpris"
    if [ "$(playerctl -p spotify status)" == "Playing" ]; then
        playerctl -p spotify metadata --format '{{title}}    {{artist}}'
        mpris_thumb
    else

        if [ -f "$HOME/.face.icon" ]; then
            cp -f "$HOME/.face.icon" "${THUMB}".png
        else
            cp "$XDG_DATA_HOME/icons/Wallbash-Icon/hyde.png" "${THUMB}".png
        fi
        pkill -USR2 hyprlock # updates the mpris thumbnail
        return 1
    fi
}

fn_cava() {

    :

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
    layout_files=$(find "${layout_dir}" -name "*.conf" 2>/dev/null | sed 's/\.conf$//')

    if [ -z "$layout_files" ]; then
        notify-send -i "preferences-desktop-display" "Error" "No .conf files found in ${layout_dir}"
        exit 1
    fi

    rofi_config="$confDir/rofi/clipboard.rasi"
    selected_layout=$(awk -F/ '{print $NF}' <<<"$layout_files" |
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
    fi
    hyde_conf="$confDir/hypr/hyprlock.conf"
    # shellcheck disable=SC2016
    if grep -qE '^\s*\$HYPRLOCK_LAYOUT\s*=\s*.*' "$hyde_conf"; then
        sed -i "s/^\s*\$HYPRLOCK_LAYOUT\s*=\s*.*/\$HYPRLOCK_LAYOUT=$selected_layout/" "$hyde_conf"
    else
        echo "\$HYPRLOCK_LAYOUT=$selected_layout" >>"$hyde_conf"
    fi

    # Notify the user
    notify-send -i "system-lock-screen" "Hyprlock:" "${selected_layout}"

}

if declare -f "fn_${1}" >/dev/null; then
    "fn_${1}"
else
    hyprlock
fi

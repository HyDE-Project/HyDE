#! /bin/bash
if ! source "$(which hyde-shell)"; then
    echo "Error: hyde-shell not found."
    echo "Is HyDE installed?"
    exit 1
fi

# Source argparse.sh for argument parsing
source "${LIB_DIR}/hyde/shutils/argparse.sh"

confDir="${confDir:-$XDG_CONFIG_HOME}"
cacheDir="${HYDE_CACHE_HOME:-"$XDG_CACHE_HOME/hyde"}"
WALLPAPER="$cacheDir/wall.set"
HYPRLOCK_SCOPE_NAME="hyde-${XDG_SESSION_DESKTOP:-unknown}-lockscreen.scope"

fn_background() {
    WP="$(realpath "$WALLPAPER")"
    BG="$cacheDir/wall.set.png"
    is_video=$(file --mime-type -b "$WP" | grep -c '^video/')
    if [ "$is_video" -eq 1 ]; then
        print_log -sec "wallpaper" -stat "converting video" "$WP"
        mkdir -p "$HYDE_CACHE_HOME/wallpapers/thumbnails"
        cached_thumb="$HYDE_CACHE_HOME/wallpapers/$(${hashMech:-sha1sum} "$WP" | cut -d' ' -f1).png"
        extract_thumbnail "$WP" "$cached_thumb"
        WP="$cached_thumb"
    fi
    cp -f "$WP" "$BG"
    mime=$(file --mime-type "$WP" | grep -E "image/(png|jpg|webp)")
    ([[ -z $mime ]] && magick "$BG"[0] "$BG") &
}
fn_profile() {
    local profilePath="$cacheDir/landing/profile"
    if [ -f "$HOME/.face.icon" ]; then
        cp "$HOME/.face.icon" "$profilePath.png"
    else
        cp "$XDG_DATA_HOME/icons/Wallbash-Icon/hyde.png" "$profilePath.png"
    fi
    return 0
}
fn_mpris() {
    local player=${1:-$(playerctl --list-all 2>/dev/null | head -n 1)}
    THUMB="$cacheDir/landing/mpris"
    player_status="$(playerctl -p "$player" status 2>/dev/null)"
    if [[ $player_status == "Playing" ]]; then
        playerctl -p "$player" metadata --format "{{xesam:title}} $(mpris_icon "$player")  {{xesam:artist}}"
        mpris_thumb "$player"
    else
        if [ -f "$HOME/.face.icon" ]; then
            if ! cmp -s "$HOME/.face.icon" "$THUMB.png"; then
                cp -f "$HOME/.face.icon" "$THUMB.png"
                reload_hyprlock
            fi
        else
            if ! cmp -s "$XDG_DATA_HOME/icons/Wallbash-Icon/hyde.png" "$THUMB.png"; then
                cp "$XDG_DATA_HOME/icons/Wallbash-Icon/hyde.png" "$THUMB.png"
                reload_hyprlock
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
        ["brave"]="")
    for key in "${!player_dict[@]}"; do
        if [[ $player == "$key"* ]]; then
            echo "${player_dict[$key]}"
            return
        fi
    done
    echo ""
}
mpris_thumb() {
    local player=${1:-""}
    artUrl=$(playerctl -p "$player" metadata --format '{{mpris:artUrl}}')
    [ "$artUrl" == "$(cat "$THUMB".lnk)" ] && [ -f "$THUMB".png ] && exit 0
    echo "$artUrl" >"$THUMB".lnk
    curl -Lso "$THUMB.art" "$artUrl"
    magick "$THUMB.art" -quality 50 "$THUMB.png"
    reload_hyprlock
}
fn_cava() {
    local tempFile=/tmp/hyprlock-cava
    [ -f "$tempFile" ] && tail -n 1 "$tempFile"
    config_file="$XDG_RUNTIME_DIR/hyde/cava.hyprlock"
    if [ "$(pgrep -c -f "cava -p $config_file")" -eq 0 ]; then
        trap 'rm -f ${tempFile}' EXIT
        "${LIB_DIR}/hyde/cava.py" hyprlock >$tempFile 2>&1
    fi
}
fn_art() {
    echo "$cacheDir/landing/mpris.art"
}
find_filepath() {
    local filename="${*:-$1}"
    local search_dirs=(
        "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprlock"
        "${XDG_CONFIG_HOME:-$HOME/.config}/hyde/hyprlock"
        "$HYPRLOCK_CONF_DIR")
    print_log -sec "hyprlock" -stat "Searching for layout" "$filename"
    find "${search_dirs[@]}" -type f -name "$filename*" 2>/dev/null | head -n 1
}
fn_select() {
    font_scale="$ROFI_HYPRLOCK_SCALE"
    [[ $font_scale =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}
    font_name=${ROFI_HYPRLOCK_FONT:-$ROFI_FONT}
    font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
    font_name=${font_name:-$(get_hyprConf "FONT")}
    font_override="* {font: \"${font_name:-"JetBrainsMono Nerd Font"} $font_scale\";}"
    hypr_border=${hypr_border:-"$(hyprctl -j getoption decoration:rounding | jq '.int')"}
    wind_border=$((hypr_border * 3 / 2))
    elem_border=$((hypr_border == 0 ? 5 : hypr_border))
    hypr_width=${hypr_width:-"$(hyprctl -j getoption general:border_size | jq '.int')"}
    r_override="window{border:${hypr_width}px;border-radius:${wind_border}px;} wallbox{border-radius:${elem_border}px;} element{border-radius:${elem_border}px;}"
    layout_dir="$confDir/hypr/hyprlock"
    layout_items=$(find -L "$layout_dir" -name "*.conf" ! -name "theme.conf" 2>/dev/null | sed 's/\.conf$//')
    if [ -z "$layout_items" ]; then
        notify-send -i "preferences-desktop-display" "Error" "No .conf files found in $layout_dir"
        exit 1
    fi
    layout_items="Theme Preference
$layout_items"
    selected_layout=$(awk -F/ '{print $NF}' <<<"$layout_items" | rofi -dmenu -i -select "$HYPRLOCK_LAYOUT" \
        -p "Select hyprlock layout" \
        -theme-str 'entry { placeholder: "🔒 Hyprlock Layout..."; }' \
        -theme-str "$font_override" \
        -theme-str "$r_override" \
        -theme-str "$(get_rofi_pos)" \
        -on-selection-changed 'hyde-shell hyprlock.sh --test-preview  "{entry}"' \
        -theme "${ROFI_HYPRLOCK_STYLE:-clipboard}")
    if [ -z "$selected_layout" ]; then
        echo "No selection made"
        exit 0
    fi
    set_conf "HYPRLOCK_LAYOUT" "$selected_layout"
    if [ "$selected_layout" == "Theme Preference" ]; then
        selected_layout="theme"
    fi
    local hyprlock_conf_path
    hyprlock_conf_path=$(find_filepath "$selected_layout")
    generate_conf "$hyprlock_conf_path"
    "$LIB_DIR/hyde/font.sh" resolve "$hyprlock_conf_path"
    fn_profile
    notify-send -i "system-lock-screen" "Hyprlock layout:" "$selected_layout"
}
check_and_sanitize_process() {
    local unit_name="${1:-$HYPRLOCK_SCOPE_NAME}"
    if systemctl --user is-active "$unit_name" >/dev/null 2>&1; then
        systemctl --user stop "$unit_name" >/dev/null 2>&1
    fi
}
reload_hyprlock() {
    local unit_name="${2:-$HYPRLOCK_SCOPE_NAME}"
    if systemctl --user is-active "$unit_name" >/dev/null 2>&1; then
        systemctl --user kill -s USR2 "$HYPRLOCK_SCOPE_NAME" >/dev/null 2>&1
    else
        pkill -USR2 hyprlock >/dev/null 2>&1
    fi
}
append_label_to_file() {
    local file="$1"
    cat <<EOF >>"$file"
label {
  text = PREVIEW! Press a key or swipe to exit.
  color = rgba(\$wallbash_txt122)
  font_size = 50
  position = 0, 0
  halign = center
  valign = top
  zindex = 6
}

label {
  text = PREVIEW! Press a key or swipe to exit.
  color = rgba(\$wallbash_txt122)
  font_size = 50
  position = 0, 0
  halign = center
  valign = bottom
  zindex = 6
}

label {
  text = PREVIEW! Press a key or swipe to exit.
  color = rgba(\$wallbash_txt122)
  font_size = 50
  position = 0, 0
  halign = center
  valign = center
  zindex = 6
}

EOF
}
layout_test() {
    print_log -sec "hyprlock" -stat "Test" "Please swipe,press a key or click to exit."
    local hyprlock_conf_name="${*:-$1}"
    if [[ $hyprlock_conf_name == "Theme Preference" ]]; then
        hyprlock_conf_name="theme"
    fi
    check_and_sanitize_process
    hyprlock_conf_path=$(find_filepath "$hyprlock_conf_name")
    if [ -z "$hyprlock_conf_path" ]; then
        print_log -sec "hyprlock" -stat "Error" "Layout $hyprlock_conf_name not found."
        exit 1
    fi
    sleep 2
    local temp_path="$XDG_RUNTIME_DIR/hyde/hyprlock-test.conf"
    generate_conf "$hyprlock_conf_path" "$temp_path"
    append_label_to_file "$temp_path"
    app2unit.sh -S both -u "$HYPRLOCK_SCOPE_NAME" -t scope -- hyprlock --no-fade-in --immediate-render --grace 99999999 -c "$temp_path"
    rm -f "$temp_path"
}
rofi_test_preview() {
    local hyprlock_conf_name="${*:-$1}"
    if [[ $hyprlock_conf_name == "Theme Preference" ]]; then
        hyprlock_conf_name="theme"
    fi
    local unit_name="hyde-${XDG_SESSION_DESKTOP:-unknown}-lockscreen-preview.scope"
    check_and_sanitize_process "$unit_name"
    send_notifs "Hyprlock layout: $hyprlock_conf_name" "Please swipe, press a key or click to exit." \
        -i "system-lock-screen" -t 3000 \
        -r 9
    app2unit.sh -S both -u "$unit_name" -t scope -- hyprlock.sh --test "$hyprlock_conf_name"
}
generate_conf() {
    local path="${1:-$confDir/hypr/hyprlock/theme.conf}"
    local target_file="${2:-$confDir/hypr/hyprlock.conf}"
    local hyde_hyprlock_conf=${SHARE_DIR:-$XDG_DATA_HOME}/hyde/hyprlock.conf
    cat <<CONF >"$target_file"
#! █░█ █▄█ █▀█ █▀█ █░░ █▀█ █▀▀ █▄▀
#! █▀█ ░█░ █▀▀ █▀▄ █▄▄ █▄█ █▄▄ █░█


#*┌────────────────────────────────────────────────────────────────────────────┐
#*│    Hyprlock Configuration File                                          │
#*│ # Please do not edit this file manually.                                   │
#*│ # Follow the instructions below on how to make changes.                    │
#*│                                                                            │
#*└────────────────────────────────────────────────────────────────────────────┘



#*┌──────────────────────────────────────────────────────────────────────────┐
#*│ #* Hyprlock active layout path:                                          │
#*│ # Set the layout path to be used by Hyprlock.                            │
#*│ # Check the available layouts in the './hyprlock/' directory.            │
#*│ # Example: /$LAYOUT_PATH=/path/to/anurati                                │
#*└──────────────────────────────────────────────────────────────────────────┘

\$LAYOUT_PATH=$path


#*┌────────────────────────────────────────────────────────────────────────────┐
#*│    Persistent layout declaration                                        │
#*│ # If a persistent layout path is declared in                               │
#*│ \$XDG_CONFIG_HOME/hypr/hyde.conf,                                          │
#*│ # the above layout setting will be ignored.                                │
#*│ # this should be the full path to the layout file.                         │
#*│                                                                            │
#*└────────────────────────────────────────────────────────────────────────────┘


#*┌──────────────────────────────────────────────────────────────────────────┐
#*│    All boilerplate configurations are handled by HyDE                  │
#*└──────────────────────────────────────────────────────────────────────────┘

source = $hyde_hyprlock_conf


#┌────────────────────────────────────────────────────────────────────────────┐
#│ Making a custom layout                                                   │
#│ - To create a custom layout, make a file in the './hyprlock/' directory.   │
#│ - Example: './hyprlock/your_custom.conf'                                   │
#│ - To use the custom layout, set the following variable:                    │
#│ - \$LAYOUT_PATH=your_custom                                                │
#│ - The custom layout will be sourced automatically.                         │
#│ - Alternatively, you can statically source the layout in                   │
#│          '~/.config/hypr/hyde.conf'.                                       │
#│ - This will take precedence over the variable in                           │
#│            '~/.config/hypr/hyprlock.conf'.                                 │
#│                                                                            │
#└────────────────────────────────────────────────────────────────────────────┘


 #┌────────────────────────────────────────────────────────────────────────────┐
 #│  Command Variables                                                       │
 #│ # Hyprlock ships with there default variables that can be used to          │
 #│ customize the lock screen.                                                 |                   │
 #│ https://wiki.hyprland.org/Hypr-Ecosystem/hyprlock/#label                   │                                                               │
 #│                                                                            │
 #└────────────────────────────────────────────────────────────────────────────┘

#┌────────────────────────────────────────────────────────────────────────────┐
#│ HyDE also provides custom variables to extend hyprlock's functionality.  │
#│                                                                            │
#│   \$BACKGROUND_PATH                                                        │
#│   - The path to the wallpaper image.                                       │
#│                                                                            │
#│   \$HYPRLOCK_BACKGROUND                                                    │
#│   - The path to the static hyprlock wallpaper image.                       │
#│   - Can be set to set a static wallpaper for Hyprlock.                     │
#│                                                                            │
#│   \$MPRIS_IMAGE                                                            │
#│   - The path to the MPRIS image.                                           │
#│   - If MPRIS is not available, it will show the ~/.face.icon image         │
#│   - if available, otherwise, it will show the HyDE logo.                   │
#│                                                                            │
#│   \$PROFILE_IMAGE                                                          │
#│   - The path to the profile image.                                         │
#│   - If the image is not available, it will show the ~/.face.icon image     │
#│   - if available, otherwise, it will show the HyDE logo.                   │
#│                                                                            │
#│   \$GREET_TEXT                                                             │
#│   - A greeting text to be displayed on the lock screen.                    │
#│   - The text will be updated every hour.                                   │
#│                                                                            │
#│   \$resolve.font                                                           │
#│   - Resolves the font name and download link.                              │
#│   - HyDE will run 'font.sh resolve' to install the font for you.           │
#│   - Note that you needed to have a network connection to download the      │
#│ font.                                                                      │
#│   - You also need to restart Hyprlock to apply the font.                   │
#│                                                                            │
#│   cmd [update:1000] \$MPRIS_TEXT                                           │
#│   - Text from media players in "Title  Author" format.                    │
#│                                                                            │
#│                                                                            │
#│   cmd [update:1000] \$SPLASH_CMD                                           │
#│   - Outputs the song title when MPRIS is available,                        │
#│   - otherwise, it will output the splash command.                          │
#│                                                                            │
#│   cmd [update:1] \$CAVA_CMD                                                │
#│   - This functionality does not work anymore.                              │
#│   - ⚠️ (Use with caution as it eats up the CPU.)                           │
#│                                                                            │
#│   cmd [update:5000] \$BATTERY_ICON                                         │
#│   - The battery icon to be displayed on the lock screen.                   │
#│   - Only works if the battery is available.                                │
#│                                                                            │                                                                    │
#└────────────────────────────────────────────────────────────────────────────┘

CONF
}

ensure_lockscreen_bg_exist() {
    if [ ! -f "$HYDE_CACHE_HOME/wallpapers/hyprlock.png" ]; then
        print_log -sec "hyprlock" -stat "setting" " $HYDE_CACHE_HOME/wallpapers/hyprlock.png"
        "${LIB_DIR}/hyde/wallpaper.sh" -s "$(readlink "$HYDE_THEME_DIR/wall.set")" --backend hyprlock
    fi
}

argparse_init "$@"
argparse_header "Hyprlock Manager"
argparse_program "hyde-shell hyprlock"
argparse_footer "Use 'hyde-shell hyprlock --help' for more information."

argparse "background,--background,-b" "" "Converts and ensures background to be a png"
argparse "profile,--profile" "" "Generates the profile picture"
argparse "mpris,--mpris" "MPRIS_PLAYER" "Handles mpris thumbnail generation" "parameter_optional"
argparse "cava,--cava" "" "Placeholder function for cava"
argparse "art,--art" "" "Prints the path to the mpris art"
argparse "--select,-S" "" "Selects the hyprlock layout"
argparse "--test" "TEST_LAYOUT" "Test layout" "parameter"
argparse "--test-preview" "TEST_PREVIEW_LAYOUT" "Test preview layout" "parameter"

argparse_finalize

case "$ARGPARSE_ACTION" in
background) fn_background ;;
profile) fn_profile ;;
mpris) fn_mpris "$MPRIS_PLAYER" ;;
cava) fn_cava ;;
art) fn_art ;;
select) fn_select ;;
test) layout_test "$TEST_LAYOUT" ;;
test-preview) rofi_test_preview "$TEST_PREVIEW_LAYOUT" ;;
*)
    ensure_lockscreen_bg_exist
    check_and_sanitize_process
    "${LIB_DIR}/hyde/app2unit.sh" -u "$HYPRLOCK_SCOPE_NAME" -t scope -- hyprlock
    exit 0
    ;;
esac

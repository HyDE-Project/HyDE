#!/usr/bin/env bash
if ! source "$(which doorwayde-shell)"; then
    echo "[$0] :: Error: doorwayde-shell not found."
    echo "[$0] :: Is DOORwayDE installed?"
    exit 1
fi

# Source argparse.sh for argument parsing
# shellcheck disable=SC1091
source "${LIB_DIR}/doorwayde/shutils/argparse.sh"

confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
animations_dir="$confDir/hypr/animations"
if [ ! -d "$animations_dir" ]; then
    notify-send -i "preferences-desktop-display" "Error" "Animations directory does not exist at $animations_dir"
    exit 1
fi

fn_select() {
    animation_items=$(find -L "$animations_dir" -name "*.lua" ! -name "disable.lua" ! -name "theme.lua" 2> /dev/null | sed 's/\.lua$//')
    if [ -z "$animation_items" ]; then
        notify-send -i "preferences-desktop-display" "Error" "No .lua files found in $animations_dir"
        exit 1
    fi
    font_scale="$ROFI_ANIMATION_SCALE"
    [[ $font_scale =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}
    font_name=${ROFI_ANIMATION_FONT:-$ROFI_FONT}
    font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
    font_name=${font_name:-$(get_hyprConf "FONT")}
    font_override="* {font: \"${font_name:-"JetBrainsMono Nerd Font"} $font_scale\";}"
    hypr_border=${hypr_border:-"$(hyprctl -j getoption decoration:rounding | jq '.int')"}
    wind_border=$((hypr_border * 3 / 2))
    elem_border=$((hypr_border == 0 ? 5 : hypr_border))
    hypr_width=${hypr_width:-"$(hyprctl -j getoption general:border_size | jq '.int')"}
    r_override="window{border:${hypr_width}px;border-radius:${wind_border}px;} wallbox{border-radius:${elem_border}px;} element{border-radius:${elem_border}px;}"
    animation_items="Disable Animation
Theme Preference
$animation_items"
    rofi_select="${HYPR_ANIMATION/theme/Theme Preference}"
    rofi_select="${rofi_select/disable/Disable Animation}"
    selected_animation=$(awk -F/ '{print $NF}' <<< "$animation_items" | rofi -dmenu -i -select "$rofi_select" \
        -p "Select animation" \
        -theme-str 'entry { placeholder: "Select animation..."; }' \
        -theme-str "$font_override" \
        -theme-str "$r_override" \
        -theme-str "$(get_rofi_pos)" \
        -theme "clipboard")
    if [ -z "$selected_animation" ]; then
        exit 0
    fi
    case $selected_animation in
        "Disable Animation")
            selected_animation="disable"
            ;;
        "Theme Preference") selected_animation="theme" ;;
    esac
    set_conf "HYPR_ANIMATION" "$selected_animation"
    fn_update
    notify-send -i "preferences-desktop-display" "Animation:" "$selected_animation"
}
fn_update() {
    [ -f "$DOORWAYDE_STATE_HOME/config" ] && source "$DOORWAYDE_STATE_HOME/config"
    [ -f "$DOORWAYDE_STATE_HOME/staterc" ] && source "$DOORWAYDE_STATE_HOME/staterc"
    current_animation=${HYPR_ANIMATION:-"theme"}
    echo "Animation updated to: $current_animation"
    cat <<- EOF > "$confDir/hypr/animations.lua"
		-- DOORwayDE controlled content -- DO NOT EDIT
		-- Edit or add presets in ./hypr/animations/ and run
		-- 'doorwayde-shell animations --select' to update this file.
		-- See https://wiki.hypr.land/Configuring/Animations/

		local animation = "$current_animation"
		require("animations/" .. animation)
	EOF
}

# Initialize argparse
argparse_init "$@"

# Set program name and header
argparse_program "doorwayde-shell animations"
argparse_header "DOORwayDE Animation Selector"

# Define arguments
argparse "--select,-S" "" "Select an animation from the available options"

# Finalize parsing
argparse_finalize

case $ARGPARSE_ACTION in
    select) fn_select ;;
    *) argparse_help ;;
esac

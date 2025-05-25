#!/usr/bin/env bash

# shellcheck source=$HOME/.local/bin/hyde-shell
# shellcheck disable=SC1091
if ! source "$(which hyde-shell)"; then
    echo "[$0] :: Error: hyde-shell not found."
    echo "[$0] :: Is HyDE installed?"
    exit 1
fi

# Set variables
confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
shaders_dir="$confDir/hypr/shaders"

# Ensure the shaders directory exists
if [ ! -d "$shaders_dir" ]; then
    notify-send -i "preferences-desktop-display" "Error" "Shaders directory does not exist at $shaders_dir"
    exit 1
fi

# Show help function
show_help() {
    cat <<HELP
Usage: $0 [OPTIONS]

Options:
    --select | -S       Select a shader from the available options
    --help   | -h       Show this help message
HELP
}

if [ -z "${*}" ]; then
    echo "No arguments provided"
    show_help
fi

# Define long options
LONG_OPTS="select,help"
SHORT_OPTS="Sh"
# Parse options
PARSED=$(getopt --options ${SHORT_OPTS} --longoptions "${LONG_OPTS}" --name "$0" -- "$@")
if [ $? -ne 0 ]; then
    exit 2
fi
eval set -- "${PARSED}"

# Default action if no arguments are provided
if [ -z "$1" ]; then
    echo "No arguments provided"
    show_help
    exit 1
fi

# Functions
fn_select() {
    # List all .frag shaders except user-defines, disable, and .cache
    shader_items=$(find "$shaders_dir" -maxdepth 1 -name "*.frag" ! -name "disable.frag" ! -name ".compiled.cache.glsl" -print0 2>/dev/null | xargs -0 -n1 basename | sed 's/\.frag$//')
    # Add 'disable' on top if it exists
    if [ -f "$shaders_dir/disable.frag" ]; then
        shader_items="disable\n$shader_items"
    fi

    if [ -z "$shader_items" ]; then
        notify-send -i "preferences-desktop-display" "Error" "No .frag files found in $shaders_dir"
        exit 1
    fi

    # Set rofi scaling
    font_scale="${ROFI_SHADER_SCALE}"
    [[ "${font_scale}" =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}

    # Set font name
    font_name=${ROFI_SHADER_FONT:-$ROFI_FONT}
    font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
    font_name=${font_name:-$(get_hyprConf "FONT")}

    # Set rofi font override
    font_override="* {font: \"${font_name:-\"JetBrainsMono Nerd Font\"} ${font_scale}\";}"

    # Window and element styling
    hypr_border=${hypr_border:-"$(hyprctl -j getoption decoration:rounding | jq '.int')"}
    wind_border=$((hypr_border * 3 / 2))
    elem_border=$((hypr_border == 0 ? 5 : hypr_border))
    hypr_width=${hypr_width:-"$(hyprctl -j getoption general:border_size | jq '.int')"}
    r_override="window{border:${hypr_width}px;border-radius:${wind_border}px;} wallbox{border-radius:${elem_border}px;} element{border-radius:${elem_border}px;}"

    # Display options using Rofi
    selected_shader=$(echo -e "$shader_items" |
        rofi -dmenu -i -select "$HYPR_SHADER" \
            -p "Select shader" \
            -theme-str "entry { placeholder: \"🎨 Select shader...\"; }" \
            -theme-str "${font_override}" \
            -theme-str "${r_override}" \
            -theme-str "$(get_rofi_pos)" \
            -theme "clipboard")

    # Exit if no selection was made
    if [ -z "$selected_shader" ]; then
        exit 0
    fi

    set_conf "HYPR_SHADER" "$selected_shader"
    fn_update "$selected_shader"
    notify-send -i "preferences-desktop-display" "Shader:" "$selected_shader"
}

concat_shader_files() {
    local files=("$@")
    true >"$shaders_dir/.compiled.cache.glsl" # Truncate file
    for f in "${files[@]}"; do
        if [ -f "$f" ]; then
            print_log -g "Processing shader" " file: $f"
            cat "$f" >>"$shaders_dir/.compiled.cache.glsl"
        fi

    done
}

parse_includes_and_update() {
    local selected_shader="$1"
    local files=()
    # Look for a comment line with !source = ... (whitespace-insensitive)
    local source_var
    source_var=$(grep -iE '^\s*//\s*!source\s*=\s*.*' "$shaders_dir/${selected_shader}.frag" 2>/dev/null | head -n1 | sed -E 's/^\s*\/\/\s*!source\s*=\s*//I' | xargs)
    if [ -n "$source_var" ]; then
        # Expand variables in the source path
        source_var=$(eval echo "$source_var")
        files+=("$source_var")
    fi

    # Automatically include .inc file if it exists
    local inc_file="$shaders_dir/${selected_shader}.inc"
    if [ -f "$inc_file" ]; then
        files+=("$inc_file")
    fi
    files+=("$shaders_dir/${selected_shader}.frag")
    concat_shader_files "${files[@]}"
    # Write the shaders.conf file with the requested banner and path
    cat <<EOF >"$confDir/hypr/shaders.conf"

#! █▀ █░█ ▄▀█ █▀▄ █▀▀ █▀█ █▀
#! ▄█ █▀█ █▀█ █▄▀ ██▄ █▀▄ ▄█

# *┌────────────────────────────────────────────────────────────────────────────┐
# *│                                                                            |
# *│ HyDE Controlled content DO NOT EDIT!                                      |
# *│ Edit or add shaders in the ./shaders/ directory                           |
# *│ and run the 'shaders.sh --select' command to update this file             |
# *│ Modify ./shaders/user-defines.frag to add your own custom defines         |
# *│ The 'shader.sh' script will automatically copy this file to the cache     |
# *│ and the cache will be used in the shader                                  |
# *│                                                                            |
# *└────────────────────────────────────────────────────────────────────────────┘

# name of the shader
\$SCREEN_SHADER = "${selected_shader}"
# path to the shader
\$SCREEN_SHADER_PATH = "$shaders_dir/${selected_shader}.frag"
# path to the compiled shader // override this in '../hyde/config.toml'
\$SCREEN_SHADER_COMPILED = ./shaders/.compiled.cache.glsl


EOF
}

fn_update() {
    parse_includes_and_update "$1"
}

# Process options
while true; do
    case "$1" in
    -S | --select)
        fn_select
        exit 0
        ;;
    --help | -h)
        show_help
        exit 0
        ;;
    --)
        shift
        break
        ;;
    *)
        echo "Invalid option: $1"
        show_help
        exit 1
        ;;
    esac
done

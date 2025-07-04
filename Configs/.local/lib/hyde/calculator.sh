#!/usr/bin/env bash

# Simple calculator using rofi's calc module

# setup rofi configuration
setup_rofi_config() {
    # font scale
    local font_scale="${ROFI_CALC_SCALE}"
    [[ "${font_scale}" =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}

    # set font name
    local font_name=${ROFI_CALC_FONT:-$ROFI_FONT}
    font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
    font_name=${font_name:-$(get_hyprConf "FONT")}

    # set rofi font override
    fnt_override="* {font: \"${font_name:-"JetBrainsMono Nerd Font"} ${font_scale}\";}"

    # border settings
    local hypr_border=${hypr_border:-"$(hyprctl -j getoption decoration:rounding | jq '.int')"}
    local wind_border=$((hypr_border * 3 / 2))
    local elem_border=$((hypr_border == 0 ? 5 : hypr_border))

    # border width
    local hypr_width=${hypr_width:-"$(hyprctl -j getoption general:border_size | jq '.int')"}

    # width and height settings
    local width="${ROFI_CALC_WIDTH:-50em}"
    local height="${ROFI_CALC_HEIGHT:-25em}"
    local lines="${ROFI_CALC_LINES:-9}"

    r_override="window{width:${width};height:${height};border:${hypr_width}px;border-radius:${wind_border}px;} entry{border-radius:${elem_border}px;} element{border-radius:${elem_border}px;} listview{lines:${lines};columns:2;}"
}

main() {
    # Source hyde-shell if available to get common functions
    if command -v hyde-shell >/dev/null 2>&1; then
        source "$(command -v hyde-shell)" || true
    fi

    setup_rofi_config

    if [[ -v customRoFile ]]; then
        rofi -show calc -modi calc -no-show-match -no-sort -config "${customRoFile}"
    else
        rofi -show calc -modi calc -no-show-match -no-sort -theme-str "${fnt_override}" -theme-str "${r_override}" -config "${roFile:-clipboard}"
    fi
}

usage() {
    cat <<EOF
--rasi <PATH>     Set custom .rasi file. Note that this removes all overrides

EOF
    exit 1
}

while (($# > 0)); do
    case $1 in
    --rasi)
        [[ -z ${2} ]] && echo "[error] --rasi requires a file.rasi config file" && exit 1
        customRoFile=${2}
        shift
        ;;
    *)
        echo "Unknown option: $1"
        usage
        ;;
    esac
    shift
done

main "$@"

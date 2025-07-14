#!/usr/bin/env bash

[[ "${HYDE_SHELL_INIT}" -ne 1 ]] && eval "$(hyde-shell init)"

# setup rofi configuration
setup_rofi_config() {
    # font scale
    local font_scale="${ROFI_BOOKMARKS_SCALE}"
    [[ "${font_scale}" =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}

    # set font name
    local font_name=${ROFI_BOOKMARKS_FONT:-$ROFI_FONT}
    font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
    font_name=${font_name:-$(get_hyprConf "FONT")}

    # set rofi font override
    font_override="* {font: \"${font_name:-"JetBrainsMono Nerd Font"} ${font_scale}\";}"

    # border settings
    local hypr_border=${hypr_border:-"$(hyprctl -j getoption decoration:rounding | jq '.int')"}
    local wind_border=$((hypr_border * 3 / 2))
    local elem_border=$((hypr_border == 0 ? 5 : hypr_border))

    # border width
    local hypr_width=${hypr_width:-"$(hyprctl -j getoption general:border_size | jq '.int')"}
    r_override="window{border:${hypr_width}px;border-radius:${wind_border}px;}wallbox{border-radius:${elem_border}px;} element{border-radius:${elem_border}px;}"
}

setup_rofi_config
browser_name=$(basename "$(xdg-settings get default-web-browser)" .desktop)
browser_name=${BROWSER:-${browser_name}}

rofi -modi "bookmarks:python $LIB_DIR/hyde/bookmarks.py \
--list" -i \
    -theme-str "entry { placeholder: \" 🌐 Launch: ${browser_name} \";}" \
    -config "${ROFI_BOOKMARK_STYLE:-clipboard}" \
    -theme-str "${r_override}" \
    -theme-str "${font_override}" \
    -theme-str "window {width: 50%;}" \
    -show bookmarks

#!/usr/bin/env bash

#// set variables

# shellcheck source=$HOME/.local/bin/hyde-shell
# shellcheck disable=SC1091
if ! source "$(which hyde-shell)"; then
    echo "[wallbash] code :: Error: hyde-shell not found."
    echo "[wallbash] code :: Is HyDE installed?"
    exit 1
fi

rofiAssetDir="${SHARE_DIR}/hyde/rofi/assets"

hypr_border=${hypr_border:-"$(hyprctl -j getoption decoration:rounding | jq '.int')"}

#// scale for monitor
mon_data=$(hyprctl -j monitors)
mon_x_res=$(jq '.[] | select(.focused==true) | if (.transform % 2 == 0) then .width else .height end' <<<"${mon_data}")
mon_scale=$(jq '.[] | select(.focused==true) | .scale' <<<"${mon_data}" | sed "s/\.//")
mon_x_res=$((mon_x_res * 100 / mon_scale))

selector_menu() {

    #// set rofi scaling
    font_scale="${ROFI_THEME_MENU_SCALE}"
    [[ "${font_scale}" =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}

    # set font name
    font_name=${ROFI_THEME_MENU_FONT:-$ROFI_FONT}
    font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
    font_name=${font_name:-$(get_hyprConf "FONT")}

    # set rofi font override
    font_override="* {font: \"${font_name:-"JetBrainsMono Nerd Font"} ${font_scale}\";}"

    elem_border=$((hypr_border * 5))
    icon_border=$((elem_border - 5))
    elm_width=$((256 * 2)) #TODO: This is 256 as the images are 256x256 px
    max_avail=$((mon_x_res - (4 * font_scale)))
    col_count=$((max_avail / elm_width))
    [[ "${col_count}" -gt 5 ]] && col_count=5
    r_override="window{width:100%;} 
                listview{columns:${col_count};} 
                element{orientation:vertical;border-radius:${elem_border}px;} 
                element-icon{border-radius:${icon_border}px;size:20em;} 
                element-text{enabled:false;}"

    #// launch rofi menu
    RofiSel=$(
        find "${rofiAssetDir}" -name "theme_style_*" |
            awk -F '[_.]' '{print $((NF - 1))}' |
            while read -r styleNum; do
                echo -en "${styleNum}\x00icon\x1f${rofiAssetDir}/theme_style_${styleNum}.png\n"
            done | sort -n |
            rofi -dmenu \
                -theme-str "${r_override}" \
                -select "${ROFI_THEME_STYLE}" \
                -theme "${ROFI_THEME_MENU_STYLE:-selector}"
    )

    #// apply selected theme
    if [ -n "${RofiSel}" ]; then
        #// extract selected style number ('Style 1' -> '1')
        selectedStyle=$(echo "${RofiSel}" | awk -F '\x00' '{print $1}' | sed 's/Style //')

        #// notify the user
        notify-send -a "HyDe Alert" -i "${rofiAssetDir}/theme_style_${selectedStyle}.png" "Style ${selectedStyle} applied..."

        #// save selection in config file
        set_conf "ROFI_THEME_STYLE" "${selectedStyle}"
    fi
    exit 0
}

help_message() {
    cat <<HELP
Usage: $(basename "${0}") --select-menu|-s  [style]

menu style:
--select-menu|-s        Select a menu style for this program

selector style:
quad|2      quad style
square|1    square style 

HELP
    exit 0
}

case "$1" in

-m | -s | --select-menu)
    selector_menu
    ;;
-*)
    help_message
    ;;

*)

    #// set rofi scaling
    # shellcheck disable=SC2153
    font_scale="${ROFI_THEME_SCALE}"
    [[ "${font_scale}" =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}

    # set font name
    font_name=${ROFI_THEME_FONT:-$ROFI_FONT}
    font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
    font_name=${font_name:-$(get_hyprConf "FONT")}

    # set rofi font override
    font_override="* {font: \"${font_name:-"JetBrainsMono Nerd Font"} ${font_scale}\";}"

    # shellcheck disable=SC2154
    elem_border=$((hypr_border * 5))
    icon_border=$((elem_border - 5))

    #// generate config

    ROFI_THEME_STYLE="${ROFI_THEME_STYLE:-1}"
    # shellcheck disable=SC2154
    case "${ROFI_THEME_STYLE}" in
    2 | "quad") # adapt to style 2
        elm_width=$(((20 + 12) * font_scale * 2))
        max_avail=$((mon_x_res - (4 * font_scale)))
        col_count=$((max_avail / elm_width))
        r_override="window{width:100%;background-color:#00000003;} 
                            listview{columns:${col_count};} 
                            element{border-radius:${elem_border}px;background-color:@main-bg;}
                            element-icon{size:20em;border-radius:${icon_border}px 0px 0px ${icon_border}px;}"
        thmbExtn="quad"
        ROFI_THEME_STYLE="selector"
        ;;
    1 | "square") # default to style 1
        elm_width=$(((23 + 12 + 1) * font_scale * 2))
        max_avail=$((mon_x_res - (4 * font_scale)))
        col_count=$((max_avail / elm_width))
        r_override="window{width:100%;} 
                            listview{columns:${col_count};} 
                            element{border-radius:${elem_border}px;padding:0.5em;} 
                            element-icon{size:23em;border-radius:${icon_border}px;}"
        thmbExtn="sqre"
        ROFI_THEME_STYLE="selector"
        ;;
    esac
    ;;

esac
#// launch rofi menu

get_themes
# shellcheck disable=SC2154
rofiSel=$(
    i=0
    while [ $i -lt ${#thmList[@]} ]; do
        echo -en "${thmList[$i]}\x00icon\x1f${thmbDir}/$(set_hash "${thmWall[$i]}").${thmbExtn:-sqre}\n"
        i=$((i + 1))
    done | rofi -dmenu \
        -theme-str "${font_override}" \
        -theme-str "${r_override}" \
        -theme "${ROFI_THEME_STYLE:-selector}" \
        -select "${HYDE_THEME}"
)

#// apply theme

if [ -n "${rofiSel}" ]; then
    "${LIB_DIR}/hyde/theme.switch.sh" -s "${rofiSel}"
    # shellcheck disable=SC2154
    notify-send -a "HyDE Alert" -i "${iconsDir}/Wallbash-Icon/hyde.png" " ${rofiSel}"
fi

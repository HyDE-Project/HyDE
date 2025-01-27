#!/usr/bin/env sh

#// set variables
scrDir="$(dirname "$(realpath "$0")")"
source "${scrDir}/globalcontrol.sh"

case "$1" in

  -s)
            #// set rofi scaling
            [[ "${rofiScale}" =~ ^[0-9]+$ ]] || rofiScale=15
            r_scale="configuration {font: \"JetBrainsMono Nerd Font ${rofiScale}\";}"
            elem_border=$(( hypr_border * 5 ))
            icon_border=$(( elem_border - 5 ))

            #// defining 2 png files to select from
            options="Style 1\x00icon\x1f${rofiAssetDir}/theme_style_1.png\nStyle 2\x00icon\x1f${rofiAssetDir}/theme_style_2.png"

            #// generate config
            mon_x_res=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .width')
            mon_scale=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .scale' | sed "s/\.//")
            mon_x_res=$(( mon_x_res * 100 / mon_scale ))

            elm_width=$(( (20 + 12 + 16 ) * rofiScale ))
            max_avail=$(( mon_x_res - (4 * rofiScale) ))
            col_count=$(( max_avail / elm_width ))
            [[ "${col_count}" -gt 5 ]] && col_count=5
            r_override="window{width:100%;} listview{columns:${col_count};} element{orientation:vertical;border-radius:${elem_border}px;} element-icon{border-radius:${icon_border}px;size:20em;} element-text{enabled:false;}"

            #// launch rofi menu 
            RofiSel=$(echo -e "$options" | rofi -dmenu -theme-str "${r_override}" -config "${rofiConf}/selector.rasi")

            #// apply selected theme
            if [ ! -z "${RofiSel}" ]; then
                #// extract selected style number ('Style 1' -> '1')
                selectedStyle=$(echo "${RofiSel}" | awk -F '\x00' '{print $1}' | sed 's/Style //')

                #// notify the user
                notify-send -a "t1" -i "${rofiAssetDir}/theme_style_${selectedStyle}.png" "Style ${selectedStyle} applied..."

                #// save selection in config file
                set_conf "ROFI_THEME_STYLE" "${selectedStyle}"
            fi
           ;;

   *)

            #// set rofi scaling
            rofiScale="${ROFI_THEME_SCALE}"
            [[ "${rofiScale}" =~ ^[0-9]+$ ]] || rofiScale=${ROFI_SCALE:-10}
            r_scale="configuration {font: \"JetBrainsMono Nerd Font ${rofiScale}\";}"
            # shellcheck disable=SC2154
            elem_border=$((hypr_border * 5))
            icon_border=$((elem_border - 5))

            #// scale for monitor

            mon_x_res=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .width')
            mon_scale=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .scale' | sed "s/\.//")
            mon_x_res=$((mon_x_res * 100 / mon_scale))

            #// generate config

            ROFI_THEME_STYLE="${ROFI_THEME_STYLE:-1}"
            # shellcheck disable=SC2154
            case "${ROFI_THEME_STYLE}" in
            2 | "quad") # adapt to style 2
                elm_width=$(((20 + 12) * rofiScale * 2))
                max_avail=$((mon_x_res - (4 * rofiScale)))
                col_count=$((max_avail / elm_width))
                r_override="window{width:100%;background-color:#00000003;} 
                            listview{columns:${col_count};} 
                            element{border-radius:${elem_border}px;background-color:@main-bg;}
                            element-icon{size:20em;border-radius:${icon_border}px 0px 0px ${icon_border}px;}"
                thmbExtn="quad"
                ROFI_THEME_STYLE="selector"
                ;;
            1 | "square") # default to style 1
                elm_width=$(((23 + 12 + 1) * rofiScale * 2))
                max_avail=$((mon_x_res - (4 * rofiScale)))
                col_count=$((max_avail / elm_width))
                r_override="window{width:100%;} 
                            listview{columns:${col_count};} 
                            element{border-radius:${elem_border}px;padding:0.5em;} 
                            element-icon{size:23em;border-radius:${icon_border}px;}"
                thmbExtn="sqre"
                ROFI_THEME_STYLE="selector"
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
                    -theme-str "${r_scale}" \
                    -theme-str "${r_override}" \
                    -theme "${ROFI_THEME_STYLE:-selector}" \
                    -select "${HYDE_THEME}"
            )

            #// apply theme

            if [ -n "${rofiSel}" ]; then
                "${scrDir}/themeswitch.sh" -s "${rofiSel}"
                # shellcheck disable=SC2154
                notify-send -a "HyDE Alert" -i "${iconsDir}/Wallbash-Icon/hyde.png" " ${rofiSel}"
            fi
            ;;
           
    esac


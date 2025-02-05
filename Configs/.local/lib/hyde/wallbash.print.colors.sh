#!/usr/bin/env bash
# shellcheck disable=SC2154

if [[ -z $dcol_pry1 ]]; then
    cacheDir=${cacheDir:-$HOME/.cache/hyde}
    # shellcheck disable=SC1091
    source "${cacheDir}/wall.dcol"
fi

# Function to convert hex to RGB
hex_to_rgb() {
    local hex=$1
    echo "$((16#${hex:0:2})) $((16#${hex:2:2})) $((16#${hex:4:2}))"
}

print_color() {
    echo -n " "
    for hex_color in "$@"; do
        local rgb_color
        rgb_color=$(hex_to_rgb "$hex_color")
        # echo -en "\e[48;2;${rgb_color// /;};1m        \e[0m "
        echo -en "\e[48;2;${rgb_color// /;};m  \e[0m"
    done
    echo
}

# Print grouped colors
print_color "$dcol_pry1" "$dcol_txt1" "$dcol_1xa1" "$dcol_1xa2" "$dcol_1xa3" "$dcol_1xa4" "$dcol_1xa5" "$dcol_1xa6" "$dcol_1xa7" "$dcol_1xa8" "$dcol_1xa9"
print_color "$dcol_pry2" "$dcol_txt2" "$dcol_2xa1" "$dcol_2xa2" "$dcol_2xa3" "$dcol_2xa4" "$dcol_2xa5" "$dcol_2xa6" "$dcol_2xa7" "$dcol_2xa8" "$dcol_2xa9"
print_color "$dcol_pry3" "$dcol_txt3" "$dcol_3xa1" "$dcol_3xa2" "$dcol_3xa3" "$dcol_3xa4" "$dcol_3xa5" "$dcol_3xa6" "$dcol_3xa7" "$dcol_3xa8" "$dcol_3xa9"
print_color "$dcol_pry4" "$dcol_txt4" "$dcol_4xa1" "$dcol_4xa2" "$dcol_4xa3" "$dcol_4xa4" "$dcol_4xa5" "$dcol_4xa6" "$dcol_4xa7" "$dcol_4xa8" "$dcol_4xa9"

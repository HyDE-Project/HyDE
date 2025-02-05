#!/usr/bin/env bash

# Set variables
scrDir=$(dirname "$(realpath "$0")")
scrDir="${scrDir:-$HOME/.config/hyde}"
# shellcheck disable=SC1091
source "$scrDir/globalcontrol.sh"
confDir="${confDir:-$XDG_CONFIG_HOME}"
cacheDir="${cacheDir:-$XDG_CACHE_HOME/hyde}"

# Set rofi scaling
font_scale="${ROFI_EMOJI_SCALE}"
[[ "${font_scale}" =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}

# set font name
font_name=${ROFI_EMOJI_FONT:-$ROFI_FONT}
font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
font_name=${font_name:-$(get_hyprConf "FONT")}

# set rofi font override
font_override="* {font: \"${font_name:-"JetBrainsMono Nerd Font"} ${font_scale}\";}"

hypr_border=${hypr_border:-"$(hyprctl -j getoption decoration:rounding | jq '.int')"}
wind_border=$((hypr_border * 3 / 2))
elem_border=$((hypr_border == 0 ? 5 : hypr_border))

# Set rofi location
rofi_position=$(get_rofi_pos)

hypr_width=${hypr_width:-"$(hyprctl -j getoption general:border_size | jq '.int')"}
r_override="window{border:${hypr_width}px;border-radius:${wind_border}px;}wallbox{border-radius:${elem_border}px;} element{border-radius:${elem_border}px;}"

save_recent() {
    #? Prepend the selected emoji to the top of the recentData file
    # sed -i "1i\\$selEmoji" "${recentData}"
    awk -v var="$dataEmoji" 'BEGIN{print var} {print}' "${recentData}" >temp && mv temp "${recentData}"
    #?  Use awk to remove duplicates and empty lines, moving the most recent emoji to the top
    awk 'NF' "${recentData}" | awk '!seen[$0]++' >temp && mv temp "${recentData}"
}

# Loop through all arguments
while (($# > 0)); do
    case $1 in
    --style | -s)
        if (($# > 1)); then
            emoji_style="$2"
            shift # Consume the value argument
        else
            print_log +y "[warn] " "--style needs argument"
            emoji_style="clipboard"
            shift
        fi
        ;;
    --rasi)
        [[ -z ${2} ]] && print_log +r "[error] " +y "--rasi requires an file.rasi config file" && exit 1
        useRofile=${2}
        shift
        ;;
    --deps)
        resolve_deps
        exit 0
        ;;
    -*)
        cat <<HELP
Usage:
--style [1 | 2]     Change Emoji style
                    Add 'emoji_style=[1|2]' variable in .~/.config/hyde/config.toml'
                        1 = list
                        2 = grid
                    or select styles from 'rofi-theme-selector'
HELP

        exit 0
        ;;
    esac
    shift # Shift off the current option being processed
done

emojiDir=${XDG_DATA_HOME:-$HOME/.local/share}/hyde
emojiData="${emojiDir}/emoji.db"
recentData="${cacheDir}/landing/show_emoji.recent"

if [[ ! -f "${recentData}" ]]; then
    echo "    Arch linux I use Arch BTW" >"${recentData}"
fi
#? Read the contents of recent.db and main.db separately
recent_entries=$(cat "${recentData}")
main_entries=$(cat "${emojiData}")
#? Combine the recent entries with the main entries
combined_entries="${recent_entries}\n${main_entries}"
#? Remove duplicates from the combined entries
unique_entries=$(echo -e "${combined_entries}" | awk '!seen[$0]++')

if [[ -n ${useRofile} ]]; then
    dataEmoji=$(rofi -dmenu -i -config "${useRofile}" <<<"${unique_entries}")
else
    emoji_style="${emoji_style:-$ROFI_EMOJI_STYLE}"
    case ${emoji_style} in
    2 | grid)
        size_override=""
        dataEmoji=$(rofi -dmenu -i -display-columns 1 \
            -display-column-separator " " \
            -theme-str "listview {columns: 8;}" \
            -theme-str "entry { placeholder: \" 🔎 Emoji\";} ${rofi_position} ${r_override}" \
            -theme-str "${font_override}" \
            -theme-str "${size_override}" \
            -theme "clipboard" <<<"${unique_entries}")
        ;;
    1 | list)
        dataEmoji=$(rofi -dmenu -multi-select -i \
            -theme-str "entry { placeholder: \" 🔎 Emoji\";} ${rofi_position} ${r_override}" \
            -theme-str "${font_override}" \
            -theme "clipboard" <<<"${unique_entries}")
        ;;
    *)
        dataEmoji=$(rofi -dmenu -multi-select -i \
            -theme-str "entry { placeholder: \" 🔎 Emoji\";} ${rofi_position} ${r_override}" \
            -theme-str "${font_override}" \
            -theme "${emoji_style:-clipboard}" <<<"${unique_entries}")
        ;;
    esac
fi

# selEmoji=$(echo -n "${selEmoji}" | cut -d' ' -f1 | tr -d '\n' | wl-copy)
trap save_recent EXIT
selEmoji=$(printf "%s" "${dataEmoji}" | cut -d' ' -f1 | tr -d '\n\r')
[ -z "${selEmoji}" ] && exit 0
wl-copy "${selEmoji}"
paste_string "${*}"

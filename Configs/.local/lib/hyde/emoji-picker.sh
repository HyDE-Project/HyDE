#!/usr/bin/env bash

# shellcheck disable=SC1090
if ! source "$(command -v hyde-shell)"; then
    echo "[wallbash] code :: Error: hyde-shell not found."
    echo "[wallbash] code :: Is HyDE installed?"
    exit 1
fi

# Define paths and files
emoji_dir=${HYDE_DATA_HOME:-$HOME/.local/share/hyde}
emoji_data="${emoji_dir}/emoji.db"
cache_dir="${HYDE_CACHE_HOME:-$HOME/.cache/hyde}"
recent_data="${cache_dir}/landing/show_emoji.recent"

# checks if an emoji entry is valid
is_valid_emoji() {
    local emoji_entry="$1"

    # return false if emoji is empty or unique_entries is not set
    [[ -z "${emoji_entry}" || -z "${unique_entries}" ]] && return 1

    # uses bash's pattern matching instead of echo and grep
    echo -e "${unique_entries}" | grep -Fxq "${emoji_entry}"
}

# save selected emoji to recent list, remove duplicates
save_recent() {
    is_valid_emoji "${data_emoji}" || return 0
    awk -v var="$data_emoji" 'BEGIN{print var} {print}' "${recent_data}" >temp && mv temp "${recent_data}"
    awk 'NF' "${recent_data}" | awk '!seen[$0]++' >temp && mv temp "${recent_data}"
}

# rofi settings
setup_rofi_config() {
    # font scale
    local font_scale="${ROFI_EMOJI_SCALE}"
    [[ "${font_scale}" =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}

    # font name
    local font_name=${ROFI_EMOJI_FONT:-$ROFI_FONT}
    font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
    font_name=${font_name:-$(get_hyprConf "FONT")}

    # rofi font override
    font_override="* {font: \"${font_name:-"JetBrainsMono Nerd Font"} ${font_scale}\";}"

    # border settings
    local hypr_border=${hypr_border:-"$(hyprctl -j getoption decoration:rounding | jq '.int')"}
    local wind_border=$((hypr_border * 3 / 2))
    local elem_border=$((hypr_border == 0 ? 5 : hypr_border))

    # rofi position
    rofi_position=$(get_rofi_pos)

    # border width
    local hypr_width=${hypr_width:-"$(hyprctl -j getoption general:border_size | jq '.int')"}
    r_override="window{border:${hypr_width}px;border-radius:${wind_border}px;}wallbox{border-radius:${elem_border}px;} element{border-radius:${elem_border}px;}"
}

# Parse command line arguments
parse_arguments() {
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
            use_rofile=${2}
            shift
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
}

# Get emoji selection from rofi
get_emoji_selection() {
    if [[ -n ${use_rofile} ]]; then
        echo "${unique_entries}" | rofi -dmenu -i -config "${use_rofile}"
    else
        local style_type="${emoji_style:-$ROFI_EMOJI_STYLE}"
        case ${style_type} in
        2 | grid)
            local size_override=""
            echo "${unique_entries}" | rofi -dmenu -i -display-columns 1 \
                -display-column-separator " " \
                -theme-str "listview {columns: 8;}" \
                -theme-str "entry { placeholder: \" 🔎 Emoji\";} ${rofi_position} ${r_override}" \
                -theme-str "${font_override}" \
                -theme-str "${size_override}" \
                -theme "clipboard"
            ;;
        1 | list)
            echo "${unique_entries}" | rofi -dmenu -multi-select -i \
                -theme-str "entry { placeholder: \" 🔎 Emoji\";} ${rofi_position} ${r_override}" \
                -theme-str "${font_override}" \
                -theme "clipboard"
            ;;
        *)
            echo "${unique_entries}" | rofi -dmenu -multi-select -i \
                -theme-str "entry { placeholder: \" 🔎 Emoji\";} ${rofi_position} ${r_override}" \
                -theme-str "${font_override}" \
                -theme "${style_type:-clipboard}"
            ;;
        esac
    fi
}

main() {
    # Parse command line arguments
    parse_arguments "$@"

    # create recent data file if it doesn't exist
    if [[ ! -f "${recent_data}" ]]; then
        mkdir -p "$(dirname "${recent_data}")"
        echo " Arch linux - I use Arch, BTW" >"${recent_data}"
    fi

    # read recent and main entries
    local recent_entries main_entries
    recent_entries=$(cat "${recent_data}")
    main_entries=$(cat "${emoji_data}")

    # combine entries and remove duplicates
    combined_entries="${recent_entries}\n${main_entries}"
    unique_entries=$(echo -e "${combined_entries}" | awk '!seen[$0]++')

    # rofi config
    setup_rofi_config

    # get emoji selection from rofi
    data_emoji=$(get_emoji_selection)

    # avoid copying typed text to clipboard, only copy valid emoji
    [ -z "${data_emoji}" ] && exit 0

    # extract and copy selected emoji(s)
    local sel_emoji
    sel_emoji=$(printf "%s" "${data_emoji}" | cut -d' ' -f1 | tr -d '\n\r')

    wl-copy "${sel_emoji}"
    paste_string "${@}"
}

# exit trap to save recent emojis
trap save_recent EXIT

# run main function
main "$@"

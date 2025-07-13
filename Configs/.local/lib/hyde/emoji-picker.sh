#!/usr/bin/env bash

if ! source "$(command -v hyde-shell)"; then
    echo "[wallbash] code :: Error: hyde-shell not found."
    echo "[wallbash] code :: Is HyDE installed?"
    exit 1
fi

emoji_dir=${HYDE_DATA_HOME:-$HOME/.local/share/hyde}
emoji_data="${emoji_dir}/emoji.db"
cache_dir="${HYDE_CACHE_HOME:-$HOME/.cache/hyde}"
recent_data="${cache_dir}/landing/show_emoji.recent"

save_recent_entry() {
    local emoji_line="$1"
    {
        echo "${emoji_line}"
        cat "${recent_data}"
    } | awk '!seen[$0]++' >temp && mv temp "${recent_data}"
}

setup_rofi_config() {
    local font_scale="${ROFI_EMOJI_SCALE}"
    [[ "${font_scale}" =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}

    local font_name=${ROFI_EMOJI_FONT:-$ROFI_FONT}
    font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
    font_name=${font_name:-$(get_hyprConf "FONT")}

    font_override="* {font: \"${font_name:-"JetBrainsMono Nerd Font"} ${font_scale}\";}"

    local hypr_border=${hypr_border:-"$(hyprctl -j getoption decoration:rounding | jq '.int')"}
    local wind_border=$((hypr_border * 3 / 2))
    local elem_border=$((hypr_border == 0 ? 5 : hypr_border))

    rofi_position=$(get_rofi_pos)

    local hypr_width=${hypr_width:-"$(hyprctl -j getoption general:border_size | jq '.int')"}
    r_override="window{border:${hypr_width}px;border-radius:${wind_border}px;}listview{border-radius:${elem_border}px;} element{border-radius:${elem_border}px;}"
}

get_emoji_selection() {
    local style_type="${emoji_style:-$ROFI_EMOJI_STYLE}"
    local size_override=""

    if [[ -n ${use_rofile} ]]; then
        awk '!seen[$0]++' "${recent_data}" "${emoji_data}" | rofi -dmenu -i -config "${use_rofile}" \
            -matching fuzzy -no-custom
    else
        case ${style_type} in
        2 | grid)
            awk '!seen[$0]++' "${recent_data}" "${emoji_data}" | rofi -dmenu -i -display-columns 1 \
                -display-column-separator " " \
                -theme-str "listview {columns: 10;}" \
                -theme-str "entry { placeholder: \" 🔎 Emoji\";} ${rofi_position} ${r_override}" \
                -theme-str "${font_override}" \
                -theme-str "${size_override}" \
                -theme "clipboard" \
                -matching fuzzy -no-custom
            ;;
        1 | list)
            awk '!seen[$0]++' "${recent_data}" "${emoji_data}" | rofi -dmenu -i \
                -theme-str "entry { placeholder: \" 🔎 Emoji\";} ${rofi_position} ${r_override}" \
                -theme-str "${font_override}" \
                -theme "clipboard" \
                -matching fuzzy -no-custom
            ;;
        *)
            awk '!seen[$0]++' "${recent_data}" "${emoji_data}" | rofi -dmenu -i \
                -theme-str "entry { placeholder: \" 🔎 Emoji\";} ${rofi_position} ${r_override}" \
                -theme-str "${font_override}" \
                -theme "${style_type:-clipboard}" \
                -matching fuzzy -no-custom
            ;;
        esac
    fi
}

parse_arguments() {
    while (($# > 0)); do
        case $1 in
        --style | -s)
            if (($# > 1)); then
                emoji_style="$2"
                shift
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
--style [1 | 2]         Change Emoji style
                        Add 'emoji_style=[1|2]' variable in ~/.config/hyde/config.toml'
                            1 = list
                            2 = grid
                        or select styles from 'rofi-theme-selector'
HELP

            exit 0
            ;;
        esac
        shift
    done
}

main() {
    parse_arguments "$@"

    if [[ ! -f "${recent_data}" ]]; then
        mkdir -p "$(dirname "${recent_data}")"
        echo " Arch linux - I use Arch, BTW" >"${recent_data}"
    fi

    setup_rofi_config

    data_emoji=$(get_emoji_selection)

    [[ -z "${data_emoji}" ]] && exit 0

    local selected_emoji_char=""
    selected_emoji_char=$(printf "%s" "${data_emoji}" | cut -d' ' -f1)

    if [[ -n "${selected_emoji_char}" ]]; then
        wl-copy "${selected_emoji_char}"
        save_recent_entry "${data_emoji}"
        paste_string "${@}"
    fi
}

main "$@"

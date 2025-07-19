#!/usr/bin/env bash

[[ "${HYDE_SHELL_INIT}" -ne 1 ]] && eval "$(hyde-shell init)"

glyph_dir=${HYDE_DATA_HOME:-$HOME/.local/share/hyde}
glyph_data="${glyph_dir}/glyph.db"
cache_dir="${HYDE_CACHE_HOME:-$HOME/.cache/hyde}"
recent_data="${cache_dir}/landing/show_glyph.recent"

save_recent_entry() {
    local glyph_line="$1"
    (
        echo "${glyph_line}"
        cat "${recent_data}"
    ) | awk '!seen[$0]++' >temp && mv temp "${recent_data}"
}

setup_rofi_config() {
    local font_scale="${ROFI_GLYPH_SCALE}"
    [[ "${font_scale}" =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}

    local font_name=${ROFI_GLYPH_FONT:-$ROFI_FONT}
    font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
    font_name=${font_name:-$(get_hyprConf "FONT")}

    font_override="* {font: \"${font_name:-"JetBrainsMono Nerd Font"} ${font_scale}\";}"

    local hypr_border=${hypr_border:-"$(hyprctl -j getoption decoration:rounding | jq '.int')"}
    local wind_border=$((hypr_border * 3 / 2))
    local elem_border=$((hypr_border == 0 ? 5 : hypr_border))

    rofi_position=$(get_rofi_pos)

    local hypr_width=${hypr_width:-"$(hyprctl -j getoption general:border_size | jq '.int')"}
    r_override="window{border:${hypr_width}px;border-radius:${wind_border}px;}listview{border-radius:${elem_border}px;} element{border-radius:${elem_border}px;}"

    rofi_args+=(
        "${ROFI_GLYPH_ARGS[@]}" 
        -i
        -matching fuzzy
        -no-custom
        -theme-str "entry { placeholder: \"   Glyph\";} ${rofi_position}"
        -theme-str "${font_override}"
        -theme-str "${r_override}"
        -theme "${ROFI_GLYPH_STYLE:-clipboard}"
    )
}

get_glyph_selection() {
    awk '!seen[$0]++' "${recent_data}" "${glyph_data}" | rofi -dmenu "${rofi_args[@]}"
}

main() {
    if [[ ! -f "${recent_data}" ]]; then
        mkdir -p "$(dirname "${recent_data}")"
        printf "\tArch linux - I use Arch, BTW\n" >"${recent_data}"
    fi

    setup_rofi_config

    data_glyph=$(get_glyph_selection)

    [[ -z "${data_glyph}" ]] && exit 0

    local sel_glyph=""
    sel_glyph=$(printf "%s" "${data_glyph}" | cut -d$'\t' -f1 | xargs)

    if [[ -n "${sel_glyph}" ]]; then
        wl-copy "${sel_glyph}"
        save_recent_entry "${data_glyph}"
        paste_string "${@}"
    fi
}

main "$@"

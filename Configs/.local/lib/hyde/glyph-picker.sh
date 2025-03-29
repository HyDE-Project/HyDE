#!/usr/bin/env bash

# shellcheck disable=SC1090
if ! source "$(command -v hyde-shell)"; then
    echo "[wallbash] code :: Error: hyde-shell not found."
    echo "[wallbash] code :: Is HyDE installed?"
    exit 1
fi

#* This glyph Data is from `https://www.nerdfonts.com/cheat-sheet`
#* I don't own any of it
#TODO:   Needed a way to fetch the glyph from the NerdFonts source.
#TODO:    find a way make the  DB update
#TODO:    make the update Script run on User space

# Define paths and files
glyph_dir=${HYDE_DATA_HOME:-$HOME/.local/share/hyde}
glyph_data="${glyph_dir}/glyph.db"
cache_dir="${HYDE_CACHE_HOME:-$HOME/.cache/hyde}"
recent_data="${cache_dir}/landing/show_glyph.recent"

# save selected glyph to recent list, remove duplicates
save_recent() {
    awk -v var="$data_glyph" 'BEGIN{print var} {print}' "${recent_data}" >temp && mv temp "${recent_data}"
    awk 'NF' "${recent_data}" | awk '!seen[$0]++' >temp && mv temp "${recent_data}"
}

# rofi settings
setup_rofi_config() {
    # font scale
    local font_scale="${ROFI_GLYPH_SCALE}"
    [[ "${font_scale}" =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}

    # font name
    local font_name=${ROFI_GLYPH_FONT:-$ROFI_FONT}
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

# rofi menu, get selection
get_glyph_selection() {
    echo "${unique_entries}" | rofi -dmenu -multi-select -i \
        -theme-str "entry { placeholder: \" 🔣 Glyph\";} ${rofi_position}" \
        -theme-str "${font_override}" \
        -theme-str "${r_override}" \
        -theme "${ROFI_GLYPH_STYLE:-clipboard}"
}

main() {
    # create recent data file if it doesn't exist
    if [[ ! -f "${recent_data}" ]]; then
        mkdir -p "$(dirname "${recent_data}")"
        echo " Arch linux - I use Arch, BTW" >"${recent_data}"
    fi

    # read recent and main entries
    local recent_entries
    recent_entries=$(cat "${recent_data}")
    local main_entries
    main_entries=$(cat "${glyph_data}")

    # combine entries and remove duplicates
    combined_entries="${recent_entries}\n${main_entries}"
    unique_entries=$(echo -e "${combined_entries}" | awk '!seen[$0]++')

    # rofi config
    setup_rofi_config

    # get glyph selection from rofi
    data_glyph=$(get_glyph_selection)

    # extract and copy selected glyph
    local sel_glyph

    # using bash's built in param expansion instead of cut
    sel_glyph="${data_glyph%% *}"
    sel_glyph="${sel_glyph//[$'\n\r']/}"
    # sel_glyph=$(printf "%s" "${data_glyph}" | cut -d' ' -f1 | tr -d '\n\r')

    wl-copy "${sel_glyph}"
    paste_string "${@}"
}

# exit trap to save recent glyphs
trap save_recent EXIT

# run main function
main "$@"

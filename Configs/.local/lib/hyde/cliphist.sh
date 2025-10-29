#!/usr/bin/env bash

pkill -u "$USER" rofi && exit 0

[[ "${HYDE_SHELL_INIT}" -ne 1 ]] && eval "$(hyde-shell init)"

# define paths and files
cache_dir="${HYDE_CACHE_HOME:-$HOME/.cache/hyde}"
favorites_file="${cache_dir}/landing/cliphist_favorites"
[ -f "$HOME/.cliphist_favorites" ] && favorites_file="$HOME/.cliphist_favorites"
cliphist_style="${ROFI_CLIPHIST_STYLE:-clipboard}"

process_deletion() {

    # handle delete mode
    while IFS= read -r line; do
        echo "${line}"
        if [[ "${line}" = ":w:i:p:e:"* ]]; then
            "${0}" --wipe
            break
        elif [[ "${line}" = ":b:a:r:"* ]]; then
            "${0}" --delete
            break
        elif [ -n "$line" ]; then
            cliphist delete <<<"${line}"
            notify-send "Deleted" "${line}"
        fi
    done
    exit 0
}

# process clipboard selections for multi-select mode
process_selections() {
    # Read the entire input into an array
    mapfile -t lines #! Not POSIX compliant
    # Get the total number of lines
    total_lines=${#lines[@]}

    handle_special_commands "${lines[@]}"

    # process regular clipboard items
    local output=""
    # Iterate over each line in the array
    for ((i = 0; i < total_lines; i++)); do
        local line="${lines[$i]}"
        local decoded_line
        decoded_line="$(echo -e "$line\t" | cliphist decode)"
        if [ $i -lt $((total_lines - 1)) ]; then
            printf -v output '%s%s\n' "$output" "$decoded_line"
        else
            printf -v output '%s%s' "$output" "$decoded_line"
        fi
    done
    echo -n "$output"
}

handle_special_commands() {

    local lines=("$@")

    case "${lines[0]}" in
    ":d:e:l:e:t:e:"*)
        exec "${0}" --delete
        exit 0
        ;;
    ":w:i:p:e:"*)
        exec "${0}" --wipe
        exit 0
        ;;
    ":b:a:r:"* | *":c:o:p:y:"*)
        exec "${0}" --copy
        exit 0
        ;;
    ":f:a:v:"*)
        exec "${0}" --favorites
        exit 0
        ;;
    ":i:m:g:")
        exec "${0}" --image-history
        ;;
    ":o:p:t:"*)
        exec "${0}"
        exit 0
        ;;
    esac

}

# check if content is binary and handle accordingly
check_content() {
    local line
    read -r line
    if [[ ${line} == *"[[ binary data"* ]]; then
        cliphist decode <<<"$line" | wl-copy
        local img_idx
        img_idx=$(awk -F '\t' '{print $1}' <<<"$line")
        local temp_preview="${XDG_RUNTIME_DIR}/hyde/pastebin-preview_${img_idx}"
        wl-paste >"${temp_preview}"
        notify-send -a "Pastebin:" "Preview: ${img_idx}" -i "${temp_preview}" -t 2000:im:g:
        return 1
    fi
}

# execute rofi with common parameters
run_rofi() {
    local placeholder="$1"
    shift

    rofi -dmenu \
        -theme-str "entry { placeholder: \"${placeholder}\";}" \
        -theme-str "${font_override}" \
        -theme-str "${r_override}" \
        -theme-str "${rofi_position}" \
        -theme "${cliphist_style}" \
        -kb-custom-1 "Alt+c" \
        -kb-custom-2 "Alt+d" \
        -kb-custom-3 "Alt+n" \
        -kb-custom-4 "Alt+w" \
        -kb-custom-5 "Alt+o" \
        -kb-custom-6 "Alt+v" \
        "$@"
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        case "${exit_code}" in
        10) printf ":c:o:p:y:" ;;
        11) printf ":d:e:l:e:t:e:" ;;
        12) printf ":f:a:v:" ;;
        13) printf ":w:i:p:e:" ;;
        14) printf ":o:p:t:" ;;
        15) printf ":i:m:g:" ;;
        esac

    fi
}

# setup rofi configuration
setup_rofi_config() {
    # font scale
    local font_scale="${ROFI_CLIPHIST_SCALE}"
    [[ "${font_scale}" =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}

    # set font name
    local font_name=${ROFI_CLIPHIST_FONT:-$ROFI_FONT}
    font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
    font_name=${font_name:-$(get_hyprConf "FONT")}

    # set rofi font override
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

# create favorites directory if it doesn't exist
ensure_favorites_dir() {
    local dir
    dir=$(dirname "$favorites_file")
    [ -d "$dir" ] || mkdir -p "$dir"
}

# process favorites file into an array of decoded lines for rofi
prepare_favorites_for_display() {
    if [ ! -f "$favorites_file" ] || [ ! -s "$favorites_file" ]; then
        return 1
    fi

    # read each Base64 encoded favorite as a separate line
    mapfile -t favorites <"$favorites_file"

    # prepare list of representations for rofi
    decoded_lines=()
    for favorite in "${favorites[@]}"; do
        local decoded_favorite
        decoded_favorite=$(echo "$favorite" | base64 --decode)
        # replace newlines with spaces for rofi display
        local single_line_favorite
        single_line_favorite=$(echo "$decoded_favorite" | tr '\n' ' ')
        decoded_lines+=("$single_line_favorite")
    done

    return 0
}

cliphist_cmd() {

    if [[ "${CLIPHIST_IMAGE_HISTORY}" != true ]]; then
        echo -e ":f:a:v:\t📌 Favorites"
        echo -e ":o:p:t:\t⚙️ Options"
        cliphist list
    else
        HYDE_CLIPHIST_IMAGE_ONLY=true cliphist.image.py
    fi
}

# display clipboard history and copy selected item
show_history() {
    local selected_item
    rofi_args=(" 📜 History..." -multi-select -i -display-columns 2 -selected-row 2)
    if [[ "${CLIPHIST_IMAGE_HISTORY}" == true ]]; then
        rofi_args=(" 🏞️ Image..." -display-columns 2
            -show-icons -eh 3
            -theme-str 'listview { lines: 4; columns: 2; }'
            -theme-str 'element { enabled: true; orientation: vertical; spacing: 0%; padding: 0%; cursor: pointer; background-color: transparent; text-color: @main-fg; horizontal-align: 0.5; }'
            -theme-str 'element-text { enabled: false;}'
            -theme-str 'element-icon {size: 8%; spacing: 0%; padding: 0%; cursor: inherit; background-color: transparent; }'
            -theme-str 'element selected.normal { background-color: @select-bg; text-color: @select-fg; }'
        )
    fi
    selected_item=$(
        cliphist_cmd | run_rofi "${rofi_args[@]}"
    ) || exit 0

    [ -n "${selected_item}" ] || exit 0

    handle_special_commands "${selected_item##*$'\n'}"
    # handle_special_commands "${selected_item##*$'\n'}"

    if echo -e "${selected_item}" | check_content; then
        process_selections <<<"${selected_item}" | wl-copy
        paste_string "${@}"
        echo -e "${selected_item}\t" | cliphist delete
    else
        # binary content - handled by check_content
        paste_string "${@}"
        exit 0
    fi
}

# delete items from clipboard history
delete_items() {
    local selected_item
    selected_item="$(cliphist list | run_rofi " 🗑️ Delete" -multi-select -i -display-columns 2)"
    handle_special_commands "${selected_item##*$'\n'}"
    process_deletion <<<"${selected_item}"
}

# favorite clipboard items
view_favorites() {
    prepare_favorites_for_display || {
        notify-send "No favorites."
        return
    }

    local selected_item
    selected_item=$(printf "%s\n" "${decoded_lines[@]}" | run_rofi "📌 View Favorites") || exit 0

    if [ -n "$selected_item" ]; then
        handle_special_commands "${selected_item##*$'\n'}"

        # Find the index of the selected favorite
        local index
        index=$(printf "%s\n" "${decoded_lines[@]}" | grep -nxF "$selected_item" | cut -d: -f1)

        # Use the index to get the Base64 encoded favorite
        if [ -n "$index" ]; then
            local selected_encoded_favorite="${favorites[$((index - 1))]}"
            echo "$selected_encoded_favorite" | base64 --decode | wl-copy
            paste_string "${@}"
            notify-send "Copied to clipboard."
        else
            notify-send "Error: Selected favorite not found."
        fi
    fi
}

# add item to favorites
add_to_favorites() {
    ensure_favorites_dir

    local item
    item=$(cliphist list | run_rofi "➕ Add to Favorites...") || exit 0

    if [ -n "$item" ]; then
        local full_item
        full_item=$(echo "$item" | cliphist decode)

        local encoded_item
        encoded_item=$(echo "$full_item" | base64 -w 0)

        # Check if the item is already in the favorites file
        if [ -f "$favorites_file" ] && grep -Fxq "$encoded_item" "$favorites_file"; then
            notify-send "Item is already in favorites."
        else
            echo "$encoded_item" >>"$favorites_file"
            notify-send "Added to favorites."
        fi
    fi
}

# delete from favorites
delete_from_favorites() {
    prepare_favorites_for_display || {
        notify-send "No favorites to remove."
        return
    }

    local selected_favorite
    selected_favorite=$(printf "%s\n" "${decoded_lines[@]}" | run_rofi "➖ Remove from Favorites...") || exit 0

    if [ -n "$selected_favorite" ]; then
        local index
        index=$(printf "%s\n" "${decoded_lines[@]}" | grep -nxF "$selected_favorite" | cut -d: -f1)

        if [ -n "$index" ]; then
            local selected_encoded_favorite="${favorites[$((index - 1))]}"

            # Handle case where only one item is present
            if [ "$(wc -l <"$favorites_file")" -eq 1 ]; then
                : >"$favorites_file"
            else
                grep -vF -x "$selected_encoded_favorite" "$favorites_file" >"${favorites_file}.tmp" &&
                    mv "${favorites_file}.tmp" "$favorites_file"
            fi
            notify-send "Item removed from favorites."
        else
            notify-send "Error: Selected favorite not found."
        fi
    fi
}

# clear all favorites
clear_favorites() {
    if [ -f "$favorites_file" ] && [ -s "$favorites_file" ]; then
        local confirm
        confirm=$(echo -e "Yes\nNo" | run_rofi "☢️ Clear All Favorites?") || exit 0

        if [ "$confirm" = "Yes" ]; then
            : >"$favorites_file"
            notify-send "All favorites have been deleted."
        fi
    else
        notify-send "No favorites to delete."
    fi
}

# manage favorites
manage_favorites() {
    local manage_action
    manage_action=$(echo -e "Add to Favorites\nDelete from Favorites\nClear All Favorites" |
        run_rofi "📓 Manage Favorites") || exit 0

    case "${manage_action}" in
    "Add to Favorites")
        add_to_favorites
        ;;
    "Delete from Favorites")
        delete_from_favorites
        ;;
    "Clear All Favorites")
        clear_favorites
        ;;
    *)
        [ -n "${manage_action}" ] || return 0
        echo "Invalid action"
        exit 1
        ;;
    esac
}

# clear clipboard history
clear_history() {
    local selected_item
    selected_item=$(echo -e "Yes\nNo" | run_rofi "☢️ Clear Clipboard History?")
    handle_special_commands "${selected_item##*$'\n'}"
    if [ "$selected_item" = "Yes" ]; then
        cliphist wipe
        notify-send "Clipboard history cleared."
    fi
}

# show help message
show_help() {
    cat <<EOF
Options:
  -c  | --copy | History            Show clipboard history and copy selected item
  -d  | --delete | Delete           Delete selected item from clipboard history
  -f  | --favorites| View Favorites              View favorite clipboard items
  -mf | -manage-fav | Manage Favorites  Manage favorite clipboard items
  -w  | --wipe | Clear History      Clear clipboard history
  -h  | --help | Help               Display this help message

Note: To enable autopaste, install 'wtype' package.
EOF
    exit 0
}

# main function
main() {
    setup_rofi_config

    local main_action="$1"
    if [ $# -eq 0 ]; then
        main_action=$(
            run_rofi "🔎 Options (Alt O)" \
                -display-column-separator ":::" \
                -display-columns 1,2 \
                -markup-rows <<EOF
History:::<i>(Alt+C)</i>
Image History:::<i>(Alt+V)</i>
Delete Item:::<i>(Alt+D)</i>
Clear History:::<i>(Alt+W)</i>
View Favorites:::<i>(Alt+N)</i>
Manage Favorites:::
EOF
        )
        handle_special_commands "${main_action##*$'\n'}"
        main_action="${main_action%%:::*}"

    fi

    unset CLIPHIST_IMAGE_HISTORY
    # process user selection
    case "${main_action}" in
    -i | --image-history | "Image History")
        CLIPHIST_IMAGE_HISTORY=true show_history "$@"
        ;;
    -c | --copy | "History")
        show_history "$@"
        ;;
    -d | --delete | "Delete")
        delete_items
        ;;
    -f | --favorites | "View Favorites")
        view_favorites "$@"
        ;;
    -mf | -manage-fav | "Manage Favorites")
        manage_favorites
        ;;
    -w | --wipe | "Clear History")
        clear_history
        ;;
    -b | --binds)
        show_binds
        ;;
    -h | --help | *)
        [ -z "$main_action" ] && exit 0
        show_help
        ;;
    esac
}

# run main function
main "$@"

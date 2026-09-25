#!/usr/bin/env bash
pkill -u "$USER" rofi && exit 0
[[ $HYDE_SHELL_INIT -ne 1 ]] && eval "$(hyde-shell init)"
cache_dir="${HYDE_CACHE_HOME:-$HOME/.cache/hyde}"
favorites_file="$cache_dir/landing/cliphist_favorites"
[ -f "$HOME/.cliphist_favorites" ] && favorites_file="$HOME/.cliphist_favorites"
cliphist_style="${ROFI_CLIPHIST_STYLE:-clipboard}"

# shellcheck disable=SC1091
[[ -f "${LIB_DIR}/hyde/shutils/l10n.sh" ]] && source "${LIB_DIR}/hyde/shutils/l10n.sh"


process_deletion() {
    while IFS= read -r line; do
        echo "$line"
        if [[ $line == ":w:i:p:e:"* ]]; then
            "$0" --wipe
            break
        elif [[ $line == ":b:a:r:"* ]]; then
            "$0" --delete
            break
        elif [ -n "$line" ]; then
            cliphist delete <<< "$line"
            notify-send "${_T["Deleted"]:-Deleted}" "$line"
        fi
    done
    exit 0
}
process_selections() {
    mapfile -t lines
    total_lines=${#lines[@]}
    handle_special_commands "${lines[@]}"
    local output=""
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
        ":d:e:l:e:t:e:"*) exec "$0" --delete exit 0 ;;
        ":w:i:p:e:"*) exec "$0" --wipe exit 0 ;;
        ":b:a:r:"* | *":c:o:p:y:"*) exec "$0" --copy exit 0 ;;
        ":f:a:v:"*) exec "$0" --favorites exit 0 ;;
        ":i:m:g:") exec "$0" --image-history ;;
        ":o:p:t:"*) exec "$0" exit 0 ;;
        ":o:c:r:"*) exec "$0" --scan-image ;;
    esac
}
check_content() {
    local line
    read -r line
    if [[ $line == *"[[ binary data"* ]]; then
        cliphist decode <<< "$line" | wl-copy
        local img_idx
        img_idx=$(awk -F '\t' '{print $1}' <<< "$line")
        local temp_preview="$XDG_RUNTIME_DIR/hyde/pastebin-preview_$img_idx"
        wl-paste > "$temp_preview"
        notify-send -a "${_T["Pastebin:"]:-Pastebin:}" "${_T["Preview:"]:-Preview:} $img_idx" -i "$temp_preview" -t 2000
        return 1
    fi
}
run_rofi() {
    local placeholder="$1"
    shift
    rofi -dmenu \
        -theme-str "entry { placeholder: \"$placeholder\";}" \
        -theme-str "$font_override" \
        -theme-str "$r_override" \
        -theme-str "$rofi_position" \
        -theme "$cliphist_style" \
        -kb-custom-1 "Alt+c" \
        -kb-custom-2 "Alt+d" \
        -kb-custom-3 "Alt+n" \
        -kb-custom-4 "Alt+w" \
        -kb-custom-5 "Alt+o" \
        -kb-custom-6 "Alt+v" \
        -kb-custom-7 "Alt+s" \
        "$@"
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        case "$exit_code" in
            10) printf ":c:o:p:y:" ;;
            11) printf ":d:e:l:e:t:e:" ;;
            12) printf ":f:a:v:" ;;
            13) printf ":w:i:p:e:" ;;
            14) printf ":o:p:t:" ;;
            15) printf ":i:m:g:" ;;
            16) printf ":o:c:r:" ;;
        esac
    fi
}
setup_rofi_config() {
    local font_scale="$ROFI_CLIPHIST_SCALE"
    [[ $font_scale =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}
    local font_name=${ROFI_CLIPHIST_FONT:-$ROFI_FONT}
    font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
    font_name=${font_name:-$(get_hyprConf "FONT")}
    font_override="* {font: \"${font_name:-"JetBrainsMono Nerd Font"} $font_scale\";}"
    local hypr_border=${hypr_border:-"$(hyprctl -j getoption decoration:rounding | jq '.int')"}
    local wind_border=$((hypr_border * 3 / 2))
    local elem_border=$((hypr_border == 0 ? 5 : hypr_border))
    rofi_position=$(get_rofi_pos)
    local hypr_width=${hypr_width:-"$(hyprctl -j getoption general:border_size | jq '.int')"}
    r_override="window{border:${hypr_width}px;border-radius:${wind_border}px;}wallbox{border-radius:${elem_border}px;} element{border-radius:${elem_border}px;}"
}
ensure_favorites_dir() {
    local dir
    dir=$(dirname "$favorites_file")
    [ -d "$dir" ] || mkdir -p "$dir"
}
prepare_favorites_for_display() {
    if [ ! -f "$favorites_file" ] || [ ! -s "$favorites_file" ]; then
        return 1
    fi
    mapfile -t favorites < "$favorites_file"
    decoded_lines=()
    for favorite in "${favorites[@]}"; do
        local decoded_favorite
        decoded_favorite=$(echo "$favorite" | base64 --decode)
        local single_line_favorite
        single_line_favorite=$(echo "$decoded_favorite" | tr '\n' ' ')
        decoded_lines+=("$single_line_favorite")
    done
    return 0
}
cliphist_cmd() {
    if [[ $CLIPHIST_IMAGE_HISTORY != true ]]; then
        echo -e ":f:a:v:\t📌 ${_T["Favorites"]:-Favorites}"
        echo -e ":o:p:t:\t⚙️ ${_T["Options"]:-Options}"
        cliphist list
    else
        HYDE_CLIPHIST_IMAGE_ONLY=true cliphist.image.py
    fi
}
show_history() {
    local selected_item
    rofi_args=(" 📜 ${_T["History..."]:-History...}" -multi-select -i -display-columns 2 -selected-row 2)
    if [[ $CLIPHIST_IMAGE_HISTORY == true ]]; then
        rofi_args=(" 🏞️ ${_T["Image History | Alt+S to Scan"]:-Image History | Alt+S to Scan}" -display-columns 2
            -show-icons -eh 3
            -theme-str 'listview { lines: 4; columns: 2; }'
            -theme-str 'element { enabled: true; orientation: vertical; spacing: 0%; padding: 0%; cursor: pointer; background-color: transparent; text-color: @main-fg; horizontal-align: 0.5; }'
            -theme-str 'element-text { enabled: false;}'
            -theme-str 'element-icon {size: 8%; spacing: 0%; padding: 0%; cursor: inherit; background-color: transparent; }'
            -theme-str 'element selected.normal { background-color: @select-bg; text-color: @select-fg; }')
    fi

    selected_item=$(cliphist_cmd | run_rofi "${rofi_args[@]}")
    echo "${?}"
    echo "$selected_item"
    [ -n "$selected_item" ] || exit 0
    handle_special_commands "${selected_item##*$'\n'}"
    if echo -e "$selected_item" | check_content; then
        process_selections <<< "$selected_item" | wl-copy
        paste_string "$@"
        echo -e "$selected_item\t" | cliphist delete
    else
        paste_string "$@"
        exit 0
    fi
}

delete_items() {
    local selected_item
    selected_item="$(cliphist list | run_rofi " 🗑️ ${_T["Delete"]:-Delete}" -multi-select -i -display-columns 2)"
    handle_special_commands "${selected_item##*$'\n'}"
    process_deletion <<< "$selected_item"
}
view_favorites() {
    prepare_favorites_for_display || {
        notify-send "${_T["No favorites."]:-No favorites.}"
        return
    }
    local selected_item
    selected_item=$(printf "%s\n" "${decoded_lines[@]}" | run_rofi "📌 ${_T["View Favorites"]:-View Favorites}") || exit 0
    if [ -n "$selected_item" ]; then
        handle_special_commands "${selected_item##*$'\n'}"
        local index
        index=$(printf "%s\n" "${decoded_lines[@]}" | grep -nxF "$selected_item" | cut -d: -f1)
        if [ -n "$index" ]; then
            local selected_encoded_favorite="${favorites[$((index - 1))]}"
            echo "$selected_encoded_favorite" | base64 --decode | wl-copy
            paste_string "$@"
            notify-send "${_T["Copied to clipboard."]:-Copied to clipboard.}"
        else
            notify-send "${_T["Error: Selected favorite not found."]:-Error: Selected favorite not found.}"
        fi
    fi
}
add_to_favorites() {
    ensure_favorites_dir
    local item
    item=$(cliphist list | run_rofi "➕ ${_T["Add to Favorites..."]:-Add to Favorites...}") || exit 0
    if [ -n "$item" ]; then
        local full_item
        full_item=$(echo "$item" | cliphist decode)
        local encoded_item
        encoded_item=$(echo "$full_item" | base64 -w 0)
        if [ -f "$favorites_file" ] && grep -Fxq "$encoded_item" "$favorites_file"; then
            notify-send "${_T["Item is already in favorites."]:-Item is already in favorites.}"
        else
            echo "$encoded_item" >> "$favorites_file"
            notify-send "${_T["Added to favorites."]:-Added to favorites.}"
        fi
    fi
}
delete_from_favorites() {
    prepare_favorites_for_display || {
        notify-send "${_T["No favorites to remove."]:-No favorites to remove.}"
        return
    }
    local selected_favorite
    selected_favorite=$(printf "%s\n" "${decoded_lines[@]}" | run_rofi "➖ ${_T["Remove from Favorites..."]:-Remove from Favorites...}") || exit 0
    if [ -n "$selected_favorite" ]; then
        local index
        index=$(printf "%s\n" "${decoded_lines[@]}" | grep -nxF "$selected_favorite" | cut -d: -f1)
        if [ -n "$index" ]; then
            local selected_encoded_favorite="${favorites[$((index - 1))]}"
            if [ "$(wc -l < "$favorites_file")" -eq 1 ]; then
                : > "$favorites_file"
            else
                grep -vF -x "$selected_encoded_favorite" "$favorites_file" > "$favorites_file.tmp" && mv "$favorites_file.tmp" "$favorites_file"
            fi
            notify-send "${_T["Item removed from favorites."]:-Item removed from favorites.}"
        else
            notify-send "${_T["Error: Selected favorite not found."]:-Error: Selected favorite not found.}"
        fi
    fi
}
clear_favorites() {
    if [ -f "$favorites_file" ] && [ -s "$favorites_file" ]; then
        local confirm
        local yes_str="${_T["Yes"]:-Yes}"
        confirm=$(echo -e "${yes_str}\n${_T["No"]:-No}" | run_rofi "☢️ ${_T["Clear All Favorites?"]:-Clear All Favorites?}") || exit 0
        if [ "$confirm" = "$yes_str" ]; then
            : > "$favorites_file"
            notify-send "${_T["All favorites have been deleted."]:-All favorites have been deleted.}"
        fi
    else
        notify-send "${_T["No favorites to delete."]:-No favorites to delete.}"
    fi
}
manage_favorites() {
    local opt_add="${_T["Add to Favorites"]:-Add to Favorites}"
    local opt_del="${_T["Delete from Favorites"]:-Delete from Favorites}"
    local opt_clr="${_T["Clear All Favorites"]:-Clear All Favorites}"

    local manage_action
    manage_action=$(echo -e "${opt_add}\n${opt_del}\n${opt_clr}" | run_rofi "📓 ${_T["Manage Favorites"]:-Manage Favorites}") || exit 0
    case "$manage_action" in
        "$opt_add")
            add_to_favorites
            ;;
        "$opt_del")
            delete_from_favorites
            ;;
        "$opt_clr")
            clear_favorites
            ;;
        *)
            [ -n "$manage_action" ] || return 0
            echo "Invalid action"
            exit 1
            ;;
    esac
}
clear_history() {
    local selected_item
    local yes_str="${_T["Yes"]:-Yes}"
    selected_item=$(echo -e "${yes_str}\n${_T["No"]:-No}" | run_rofi "☢️ ${_T["Clear Clipboard History?"]:-Clear Clipboard History?}")
    handle_special_commands "${selected_item##*$'\n'}"
    if [ "$selected_item" = "$yes_str" ]; then
        cliphist wipe
        notify-send "${_T["Clipboard history cleared."]:-Clipboard history cleared.}"
    fi
}
main_menu_options() {
    cat <<- EOF
		${_T["History"]:-History}:::<sub>(Alt+C)</sub>
		${_T["Image History"]:-Image History}:::<sub>(Alt+V)</sub>
		${_T["Delete Item"]:-Delete Item}:::<sub>(Alt+D)</sub>
		${_T["Clear History"]:-Clear History}:::<sub>(Alt+W)</sub>
		${_T["View Favorites"]:-View Favorites}:::<sub>(Alt+N)</sub>
		${_T["Manage Favorites"]:-Manage Favorites}:::<sub>(Alt+O)</sub>
	EOF
}

ocr_scan() {

    # shellcheck disable=SC1091
    source "${LIB_DIR}/hyde/shutils/ocr.sh"
    source ${XDG_STATE_HOME}/hyde/config
    local runtime_dir="${XDG_RUNTIME_DIR:-/run/user/${EUID}}/hyde"
    local image_path="${runtime_dir}/cliphist_ocr.png"
    local index
    index="$(HYDE_CLIPHIST_IMAGE_ONLY=1 "${LIB_DIR}/hyde/cliphist.image.py" | head -n1)"
    [[ -n $index ]] || {
        send_notifs "${_T["OCR Error"]:-OCR Error}" "${_T["No images in clipboard history..."]:-No images in clipboard history...}" -r 9
        exit 1
    }

    mkdir -p "$runtime_dir"
    cliphist decode "$index" > "${image_path}"
    if [ ! -s "${image_path}" ]; then
        notify-send "${_T["OCR Error"]:-OCR Error}" "${_T["No image data in clipboard -r 9"]:-No image data in clipboard -r 9}"
        exit 1
    fi
    print_log -g "Scanning ${image_path}"
    send_notifs "${_T["OCR"]:-OCR}" "${_T["Scanning latest image from clipboard..."]:-Scanning latest image from clipboard...}" -i "${image_path}" -r 9
    ocr_extract "$image_path"

}

main() {
    setup_rofi_config

    # shellcheck disable=SC1091
    source "${LIB_DIR}/hyde/shutils/argparse.sh"

    argparse_init "$@"
    argparse_program "hyde-shell cliphist"
    argparse_header "HyDE Clipboard Manager"

    argparse "--copy,-c" "ACTION=copy" "Show clipboard history and copy selected item"
    argparse "--delete,-d" "ACTION=delete" "Delete selected item from clipboard history"
    argparse "--favorites,-f" "ACTION=favorites" "View favorite clipboard items"
    argparse "--manage-fav,-mf" "ACTION=manage_fav" "Manage favorite clipboard items"
    argparse "--wipe,-w" "ACTION=wipe" "Clear clipboard history"
    argparse "--image-history,-i" "ACTION=image_history" "Show image history"
    argparse "--scan-image,-sc" "ACTION=ocr_image" "Use tesseract the latest image from clipboard"
    argparse_finalize

    unset CLIPHIST_IMAGE_HISTORY # prevent image history side effects

    if [ -z "$ACTION" ]; then
        # Localized options for menu matching
        local opt_hist="${_T["History"]:-History}"
        local opt_imgh="${_T["Image History"]:-Image History}"
        local opt_del="${_T["Delete Item"]:-Delete Item}"
        local opt_clr="${_T["Clear History"]:-Clear History}"
        local opt_vfav="${_T["View Favorites"]:-View Favorites}"
        local opt_mfav="${_T["Manage Favorites"]:-Manage Favorites}"

        # No arguments provided, show menu
        local main_action
        main_action=$(
            main_menu_options | run_rofi "🔎 ${_T["Options (Alt O)"]:-Options (Alt O)}" \
                -display-column-separator ":::" \
                -display-columns 1,2 \
                -markup-rows
        )
        handle_special_commands "${main_action##*$'\n'}"

        main_action="${main_action%%:::*}"

        case "$main_action" in
            "$opt_hist") ACTION=copy ;;
            "$opt_imgh") ACTION=image_history ;;
            "$opt_del") ACTION=delete ;;
            "$opt_clr") ACTION=wipe ;;
            "$opt_vfav") ACTION=favorites ;;
            "$opt_mfav") ACTION=manage_fav ;;
            *) exit 0 ;;
        esac
    fi

    # Execute the action
    case "$ACTION" in
        copy) show_history "$@" ;;
        delete) delete_items ;;
        favorites) view_favorites "$@" ;;
        manage_fav) manage_favorites ;;
        wipe) clear_history ;;
        image_history) CLIPHIST_IMAGE_HISTORY=true show_history "$@" ;;
        ocr_image) ocr_scan ;;
    esac
}
main "$@"

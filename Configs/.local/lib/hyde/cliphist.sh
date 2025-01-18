#!/usr/bin/env bash

# Set variables
# shellcheck source=$HOME/.local/bin/hyde-shell
# shellcheck disable=SC1091
if ! source "$(which hyde-shell)"; then
    echo "[wallbash] code :: Error: hyde-shell not found."
    echo "[wallbash] code :: Is HyDE installed?"
    exit 1
fi

confDir="${confDir:-$XDG_CONFIG_HOME}"
cacheDir="${cacheDir:-$XDG_CACHE_HOME/hyde}"
favoritesFile="${cacheDir}/landing/cliphist_favorites"
cliphist_style="${ROFI_CLIPHIST_STYLE:-clipboard}"
delMode=false

#? MultiSelect
pastebin_process() {

    if [ true != "${delMode}" ]; then
        # Read the entire input into an array
        mapfile -t lines #! Not POSIX compliant
        # Get the total number of lines
        total_lines=${#lines[@]}
        if [[ "${lines[0]}" = ":d:e:l:e:t:e:"* ]]; then
            "${0}" --delete
        elif [[ "${lines[0]}" = ":w:i:p:e:"* ]]; then
            "${0}" --wipe
        elif [[ "${lines[0]}" = ":b:a:r:"* ]] || [[ "${lines[0]}" = *":c:o:p:y:"* ]]; then
            "${0}" --copy
        elif [[ "${lines[0]}" = ":f:a:v:"* ]]; then
            "${0}" --favorites
        elif [[ "${lines[0]}" = ":o:p:t:"* ]]; then
            "${0}"
        else
            # Iterate over each line in the array
            for ((i = 0; i < total_lines; i++)); do
                line="${lines[$i]}"
                decoded_line="$(echo -e "$line\t" | cliphist decode)"
                if [ $i -lt $((total_lines - 1)) ]; then
                    printf -v output '%s%s\n' "$output" "$decoded_line"
                else
                    printf -v output '%s%s' "$output" "$decoded_line"
                fi
            done
            echo -n "$output"
        fi
    else
        while IFS= read -r line; do
            if [[ "${line}" = ":w:i:p:e:"* ]]; then
                "${0}" --wipe
                break
            elif [[ "${line}" = ":b:a:r:"* ]]; then
                "${0}" --delete
                break
            else
                if [ -n "$line" ]; then
                    cliphist delete <<<"${line}"
                    notify-send "Deleted" "${line}"
                fi

            fi
        done
        exit 0
    fi
}

checkContent() {
    # Read the input line by line
    read -r line
    if [[ ${line} == *"[[ binary data"* ]]; then
        cliphist decode <<<"$line" | wl-copy
        imdx=$(awk -F '\t' '{print $1}' <<<$line)
        temprev="${HYDE_RUNTIME_DIR}/pastebin-preview_${imdx}"
        wl-paste >"${temprev}"
        notify-send -a "Pastebin:" "Preview: ${imdx}" -i "${temprev}" -t 2000
        return 1
    fi

}

# Set rofi scaling
rofiScale="${ROFI_CLIPHIST_SCALE}"
[[ "${rofiScale}" =~ ^[0-9]+$ ]] || rofiScale=${ROFI_SCALE:-10}
r_scale="configuration {font: \"JetBrainsMono Nerd Font ${rofiScale}\";}"
hypr_border=${hypr_border:-"$(hyprctl -j getoption decoration:rounding | jq '.int')"}
wind_border=$((hypr_border * 3 / 2))
elem_border=$((hypr_border == 0 ? 5 : hypr_border))

# Set rofi location
rofi_position=$(get_rofi_pos)

hypr_width=${hypr_width:-"$(hyprctl -j getoption general:border_size | jq '.int')"}
r_override="window{border:${hypr_width}px;border-radius:${wind_border}px;}wallbox{border-radius:${elem_border}px;} element{border-radius:${elem_border}px;}"

# Show main menu if no arguments are passed
if [ $# -eq 0 ]; then
    main_action=$(echo -e "History\nDelete\nView Favorites\nManage Favorites\nClear History" | rofi -dmenu -theme-str "entry { placeholder: \"🔎 Choose action\";}" -theme-str "${r_scale}" -theme-str "${r_override}" -theme-str "${rofi_position}" -theme "${cliphist_style}")
else
    main_action="$1"
fi

case "${main_action}" in
-c | --copy | "History")
    selected_item=$( (
        echo -e ":f:a:v:\t📌 Favorites"
        echo -e ":o:p:t:\t⚙️ Options"
        cliphist list
    ) | rofi -dmenu -multi-select -i -display-columns 2 -selected-row 2 -theme-str "${r_scale}" -theme-str "entry { placeholder: \" 📜 History...\";}  ${rofi_position}  ${r_override}" -theme "${cliphist_style}")
    ([ -n "${selected_item}" ] && echo -e "${selected_item}" | checkContent) || exit 0
    if [ $? -eq 1 ]; then
        paste_string "${*}"
        exit 0
    fi
    pastebin_process <<<"${selected_item}" | wl-copy
    paste_string "${*}"
    echo -e "${selected_item}\t" | cliphist delete
    ;;
-d | --delete | "Delete")
    export delMode=true
    (
        cliphist list
    ) | rofi -dmenu -multi-select -i -display-columns 2 -theme-str "${r_scale}" -theme-str "entry { placeholder: \" 🗑️ Delete\";} ${rofi_position} ${r_override}" -theme "${cliphist_style}" | pastebin_process
    ;;
-f | --favorites | "View Favorites")
    if [ -f "$favoritesFile" ] && [ -s "$favoritesFile" ]; then
        # Read each Base64 encoded favorite as a separate line
        mapfile -t favorites <"$favoritesFile"

        # Prepare a list of decoded single-line representations for rofi
        decoded_lines=()
        for favorite in "${favorites[@]}"; do
            decoded_favorite=$(echo "$favorite" | base64 --decode)
            # Replace newlines with spaces for rofi display
            single_line_favorite=$(echo "$decoded_favorite" | tr '\n' ' ')
            decoded_lines+=("$single_line_favorite")
        done

        selected_favorite=$(printf "%s\n" "${decoded_lines[@]}" | rofi -dmenu -theme-str "entry { placeholder: \"📌  View Favorites\";}" -theme-str "${r_scale}" -theme-str "${r_override}" -theme-str "${rofi_position}" -theme "${cliphist_style}")
        if [ -n "$selected_favorite" ]; then
            # Find the index of the selected favorite
            index=$(printf "%s\n" "${decoded_lines[@]}" | grep -nxF "$selected_favorite" | cut -d: -f1)
            # Use the index to get the Base64 encoded favorite
            if [ -n "$index" ]; then
                selected_encoded_favorite="${favorites[$((index - 1))]}"
                # Decode and copy the full multi-line content to clipboard
                echo "$selected_encoded_favorite" | base64 --decode | wl-copy
                paste_string "${*}"
                notify-send "Copied to clipboard."
            else
                notify-send "Error: Selected favorite not found."
            fi
        fi
    else
        notify-send "No favorites."
    fi
    ;;
-mf | -manage-fav | "Manage Favorites")
    manage_action=$(echo -e "Add to Favorites\nDelete from Favorites\nClear All Favorites" | rofi -dmenu -theme-str "entry { placeholder: \"📓 Manage Favorites\";}" -theme-str "${r_scale}" -theme-str "${r_override}" -theme-str "${rofi_position}" -theme "${cliphist_style}")

    case "${manage_action}" in
    "Add to Favorites")
        # Show clipboard history to add to favorites
        item=$(cliphist list | rofi -dmenu -theme-str "entry { placeholder: \"➕ Add to Favorites...\";}" -theme-str "${r_scale}" -theme-str "${r_override}" -theme-str "${rofi_position}" -theme "${cliphist_style}")
        if [ -n "$item" ]; then
            # Decode the item from clipboard history
            full_item=$(echo "$item" | cliphist decode)
            encoded_item=$(echo "$full_item" | base64 -w 0)

            # Check if the item is already in the favorites file
            if grep -Fxq "$encoded_item" "$favoritesFile"; then
                notify-send "Item is already in favorites."
            else
                # Add the encoded item to the favorites file
                echo "$encoded_item" >>"$favoritesFile"
                notify-send "Added in favorites."
            fi
        fi
        ;;
    -df | --delete-fav | "Delete from Favorites")
        if [ -f "$favoritesFile" ] && [ -s "$favoritesFile" ]; then
            # Read each Base64 encoded favorite as a separate line
            mapfile -t favorites <"$favoritesFile"

            # Prepare a list of decoded single-line representations for rofi
            decoded_lines=()
            for favorite in "${favorites[@]}"; do
                decoded_favorite=$(echo "$favorite" | base64 --decode)
                # Replace newlines with spaces for rofi display
                single_line_favorite=$(echo "$decoded_favorite" | tr '\n' ' ')
                decoded_lines+=("$single_line_favorite")
            done

            selected_favorite=$(printf "%s\n" "${decoded_lines[@]}" | rofi -dmenu -theme-str "entry { placeholder: \"➖ Remove from Favorites...\";}" -theme-str "${r_scale}" -theme-str "${r_override}" -theme-str "${rofi_position}" -theme "${cliphist_style}")
            if [ -n "$selected_favorite" ]; then
                index=$(printf "%s\n" "${decoded_lines[@]}" | grep -nxF "$selected_favorite" | cut -d: -f1)
                if [ -n "$index" ]; then
                    selected_encoded_favorite="${favorites[$((index - 1))]}"

                    # Handle case where only one item is present
                    if [ "$(wc -l <"$favoritesFile")" -eq 1 ]; then
                        # Remove the single encoded item from the file
                        : >"$favoritesFile"
                    else
                        # Remove the selected encoded item from the favorites file
                        grep -vF -x "$selected_encoded_favorite" "$favoritesFile" >"${favoritesFile}.tmp" && mv "${favoritesFile}.tmp" "$favoritesFile"
                    fi
                    notify-send "Item removed from favorites."
                else
                    notify-send "Error: Selected favorite not found."
                fi
            fi
        else
            notify-send "No favorites to remove."
        fi
        ;;
    -cf | --clear-fav | "Clear All Favorites")
        if [ -f "$favoritesFile" ] && [ -s "$favoritesFile" ]; then
            confirm=$(echo -e "Yes\nNo" | rofi -dmenu -theme-str "entry { placeholder: \"☢️ Clear All Favorites?\";}" -theme-str "${r_scale}" -theme-str "${r_override}" -theme-str "${rofi_position}" -theme "${cliphist_style}")
            if [ "$confirm" = "Yes" ]; then
                : >"$favoritesFile"
                notify-send "All favorites have been deleted."
            fi
        else
            notify-send "No favorites to delete."
        fi
        ;;
    *)
        echo "Invalid action"
        exit 1
        ;;
    esac
    ;;
-w | --wipe | "Clear History")
    if [ "$(echo -e "Yes\nNo" | rofi -dmenu -theme-str "entry { placeholder: \"☢️ Clear Clipboard History?\";}" -theme-str "${r_scale}" -theme-str "${r_override}" -theme-str "${rofi_position}" -theme "${cliphist_style}")" == "Yes" ]; then
        cliphist wipe
        notify-send "Clipboard history cleared."
    fi
    ;;
-*)
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
    ;;
esac

#!/usr/bin/env bash

set -u
set -e

scrDir=$(dirname "$(realpath "$0")")
source "$scrDir/globalcontrol.sh"

BROWSER="firefox"
WEB_SEARCH_CACHE_DIR="${HYDE_CACHE_HOME:-${XDG_CACHE_HOME:-$HOME/.cache/hyde}}/landing/rofi-websearch"

SOURCES_CONFIG=(
    '([name]="google"  [logo]=" " [url]="https://www.google.com/search?q=")'
    '([name]="chatGPT" [logo]=" " [url]="https://chat.openai.com/?q=")'
    '([name]="github"  [logo]=" " [url]="https://www.github.com/search?q=")'
    '([name]="youtube" [logo]=" " [url]="https://www.youtube.com/results?search_query=")'
)

SOURCES_ORDER=()
declare -A URLS
declare -A LOGOS

for i in "${!SOURCES_CONFIG[@]}"; do
    declare -A source_item
    eval "source_item=${SOURCES_CONFIG[$i]}"

    name="${source_item[name]}"
    SOURCES_ORDER+=("$name")
    URLS["$name"]="${source_item[url]}"
    LOGOS["$name"]="${source_item[logo]}"
done

DEFAULT_SITE="${SOURCES_ORDER[0]}"

SOURCE_TO_USE=""

usage() {
    echo "web-search is a script that opens a rofi browser with which you can"
    echo "search the web."
    echo ""
    echo "Usage: $0 [-s <site to search>] [-b <browser executable> ]"
    echo "  -h        show this help"
    echo "  -s        give the search engine to use, can be one of the following:"

    for source in "${SOURCES_ORDER[@]}"; do
        echo "            * $source"
    done

    echo "  -b                     Set default browser, the default value is '$BROWSER'"
    echo "  -m | --manage-history  Show a Rofi menu to manage history (clear specific/wipe all)."
    echo "  -c | --clear-specific  Directly show menu to clear specific history entries."
    echo "  -w | --wipe-all        Directly wipe all web search history for all sites."

    exit 1
}

create_cache_dir() {
    mkdir -p "$WEB_SEARCH_CACHE_DIR"
}

create_cache_files() {
    for source in "${SOURCES_ORDER[@]}"; do
        touch "$WEB_SEARCH_CACHE_DIR/$source"
    done
}

gen_sites_list() {
    for source in "${SOURCES_ORDER[@]}"; do
        echo "${LOGOS[$source]}   $source"
    done
}

gen_queries_list() {
    local source_name="$1"
    local history_file="$WEB_SEARCH_CACHE_DIR/$source_name"
    if [ -s "$history_file" ]; then
        cat "$history_file"
    fi
}

write_to_top() {
    local file_name="$1"
    local content="$2"
    local cache_file="$WEB_SEARCH_CACHE_DIR/$file_name"
    local tmp_file="$WEB_SEARCH_CACHE_DIR/tmp"

    {
        echo "$content"
        cat "$cache_file"
    } >"$tmp_file" &&
        mv "$tmp_file" "$cache_file"
}

handle_query() {
    local source_name="$1"
    local query="$2"

    if [ -z "$query" ]; then
        exit 0
    fi

    local history_file="$WEB_SEARCH_CACHE_DIR/$source_name"
    if grep -Fxq "$query" "$history_file"; then
        sed -i "/^${query}$/d" "$history_file"
    fi
    write_to_top "$source_name" "$query"

    $BROWSER "${URLS[$source_name]}$query"
}

hypr_border=${hypr_border:-$(hyprctl -j getoption decoration:rounding | jq '.int')}
hypr_width=${hypr_width:-$(hyprctl -j getoption general:border_size | jq '.int')}
wind_border=$((hypr_border * 3 / 2))
elem_border=$([ "$hypr_border" -eq 0 ] && echo "5" || echo "$hypr_border")

r_width="width: 65%;"
r_override="window {$r_width border: ${hypr_width}px; border-radius: ${wind_border}px;} entry {border-radius: ${elem_border}px;} element {border-radius: ${elem_border}px;}"

font_scale="${ROFI_KEYBIND_HINT_SCALE:-$(gsettings get org.gnome.desktop.interface font-name | awk '{gsub(/'\''/,""); print $NF}')}"
[[ "${font_scale}" =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}

font_name=${ROFI_KEYBIND_HINT_FONT:-${ROFI_FONT:-}}
font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
font_name=${font_name:-$(get_hyprConf "FONT")}

font_override="* {font: \"${font_name:-'JetBrainsMono Nerd Font'} ${font_scale}\";}"

icon_override=$(gsettings get org.gnome.desktop.interface icon-theme | sed "s/'//g")
icon_override="configuration {icon-theme: \"${icon_override}\";}"

run_rofi() {
    local placeholder="$1"
    shift
    rofi -dmenu \
        -theme-str "entry { placeholder: \"${placeholder}\";}" \
        -theme-str "${font_override}" \
        -theme-str "${r_override}" \
        -theme-str "${icon_override}" \
        -theme "${ROFI_KEYBIND_HINT_STYLE:-clipboard}" "$@"
}

clear_specific_history() {
    local selected_display_site
    selected_display_site=$(gen_sites_list | run_rofi "🗑️ Select site to clear history from")
    [ -z "$selected_display_site" ] && exit 0

    local selected_site_name
    selected_site_name=$(echo "$selected_display_site" | awk '{print $NF}')

    local history_file="$WEB_SEARCH_CACHE_DIR/$selected_site_name"
    if [ ! -s "$history_file" ]; then
        notify-send "No History" "No search history found for $selected_site_name."
        exit 0
    fi

    local selected_queries
    selected_queries=$(gen_queries_list "$selected_site_name" | run_rofi "🗑️ Delete queries from $selected_site_name" -multi-select -no-custom)

    if [ -n "$selected_queries" ]; then
        mapfile -t queries_to_delete <<<"$selected_queries"

        local pattern_file
        pattern_file=$(mktemp)
        printf "%s\n" "${queries_to_delete[@]}" >"$pattern_file"

        local temp_file
        temp_file=$(mktemp)
        grep -vFxf "$pattern_file" "$history_file" >"$temp_file"
        mv "$temp_file" "$history_file"
        rm "$pattern_file"

        notify-send "Deleted" "Selected queries from $selected_site_name history have been removed."
    else
        notify-send "No selection" "No queries were selected for deletion."
    fi
}

wipe_all_history() {
    local confirm
    confirm=$(echo -e "Yes\nNo" | run_rofi "☢️ Clear ALL Web Search History?")

    if [ "$confirm" = "Yes" ]; then
        rm -f "${WEB_SEARCH_CACHE_DIR:?}"/*
        notify-send "All web search history has been wiped."
    fi
}

manage_history() {
    local manage_action
    manage_action=$(echo -e "Clear Specific Entries" |
        run_rofi "⚙️ Manage History")

    case "${manage_action}" in
    "Clear Specific Entries")
        clear_specific_history
        ;;
    "Wipe All History")
        wipe_all_history
        ;;
    *)
        [ -n "${manage_action}" ] || return 0
        echo "Invalid action"
        exit 1
        ;;
    esac
}

main() {
    create_cache_dir
    create_cache_files

    local action_requested=""

    while getopts ":s:b:cwmh" opt; do
        case "${opt}" in
        s)
            SOURCE_TO_USE=${OPTARG}
            ;;
        b)
            BROWSER=${OPTARG}
            ;;
        c)
            action_requested="clear_specific"
            ;;
        w)
            action_requested="wipe_all"
            ;;
        m)
            action_requested="manage"
            ;;
        h)
            usage
            ;;
        \?)
            usage
            ;;
        esac
    done
    shift $((OPTIND - 1))

    case "$action_requested" in
    "clear_specific")
        clear_specific_history
        exit 0
        ;;
    "wipe_all")
        wipe_all_history
        exit 0
        ;;
    "manage")
        manage_history
        exit 0
        ;;
    esac

    if [ "$#" -gt 0 ]; then
        handle_query "$DEFAULT_SITE" "$*"
    elif [ -n "$SOURCE_TO_USE" ]; then
        if [[ -v URLS[$SOURCE_TO_USE] ]]; then
            query=$(gen_queries_list "$SOURCE_TO_USE" | run_rofi "Search (${LOGOS[$SOURCE_TO_USE]} $SOURCE_TO_USE)")
            handle_query "$SOURCE_TO_USE" "$query"
        else
            echo "Error: Unknown source '$SOURCE_TO_USE'" >&2
            exit 1
        fi
    else
        local main_action
        local rofi_prompt="🔎 Select engine, or type to search ${LOGOS[$DEFAULT_SITE]} ${DEFAULT_SITE^}"
        main_action=$( (
            gen_sites_list
            echo "Manage History"
        ) | run_rofi "$rofi_prompt")

        local selected_name
        selected_name=$(echo "$main_action" | awk '{print $NF}')

        if [[ -v URLS[$selected_name] ]]; then
            local site="$selected_name"
            local search_prompt="Search (${LOGOS[$site]} $site)"
            query=$(gen_queries_list "$site" | run_rofi "$search_prompt")
            handle_query "$site" "$query"
        elif [ "$main_action" = "Manage History" ]; then
            manage_history
        elif [ -n "$main_action" ]; then
            handle_query "$DEFAULT_SITE" "$main_action"
        else
            exit 0
        fi
    fi
}

main "$@"

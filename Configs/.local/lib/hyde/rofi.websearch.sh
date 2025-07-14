#!/usr/bin/env bash

set -e

[[ "${HYDE_SHELL_INIT}" -ne 1 ]] && eval "$(hyde-shell init)"

cached_search_dir="${XDG_CACHE_HOME:-$HOME/.cache}/hyde/landing/websearch"

declare -A SITES SITES_ICON
search_file=(
    "${SHARE_DIR}/hyde/websearch.lst"
    "${XDG_CONFIG_HOME}/hyde/websearch.lst"
)

# Load search engines from .lst file
load_search_engines() {
    local lst_files=()
    for f in "${search_file[@]}"; do
        [[ $f == *.lst && -f $f ]] && lst_files+=("$f")
    done

    # Use awk to parse all files at once
    # awk splits lines by '|', trims whitespace, and prints shell assignments
    #? This is faster but a forbidden technique!
    eval "$(
        awk -F'|' '
        function trim(s) {
            gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", s);
            return s
        }
        {
            icon = trim($1);
            key = trim($2);
            url = trim($3);
            if (key != "" && url != "") {
                #! Escape double quotes and backslashes in url and icon for safe shell eval
                gsub(/["\\]/, "\\\\&", url);
                gsub(/["\\]/, "\\\\&", icon);
                print "SITES[\"" key "\"]=\"" url "\""
                print "SITES_ICON[\"" key "\"]=\"" icon "\""
            }
        }
        ' "${lst_files[@]}"
    )"
}

# Generate the list of sites
get_sites_list() {
    # Show recent sites first, then the rest, with icons
    {
        local cache="${cached_search_dir}/recent.sites"
        [[ -f "$cache" ]] && awk -F '|' '{gsub(/^[ \t]+|[ \t]+$/, "", $1); print $1}' "$cache" | while read -r key; do
            [[ -n "$key" && -n "${SITES_ICON[$key]}" ]] && printf "%s \t%s\n" "${SITES_ICON[$key]}" "$key"
        done

        for key in "${!SITES[@]}"; do
            [[ -n "${SITES_ICON[$key]}" ]] && printf "%s \t%s\n" "${SITES_ICON[$key]}" "$key"
        done | sort -u
    } | awk '!seen[$0]++'
}

# Generate the list of previously used search queries
get_queries_list() {
    site=$1
    cat "$cached_search_dir/$site.txt" 2>/dev/null || true
}

write_to_top() {
    file=$1
    content=$2
    # Only save valid keys from SITES to recent.sites
    if [[ "$file" == *"recent.sites" ]]; then
        key="$(awk -F '|' '{print $1}' <<<"$content" | xargs)"
        if [[ -n "${SITES[$key]}" ]]; then
            grep -vx "$key" "$file" 2>/dev/null >temp_recent || true
            printf "%s\n" "$key" >"$file"
            cat temp_recent >>"$file"
            rm -f temp_recent
        fi
    else
        # Prepend the new line to the file
        {
            printf "%s\n" "$content"
            cat "$file" 2>/dev/null
        } >temp && mv temp "$file"
        # Remove duplicates and empty lines, keeping the first occurrence (most recent)
        awk 'NF' "$file" | awk '!seen[$0]++' >temp && mv temp "$file"
    fi
}

handle_query() {
    site=$1
    query=$2
    [ -z "$site" ] && exit 0
    [ -z "$query" ] && exit 0
    mkdir -p "$cached_search_dir"
    touch "$cached_search_dir/$site.txt"
    if grep -Fxq "$query" "$cached_search_dir/$site.txt"; then
        printf "%s\n" "$(grep -xv "$query" "$cached_search_dir/$site.txt")" >"$cached_search_dir/$site.txt"
    fi
    write_to_top "$cached_search_dir/$site.txt" "$query"
    write_to_top "$cached_search_dir/recent.sites" "$site | ${SITES[$site]}"

    if [ -n "$BROWSER" ]; then
        printf "Using browser: %s %s\n" "$BROWSER" "${SITES[$site]}$query"
        nohup "$BROWSER" "${SITES[$site]}$query" >/dev/null 2>&1 &
    else
        printf "Using default browser: xdg-open %s\n" "${SITES[$site]}$query"
        [ -z "$BROWSER" ] && nohup xdg-open "${SITES[$site]}$query" >/dev/null 2>&1 &
    fi
}

smart_input() {
    # Handles input like 'goog: some query' with fast fuzzy matching
    local input="$1"
    local site_raw
    local query

    if [[ "$input" == *:* ]]; then
        site_raw="${input%%:*}"
        query="${input#*:}"
    else
        site_raw=$(printf "%s\t" "$input" | cut -f2)
        query=""
    fi

    local site

    # Fast fuzzy match: exact first, then substring (case-insensitive)
    [[ -n "${SITES[$site_raw]}" ]] && site="$site_raw"
    if [[ -z "$site" ]]; then
        for candidate in "${!SITES[@]}"; do
            [[ "${candidate,,}" == *"${site_raw,,}"* ]] && site="$candidate" && break
        done
    fi
    [[ -z "$site" ]] && {
        printf "Unknown site: %s\n" "$site_raw"
        exit 1
    }
    export FINAL_QUERY="$query" FINAL_SITE="$site"
}

# setup rofi configuration
setup_rofi_config() {
    # font scale
    local font_scale="${ROFI_BOOKMARKS_SCALE}"
    [[ "${font_scale}" =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}

    # set font name
    local font_name=${ROFI_BOOKMARKS_FONT:-$ROFI_FONT}
    font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
    font_name=${font_name:-$(get_hyprConf "FONT")}

    # set rofi font override
    font_override="* {font: \"${font_name:-"JetBrainsMono Nerd Font"} ${font_scale}\";}"

    # border settings
    local hypr_border=${hypr_border:-"$(hyprctl -j getoption decoration:rounding | jq '.int')"}
    local wind_border=$((hypr_border * 3 / 2))
    local elem_border=$((hypr_border == 0 ? 5 : hypr_border))

    # border width
    local hypr_width=${hypr_width:-"$(hyprctl -j getoption general:border_size | jq '.int')"}
    r_override="window{border:${hypr_width}px;border-radius:${wind_border}px;}wallbox{border-radius:${elem_border}px;} element{border-radius:${elem_border}px;}"
}

usage() {
    cat <<EOF
--clear-cache               Reset cache
--browser | -b [browser]    Browser to use, defaults to xdg browser
--site | -s [search engine] Search-engine to use
-h | --help                 Show this help message
Available:
$(
        for site in "${!SITES[@]}"; do
            echo -e "\t${SITES_ICON[$site]} $site"
        done | sort
    )
EOF
    exit 0
}

rofi_interactive() {
    unset FINAL_SITE FINAL_QUERY
    setup_rofi_config

    if [[ -n "${SITE_TO_USE}" ]]; then
        if [[ -z "${SITES[$SITE_TO_USE]}" ]]; then
            printf "Invalid site: %s\n" "$FINAL_SITE"
            exit 1
        else
            printf "Using site: %s\n" "$SITE_TO_USE"
            FINAL_SITE="${SITE_TO_USE}"
        fi
    else

        text_input=$(
            get_sites_list |
                rofi -dmenu -i "${ROFI_WEBSEARCH_ARGS[@]}" \
                    -p "🔎 Select engine" \
                    -theme-str "${r_override}" \
                    -config "${ROFI_WEBSEARCH_STYLE:-clipboard}" \
                    -theme-str "entry { placeholder: \"🔎 Search engine...\";}" \
                    -theme-str "${font_override}" \
                    -theme-str "window {width: 50%;}"

        )
        [[ -z "$text_input" ]] && exit 0
        printf "Input: %s\n" "$text_input"
        smart_input "${text_input[@]}"
    fi

    if [[ -z ${FINAL_SITE} ]]; then
        FINAL_SITE=$(awk '{print $1}' <<<"$text_input")
        if [[ -z "${SITES[$FINAL_SITE]}" ]]; then
            printf "Invalid FINAL_SITE: %s\n" "$FINAL_SITE"
            exit 1
        fi
    fi

    if [[ -z ${FINAL_QUERY} ]]; then
        FINAL_QUERY=$(
            get_queries_list "$FINAL_SITE" |
                rofi -dmenu -i "${ROFI_WEBSEARCH_ARGS[@]}" \
                    -theme-str "${r_override}" \
                    -config "${ROFI_WEBSEARCH_STYLE:-clipboard}" \
                    -theme-str "entry { placeholder: \"🔎 Query...\";}" \
                    -theme-str "${font_override}" \
                    -theme-str "window {width: 50%;}"
        )
    fi
    printf "Final site: %s\n" "$FINAL_SITE"
    printf "Final query: %s\n" "$FINAL_QUERY"
    if [[ -n "${FINAL_QUERY}" ]] && [[ -n "${FINAL_SITE}" ]]; then
        handle_query "$FINAL_SITE" "$FINAL_QUERY"
    fi

}

main() {

    while (($# > 0)); do
        case $1 in
        --site | -s)
            if (($# > 1)); then
                SITE_TO_USE="$2"
                shift
            else
                print_log +r "[error] " +y "--site requires an argument."
                usage
            fi
            ;;
        --browser | -b)
            if (($# > 1)); then
                BROWSER="$2"
                shift
            else
                print_log +r "[error] " +y "--browser requires an argument."
                usage
            fi
            ;;
        --clear-cache)
            rm -fr "${cached_search_dir}"
            print_log +g "[ok] " +y "cleared cache"
            exit 0
            ;;
        -h | --help)
            usage
            ;;
        *)
            printf "Unknown option: %s\n" "$1"
            usage
            ;;
        esac
        shift
    done

    load_search_engines
    rofi_interactive
}

main "$@"

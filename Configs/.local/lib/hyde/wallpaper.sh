#!/usr/bin/env bash
# shellcheck disable=SC1091
# shellcheck disable=SC2034
if [[ $HYDE_SHELL_INIT -ne 1 ]]; then
    eval "$(hyde-shell init)"
else
    export_hyde_config
fi

source "$LIB_DIR/hyde/wallpaper/help.sh"
source "$LIB_DIR/hyde/wallpaper/core.sh"
source "$LIB_DIR/hyde/wallpaper/select.sh"

resolve_cache_args() {
    [ "$cache_flag" == "true" ] || return 0
    case "$cache_mode" in
    w | wall | t | theme)
        if [ -z "$cache_arg" ] && [ $# -gt 0 ] && [[ $1 != -* ]]; then
            cache_arg="$1"
        fi
        ;;
    esac
}

run_cache_command() {
    [ "$cache_flag" == "true" ] || return 1
    case "$cache_mode" in
    current)
        "$LIB_DIR/hyde/wallpaper/cache.sh" commence
        ;;
    w | wall)
        if [ -z "$cache_arg" ] || [ ! -f "$cache_arg" ]; then
            print_log -err "wallpaper" "--cache wall requires a valid file path"
            return 1
        fi
        "$LIB_DIR/hyde/wallpaper/cache.sh" commence -w "$cache_arg"
        ;;
    t | theme)
        if [ -z "$cache_arg" ]; then
            print_log -err "wallpaper" "--cache theme requires a theme name"
            return 1
        fi
        "$LIB_DIR/hyde/wallpaper/cache.sh" commence -t "$cache_arg"
        ;;
    f | full | all)
        "$LIB_DIR/hyde/wallpaper/cache.sh" commence -f
        ;;
    *)
        print_log -err "wallpaper" "Invalid cache mode: $cache_mode"
        print_log -sec "wallpaper" "Use: --cache <current|wall|theme|full> [value]"
        return 1
        ;;
    esac
}

validate_multi_select_flags() {
    if [ "$multi_select" == "true" ] && [ "$output_flag" != "true" ]; then
        print_log -err "wallpaper" "--multi-select requires --output"
        return 1
    fi
}

setup_wallpaper_targets() {
    local requires_backend=true
    [ "$output_flag" == "true" ] && requires_backend=false
    case "$wallpaper_setter_flag" in
    g | select | start) requires_backend=false ;;
    esac
    if [ -z "$wallpaper_backend" ] && [ "$requires_backend" = true ]; then
        print_log -sec "wallpaper" -err "No backend specified"
        print_log -sec "wallpaper" " Please specify a backend, try '--backend awww'"
        print_log -sec "wallpaper" " See available commands: '--help | -h'"
        return 1
    fi
    if [ "$set_as_global" == "true" ]; then
        wallSet="$HYDE_THEME_DIR/wall.set"
        wallCur="$HYDE_CACHE_HOME/wall.set"
        wallSqr="$HYDE_CACHE_HOME/wall.sqre"
        wallTmb="$HYDE_CACHE_HOME/wall.thmb"
        wallBlr="$HYDE_CACHE_HOME/wall.blur"
        wallQad="$HYDE_CACHE_HOME/wall.quad"
        wallDcl="$HYDE_CACHE_HOME/wall.dcol"
    elif [ -n "$wallpaper_backend" ]; then
        mkdir -p "$HYDE_CACHE_HOME/wallpapers"
        wallCur="$HYDE_CACHE_HOME/wallpapers/$wallpaper_backend.png"
        wallSet="$HYDE_THEME_DIR/wall.$wallpaper_backend.png"
    else
        wallSet="$HYDE_THEME_DIR/wall.set"
    fi
    if [ ! -e "$wallSet" ]; then
        Wall_Hash
    fi
}

handle_output_mode() {
    [ "$output_flag" == "true" ] || return 1
    local source_path
    if [ "$multi_select" == "true" ] && [ ${#wallpaper_outputs[@]} -gt 0 ]; then
        for out in "${wallpaper_outputs[@]}"; do
            Wall_Select
            if [ -n "$selected_wallpaper_path" ]; then
                source_path="$selected_wallpaper_path"
            else
                source_path="$wallSet"
            fi
            print_log -sec "wallpaper" "Copied $(basename "$source_path") to: $out"
            cp -f "$source_path" "$out"
        done
        return 0
    elif [ "$multi_select" == "true" ] && [ ${#wallpaper_outputs[@]} -eq 0 ]; then
        print_log -err "wallpaper" "--multi-select requires at least one --output"
        return 2
    fi
    if [ "$wallpaper_setter_flag" == "select" ]; then
        Wall_Select
        if [ -n "$selected_wallpaper_path" ]; then
            source_path="$selected_wallpaper_path"
        else
            source_path="$wallSet"
        fi
    else
        source_path="$wallSet"
    fi
    if [ ${#wallpaper_outputs[@]} -eq 0 ] && [ -n "$wallpaper_output" ]; then
        wallpaper_outputs=("$wallpaper_output")
    fi
    wallpaper_name="$(basename "$source_path")"
    for out in "${wallpaper_outputs[@]}"; do
        print_log -sec "wallpaper" "Copied $wallpaper_name to: $out"
        cp -f "$source_path" "$out"
    done
    return 0
}

main() {
    resolve_cache_args "$@"

    if run_cache_command; then
        exit $?
    elif [ "$cache_flag" == "true" ]; then
        exit 1
    fi

    validate_multi_select_flags || exit 1
    setup_wallpaper_targets || exit 1
    handle_output_mode
    case $? in
    0) exit 0 ;;
    2) exit 1 ;;
    esac

    if [ -n "$wallpaper_setter_flag" ]; then
        export WALLPAPER_SET_FLAG="$wallpaper_setter_flag"
        case "$wallpaper_setter_flag" in
        n)
            Wall_Hash
            Wall_Change n
            ;;
        p)
            Wall_Hash
            Wall_Change p
            ;;
        r)
            Wall_Hash
            setIndex=$((RANDOM % ${#wallList[@]}))
            Wall_Cache "${wallList[setIndex]}"
            ;;
        s)
            if [ -z "$wallpaper_path" ] && [ ! -f "$wallpaper_path" ]; then
                print_log -err "wallpaper" "Wallpaper not found: $wallpaper_path"
                exit 1
            fi
            get_hashmap "$wallpaper_path"
            Wall_Cache
            ;;
        start)
            if [ ! -e "$wallSet" ]; then
                print_log -err "wallpaper" "No current wallpaper found: $wallSet"
                exit 1
            fi
            export WALLPAPER_RELOAD_ALL=0 WALLBASH_STARTUP=1
            current_wallpaper="$(realpath "$wallSet")"
            get_hashmap "$current_wallpaper"
            Wall_Cache
            ;;
        g)
            if [ ! -e "$wallSet" ]; then
                print_log -err "wallpaper" "Wallpaper not found: $wallSet"
                exit 1
            fi
            realpath "$wallSet"
            exit 0
            ;;
        o)
            if [ -n "$wallpaper_output" ]; then
                print_log -sec "wallpaper" "Current wallpaper copied to: $wallpaper_output"
                cp -f "$wallSet" "$wallpaper_output"
            fi
            # Output-only: do not proceed to backend apply
            exit 0
            ;;
        select)
            # Warm cache/icons when actually applying a selection (not output-only)
            if [ "$output_flag" != "true" ]; then
                "$LIB_DIR/hyde/wallpaper/cache.sh" commence &>/dev/null &
            fi
            Wall_Select
            get_hashmap "$selected_wallpaper_path"
            Wall_Cache
            ;;
        link)
            Wall_Hash
            Wall_Cache
            exit 0
            ;;
        esac
    fi
    if [ -f "$LIB_DIR/hyde/wallpaper.$wallpaper_backend.sh" ] && [ -n "$wallpaper_backend" ]; then
        print_log -sec "wallpaper" "Using backend: $wallpaper_backend"
        "$LIB_DIR/hyde/wallpaper.$wallpaper_backend.sh" "$wallSet"
    else
        if command -v "wallpaper.$wallpaper_backend.sh" >/dev/null; then
            "wallpaper.$wallpaper_backend.sh" "$wallSet"
        else
            print_log -warn "wallpaper" "No backend script found for $wallpaper_backend"
            print_log -warn "wallpaper" "Created: $HYDE_CACHE_HOME/wallpapers/$wallpaper_backend.png instead"
        fi
    fi
    if [ "$wallpaper_setter_flag" == "select" ]; then
        if [ -e "$(readlink -f "$wallSet")" ]; then
            if [ "$set_as_global" == "true" ]; then
                notify-send -a "HyDE Alert" -i "$selected_thumbnail" "$selected_wallpaper"
            else
                notify-send -a "HyDE Alert" -i "$selected_thumbnail" "$selected_wallpaper set for $wallpaper_backend"
            fi
        else
            notify-send -a "HyDE Alert" "Wallpaper not found"
        fi
    fi
}
if [ -z "$*" ]; then
    echo "No arguments provided"
    show_help
fi
LONGOPTS="link,global,select,multi-select,json,next,previous,random,set:,start,backend:,get,output:,help,filetypes:,cache:"
PARSED=$(getopt --options GSjnprb:s:t:go:h --longoptions "$LONGOPTS" --name "$0" -- "$@") || exit 2
WALLPAPER_OVERRIDE_FILETYPES=()
wallpaper_backend="${WALLPAPER_BACKEND:-awww}"
wallpaper_setter_flag=""
output_flag=false
wallpaper_outputs=()
multi_select=false
cache_flag=false
cache_mode=""
cache_arg=""
eval set -- "$PARSED"
while true; do
    case "$1" in
    -G | --global)
        set_as_global=true
        shift
        ;;
    --link)
        wallpaper_setter_flag="link"
        shift
        ;;
    -j | --json)
        Wall_Json
        exit 0
        ;;
    -S | --select)
        wallpaper_setter_flag=select
        shift
        ;;
    --multi-select)
        multi_select=true
        shift
        ;;
    -n | --next)
        wallpaper_setter_flag=n
        shift
        ;;
    -p | --previous)
        wallpaper_setter_flag=p
        shift
        ;;
    -r | --random)
        wallpaper_setter_flag=r
        shift
        ;;
    -s | --set)
        wallpaper_setter_flag=s
        wallpaper_path="$2"
        shift 2
        ;;
    --start)
        wallpaper_setter_flag=start
        shift
        ;;
    -g | --get)
        wallpaper_setter_flag=g
        shift
        ;;
    -b | --backend)
        wallpaper_backend="${2:-"$WALLPAPER_BACKEND"}"
        shift 2
        ;;
    -o | --output)
        wallpaper_output="$2"
        wallpaper_outputs+=("$2")
        output_flag=true
        shift 2
        ;;
    -t | --filetypes)
        IFS=':' read -r -a WALLPAPER_OVERRIDE_FILETYPES <<<"$2"
        if [ "$LOG_LEVEL" == "debug" ]; then
            for i in "${WALLPAPER_OVERRIDE_FILETYPES[@]}"; do
                print_log -g "DEBUG:" -b "filetype overrides : " "'$i'"
            done
        fi
        export WALLPAPER_OVERRIDE_FILETYPES
        shift 2
        ;;
    --cache)
        cache_flag=true
        cache_mode="$2"
        shift 2
        ;;
    -h | --help)
        show_help
        ;;
    --)
        shift
        break
        ;;
    *)
        echo "Invalid option: $1"
        echo "Try '$(basename "$0") --help' for more information."
        exit 1
        ;;
    esac
done

main "$@"

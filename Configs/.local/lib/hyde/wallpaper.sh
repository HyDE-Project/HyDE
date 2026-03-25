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

main() {
    # Enforce that --multi-select is only used with --output
    if [ "$multi_select" == "true" ] && [ "$output_flag" != "true" ]; then
        print_log -err "wallpaper" "--multi-select requires --output"
        exit 1
    fi

    requires_backend=true
    [ "$output_flag" == "true" ] && requires_backend=false
    case "$wallpaper_setter_flag" in
    g | select | start) requires_backend=false ;;
    esac
    if [ -z "$wallpaper_backend" ] && [ "$requires_backend" = true ]; then
        print_log -sec "wallpaper" -err "No backend specified"
        print_log -sec "wallpaper" " Please specify a backend, try '--backend awww'"
        print_log -sec "wallpaper" " See available commands: '--help | -h'"
        exit 1
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
    # If output-only is requested, perform copies and exit early.
    if [ "$output_flag" == "true" ]; then
        local source_path
        # Multi-select: open selection once per output path
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
            exit 0
        elif [ "$multi_select" == "true" ] && [ ${#wallpaper_outputs[@]} -eq 0 ]; then
            print_log -err "wallpaper" "--multi-select requires at least one --output"
            exit 1
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
        # If no outputs captured (unexpected), fallback to single `wallpaper_output`
        if [ ${#wallpaper_outputs[@]} -eq 0 ] && [ -n "$wallpaper_output" ]; then
            wallpaper_outputs=("$wallpaper_output")
        fi
        wallpaper_name="$(basename "$source_path")"
        for out in "${wallpaper_outputs[@]}"; do
            print_log -sec "wallpaper" "Copied $wallpaper_name to: $out"
            cp -f "$source_path" "$out"
        done
        exit 0
    fi
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
                "$LIB_DIR/hyde/swwwallcache.sh" w &>/dev/null &
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
LONGOPTS="link,global,select,multi-select,json,next,previous,random,set:,start,backend:,get,output:,help,filetypes:"
PARSED=$(getopt --options GSjnprb:s:t:go:h --longoptions "$LONGOPTS" --name "$0" -- "$@") || exit 2
WALLPAPER_OVERRIDE_FILETYPES=()
wallpaper_backend="${WALLPAPER_BACKEND:-awww}"
wallpaper_setter_flag=""
output_flag=false
wallpaper_outputs=()
multi_select=false
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
main

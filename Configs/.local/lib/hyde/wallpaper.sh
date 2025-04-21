#!/usr/bin/env bash
# shellcheck disable=SC2154

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"

# // Help message
show_help() {
    cat <<EOF
Usage: $(basename "$0") --[options|flags] [parameters]
options:
    -j, --json                List wallpapers in JSON format to STDOUT
    -S, --select              Select wallpaper using rofi
    -n, --next                Set next wallpaper
    -p, --previous            Set previous wallpaper
    -r, --random              Set random wallpaper
    -s, --set <file>          Set specified wallpaper
    -g, --get                 Get current wallpaper of specified backend
    -o, --output <file>       Copy current wallpaper to specified file
        --link                Resolved the linked wallpaper according to the theme
    -t  --filetypes <types>   Specify file types to override (colon-separated ':')
    -h, --help                Display this help message

flags:
    -b, --backend <backend>   Set wallpaper backend to use (swww, hyprpaper, etc.)
    -G, --global              Set wallpaper as global


notes: 
       --backend <backend> is also use to cache wallpapers/background images e.g. hyprlock
           when '--backend hyprlock' is used, the wallpaper will be cached in
           ~/.cache/hyde/wallpapers/hyprlock.png

       --global flag is used to set the wallpaper as global, this means all
         thumbnails will be updated to reflect the new wallpaper

       --output <path> is used to copy the current wallpaper to the specified path
            We can use this to have a copy of the wallpaper to '/var/tmp' where sddm or
            any systemwide application can access it  
EOF
    exit 0
}
#// Set and Cache Wallpaper

Wall_Cache() {
    ln -fs "${wallList[setIndex]}" "${wallSet}"
    ln -fs "${wallList[setIndex]}" "${wallCur}"
    if [ "${set_as_global}" == "true" ]; then
        print_log -sec "wallpaper" "Setting Wallpaper as global"
        "${scrDir}/swwwallcache.sh" -w "${wallList[setIndex]}" &>/dev/null
        "${scrDir}/color.set.sh" "${wallList[setIndex]}" &
        ln -fs "${thmbDir}/${wallHash[setIndex]}.sqre" "${wallSqr}"
        ln -fs "${thmbDir}/${wallHash[setIndex]}.thmb" "${wallTmb}"
        ln -fs "${thmbDir}/${wallHash[setIndex]}.blur" "${wallBlr}"
        ln -fs "${thmbDir}/${wallHash[setIndex]}.quad" "${wallQad}"
        ln -fs "${dcolDir}/${wallHash[setIndex]}.dcol" "${wallDcl}"
    fi

}

Wall_Change() {
    curWall="$(set_hash "${wallSet}")"
    for i in "${!wallHash[@]}"; do
        if [ "${curWall}" == "${wallHash[i]}" ]; then
            if [ "${1}" == "n" ]; then
                setIndex=$(((i + 1) % ${#wallList[@]}))
            elif [ "${1}" == "p" ]; then
                setIndex=$((i - 1))
            fi
            break
        fi
    done
    Wall_Cache "${wallList[setIndex]}"
}

# * Method to list wallpapers from hashmaps into json
Wall_Json() {
    setIndex=0
    [ ! -d "${HYDE_THEME_DIR}" ] && echo "ERROR: \"${HYDE_THEME_DIR}\" does not exist" && exit 0
    wallPathArray=("${HYDE_THEME_DIR}")
    wallPathArray+=("${WALLPAPER_CUSTOM_PATHS[@]}")

    get_hashmap "${wallPathArray[@]}" # get the hashmap provides wallList and wallHash

    # Prepare data for jq
    wallListJson=$(printf '%s\n' "${wallList[@]}" | jq -R . | jq -s .)
    wallHashJson=$(printf '%s\n' "${wallHash[@]}" | jq -R . | jq -s .)

    # Create JSON using jq
    jq -n --argjson wallList "$wallListJson" --argjson wallHash "$wallHashJson" --arg cacheHome "${HYDE_CACHE_HOME:-$HOME/.cache/hyde}" '
        [range(0; $wallList | length) as $i | 
            {
                path: $wallList[$i], 
                hash: $wallHash[$i], 
                basename: ($wallList[$i] | split("/") | last),
                thmb: "\($cacheHome)/thumbs/\($wallHash[$i]).thmb",
                sqre: "\($cacheHome)/thumbs/\($wallHash[$i]).sqre",
                blur: "\($cacheHome)/thumbs/\($wallHash[$i]).blur",
                quad: "\($cacheHome)/thumbs/\($wallHash[$i]).quad",
                dcol: "\($cacheHome)/dcols/\($wallHash[$i]).dcol",
                rofi_sqre: "\($wallList[$i] | split("/") | last):::\($wallList[$i]):::\($cacheHome)/thumbs/\($wallHash[$i]).sqre\u0000icon\u001f\($cacheHome)/thumbs/\($wallHash[$i]).sqre",
                rofi_thmb: "\($wallList[$i] | split("/") | last):::\($wallList[$i]):::\($cacheHome)/thumbs/\($wallHash[$i]).thmb\u0000icon\u001f\($cacheHome)/thumbs/\($wallHash[$i]).thmb",
                rofi_blur: "\($wallList[$i] | split("/") | last):::\($wallList[$i]):::\($cacheHome)/thumbs/\($wallHash[$i]).blur\u0000icon\u001f\($cacheHome)/thumbs/\($wallHash[$i]).blur",
                rofi_quad: "\($wallList[$i] | split("/") | last):::\($wallList[$i]):::\($cacheHome)/thumbs/\($wallHash[$i]).quad\u0000icon\u001f\($cacheHome)/thumbs/\($wallHash[$i]).quad",

            }
        ]
    '
}

Wall_Select() {
    font_scale="${ROFI_WALLPAPER_SCALE}"
    [[ "${font_scale}" =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}

    # set font name
    font_name=${ROFI_WALLPAPER_FONT:-$ROFI_FONT}
    font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
    font_name=${font_name:-$(get_hyprConf "FONT")}

    # set rofi font override
    font_override="* {font: \"${font_name:-"JetBrainsMono Nerd Font"} ${font_scale}\";}"

    # shellcheck disable=SC2154
    elem_border=$((hypr_border * 3))

    #// scale for monitor

    mon_data=$(hyprctl -j monitors)
    mon_x_res=$(jq '.[] | select(.focused==true) | if (.transform % 2 == 0) then .width else .height end' <<<"${mon_data}")
    mon_scale=$(jq '.[] | select(.focused==true) | .scale' <<<"${mon_data}" | sed "s/\.//")
    mon_x_res=$((mon_x_res * 100 / mon_scale))

    #// generate config

    elm_width=$(((28 + 8 + 5) * font_scale))
    max_avail=$((mon_x_res - (4 * font_scale)))
    col_count=$((max_avail / elm_width))

    r_override="window{width:100%;}
    listview{columns:${col_count};spacing:5em;}
    element{border-radius:${elem_border}px;
    orientation:vertical;} 
    element-icon{size:28em;border-radius:0em;}
    element-text{padding:1em;}"

    #// launch rofi menu
    local entry
    entry=$(

        Wall_Json | jq -r '.[].rofi_sqre' | rofi -dmenu \
            -display-column-separator ":::" \
            -display-columns 1 \
            -theme-str "${font_override}" \
            -theme-str "${r_override}" \
            -theme "${ROFI_WALLPAPER_STYLE:-selector}" \
            -select "$(basename "$(readlink "$wallSet")")"
    )
    selected_thumbnail="$(awk -F ':::' '{print $3}' <<<"${entry}")"
    selected_wallpaper_path="$(awk -F ':::' '{print $2}' <<<"${entry}")"
    selected_wallpaper="$(awk -F ':::' '{print $1}' <<<"${entry}")"
    export selected_wallpaper selected_wallpaper_path selected_thumbnail
    if [ -z "${selected_wallpaper}" ]; then
        print_log -err "wallpaper" " No wallpaper selected"
        exit 0
    fi
}

Wall_Hash() {
    # * Method to load wallpapers in hashmaps and fix broken links per theme
    setIndex=0
    [ ! -d "${HYDE_THEME_DIR}" ] && echo "ERROR: \"${HYDE_THEME_DIR}\" does not exist" && exit 0
    wallPathArray=("${HYDE_THEME_DIR}")
    wallPathArray+=("${WALLPAPER_CUSTOM_PATHS[@]}")
    get_hashmap "${wallPathArray[@]}"
    [ ! -e "$(readlink -f "${wallSet}")" ] && echo "fixing link :: ${wallSet}" && ln -fs "${wallList[setIndex]}" "${wallSet}"
}

main() {
    #// set full cache variables
    if [ -z "$wallpaper_backend" ] &&
        [ "$wallpaper_setter_flag" != "o" ] &&
        [ "$wallpaper_setter_flag" != "g" ] &&
        [ "$wallpaper_setter_flag" != "select" ]; then
        print_log -sec "wallpaper" -err "No backend specified"
        print_log -sec "wallpaper" " Please specify a backend, try '--backend swww'"
        print_log -sec "wallpaper" " See available commands: '--help | -h'"
        exit 1
    fi

    # * --global flag is used to set the wallpaper as global, this means caching the wallpaper to thumbnails
    #  If wallpaper is used for thumbnails, set the following variables
    if [ "$set_as_global" == "true" ]; then
        wallSet="${HYDE_THEME_DIR}/wall.set"
        wallCur="${HYDE_CACHE_HOME}/wall.set"
        wallSqr="${HYDE_CACHE_HOME}/wall.sqre"
        wallTmb="${HYDE_CACHE_HOME}/wall.thmb"
        wallBlr="${HYDE_CACHE_HOME}/wall.blur"
        wallQad="${HYDE_CACHE_HOME}/wall.quad"
        wallDcl="${HYDE_CACHE_HOME}/wall.dcol"
    elif [ -n "${wallpaper_backend}" ]; then
        mkdir -p "${HYDE_CACHE_HOME}/wallpapers"
        wallCur="${HYDE_CACHE_HOME}/wallpapers/${wallpaper_backend}.png"
        wallSet="${HYDE_THEME_DIR}/wall.${wallpaper_backend}.png"
    else
        wallSet="${HYDE_THEME_DIR}/wall.set"
    fi

    if [ -n "${wallpaper_setter_flag}" ]; then
        export WALLPAPER_SET_FLAG="${wallpaper_setter_flag}"
        case "${wallpaper_setter_flag}" in
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
            if [ -z "${wallpaper_path}" ] && [ ! -f "${wallpaper_path}" ]; then
                print_log -err "wallpaper" "Wallpaper not found: ${wallpaper_path}"
                exit 1
            fi
            get_hashmap "${wallpaper_path}"
            Wall_Cache
            ;;
        g)
            if [ ! -e "${wallSet}" ]; then
                print_log -err "wallpaper" "Wallpaper not found: ${wallSet}"
                exit 1
            fi
            realpath "${wallSet}"
            exit 0
            ;;
        o)
            if [ -n "${wallpaper_output}" ]; then
                print_log -sec "wallpaper" "Current wallpaper copied to: ${wallpaper_output}"
                cp -f "${wallSet}" "${wallpaper_output}"
            fi
            ;;
        select)
            Wall_Select
            get_hashmap "${selected_wallpaper_path}"
            Wall_Cache
            ;;
        link)
            Wall_Hash
            Wall_Cache
            exit 0
            ;;
        esac
    fi

    # Apply wallpaper to  backend
    if [ -f "${scrDir}/wallpaper.${wallpaper_backend}.sh" ] && [ -n "${wallpaper_backend}" ]; then
        print_log -sec "wallpaper" "Using backend: ${wallpaper_backend}"
        "${scrDir}/wallpaper.${wallpaper_backend}.sh" "${wallSet}"
    else
        if command -v "wallpaper.${wallpaper_backend}.sh" >/dev/null; then
            "wallpaper.${wallpaper_backend}.sh" "${wallSet}"
        else
            print_log -warn "wallpaper" "No backend script found for ${wallpaper_backend}"
            print_log -warn "wallpaper" "Created: $HYDE_CACHE_HOME/wallpapers/${wallpaper_backend}.png instead"
        fi
    fi

    if [ "${wallpaper_setter_flag}" == "select" ]; then
        if [ -e "$(readlink -f "${wallSet}")" ]; then
            if [ "${set_as_global}" == "true" ]; then
                notify-send -a "HyDE Alert" -i "${selected_thumbnail}" "${selected_wallpaper}"
            else
                notify-send -a "HyDE Alert" -i "${selected_thumbnail}" "${selected_wallpaper} set for ${wallpaper_backend}"
            fi
        else
            notify-send -a "HyDE Alert" "Wallpaper not found"
        fi
    fi
}

#// evaluate options

if [ -z "${*}" ]; then
    echo "No arguments provided"
    show_help
fi

# Define long options
LONGOPTS="link,global,select,json,next,previous,random,set:,backend:,get,output:,help,filetypes:"

# Parse options
PARSED=$(
    if getopt --options GSjnprb:s:t:go:h --longoptions $LONGOPTS --name "$0" -- "$@"; then
        exit 2
    fi
)

# Initialize the array for filetypes
WALLPAPER_OVERRIDE_FILETYPES=()

wallpaper_backend="${WALLPAPER_BACKEND:-swww}"
wallpaper_setter_flag=""
# Apply parsed options
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
        "${scrDir}/swwwallcache.sh" w &>/dev/null &
        wallpaper_setter_flag=select
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
        wallpaper_path="${2}"
        shift 2
        ;;
    -g | --get)
        wallpaper_setter_flag=g
        shift
        ;;
    -b | --backend)
        # Set wallpaper backend to use (swww, hyprpaper, etc.)
        wallpaper_backend="${2:-"$WALLPAPER_BACKEND"}"
        shift 2
        ;;
    -o | --output)
        # Accepts wallpaper output path
        wallpaper_setter_flag=o
        wallpaper_output="${2}"
        shift 2
        ;;
    -t | --filetypes)
        IFS=':' read -r -a WALLPAPER_OVERRIDE_FILETYPES <<<"$2"
        if [ "${LOG_LEVEL}" == "debug" ]; then
            for i in "${WALLPAPER_OVERRIDE_FILETYPES[@]}"; do
                print_log -g "DEBUG:" -b "filetype overrides : " "'${i}'"
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

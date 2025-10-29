#!/usr/bin/env bash

[[ "${HYDE_SHELL_INIT}" -ne 1 ]] && eval "$(hyde-shell init)"

style=${1}

# check if 1st args is only number an single argument
if [ "$#" -lt 2 ] && [[ "$1" =~ ^[0-9]+$ ]]; then
    print_log -y "Please use --backend and --style flags... this usage will be deprecated"
else

    # now add arg parsing for multiple flags loop

    # Define short and long options
    SHORTOPTS="s:b:h"
    LONGOPTS="style:,backend:,help"

    # Parse options
    PARSED=$(
        getopt --options "${SHORTOPTS}" --longoptions "${LONGOPTS}" --name "$0" -- "$@"
    )
    if [[ $? -ne 0 ]]; then
        exit 2
    fi
    eval set -- "${PARSED}"

    # Existing argument parsing logic
    while [[ $# -gt 0 ]]; do
        case $1 in
        -s | --style)
            style="$2"
            shift 2
            ;;
        -b | --backend)
            backend="$2"
            shift 2
            ;;
        -h | --help)
            cat <<EOF
Usage: $0 [options]
  -s, --style   Specify the style
  -b, --backend Specify the backend
  -h, --help    Show this help message
EOF
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            shift
            ;;
        esac
    done

fi

if [[ "$style" =~ ^[0-9]+$ ]]; then
    RofiConf="gamelauncher_${style}"
else
    RofiConf="${style:-$ROFI_GAMELAUNCHER_STYLE}"
fi

RofiConf=${RofiConf:-"steam_deck"}

elem_border=$((hypr_border * 2))
icon_border=$((elem_border - 3))
r_override="element{border-radius:${elem_border}px;} element-icon{border-radius:${icon_border}px;}"

[[ -n "${ROFI_GAMELAUNCHER_STYLE}" ]] && style=${ROFI_GAMELAUNCHER_STYLE}
case ${style:-5} in
5 | steam_deck)
    monitor_info=()
    eval "$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) |
    "monitor_info=(\(.width) \(.height) \(.scale) \(.x) \(.y)) reserved_info=(\(.reserved | join(" ")))"')"
    percent=80

    monitor_scale="${monitor_info[2]//./}"

    monitor_width=$((monitor_info[0] * $percent / monitor_scale))

    monitor_height=$((monitor_info[1] * $percent / monitor_scale))

    BG=$HOME/.local/share/hyde/rofi/assets/steamdeck_holographic.png
    BGfx=$HOME/.cache/hyde/landing/steamdeck_holographic_${monitor_width}x${monitor_height}.png

    if [ ! -e "${BGfx}" ]; then
        magick "${BG}" -resize ${monitor_width}x${monitor_height} -background none -gravity center -extent ${monitor_width}x${monitor_height} "$BGfx"
    fi

    r_override="window {width: ${monitor_width}px; height: ${monitor_height}; background-image: url('${BGfx}',width);}  
                element-icon {border-radius:0px;}
                mainbox { padding: 17% 18%; }
                "
    ;;

*) ;;
esac

backend_command=()
rofi_args=()

case "${backend}" in
steam)
    backend_command=(python3 "${LIB_DIR}/hyde/gamelauncher/steam.py" --rofi-string)
    ;;
lutris)
    backend_command=(python3 "${LIB_DIR}/hyde/gamelauncher/lutris.py" --rofi-string)
    ;;
*)
    backend_command=(python3 "${LIB_DIR}/hyde/gamelauncher/catalog.py" --rofi-string)
    rofi_args=(-markup-rows)
    ;;
esac

CHOICE=$("${backend_command[@]}" |
    rofi -dmenu -p Catalog \
        -theme-str "$r_override" \
        -display-columns 1 \
        "${rofi_args[@]}" \
        -config "$RofiConf")

if [ -z "$CHOICE" ]; then
    exit 0
fi

CMD=${CHOICE#*$'\t'}
eval exec "${CMD}"

#!/usr/bin/env bash
[[ $HYDE_SHELL_INIT -ne 1 ]] && eval "$(hyde-shell init)"
style=$1
if [ "$#" -lt 2 ] && [[ $1 =~ ^[0-9]+$ ]]; then
    print_log -y "Please use --backend and --style flags... this usage will be deprecated"
else

    # shellcheck disable=SC1091
    source "${LIB_DIR}/hyde/shutils/argparse.sh"
    argparse_init "$@"

    argparse_program "hyde-shell gamelauncher"
    argparse_header "HyDE Game Launcher"

    argparse "--style,-s" "STYLE" "Specify the style" "parameter"
    argparse "--backend,-b" "BACKEND" "Specify the backend" "parameter"

    argparse_finalize

    style="${STYLE:-$style}"
    backend="${BACKEND:-$backend}"

fi

if [[ $style =~ ^[0-9]+$ ]]; then
    rofi_config="gamelauncher_$style"
else
    rofi_config="${style:-$ROFI_GAMELAUNCHER_STYLE}"
fi
rofi_config=${rofi_config:-"steam_deck"}
elem_border=$((hypr_border * 2))
icon_border=$((elem_border - 3))
r_override="element{border-radius:${elem_border}px;} element-icon{border-radius:${icon_border}px;}"
[[ -n $ROFI_GAMELAUNCHER_STYLE ]] && style=$ROFI_GAMELAUNCHER_STYLE
case ${style:-5} in
5 | steam_deck)
    monitor_info=()
    eval "$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) |
    "monitor_info=(\(.width) \(.height) \(.scale) \(.x) \(.y)) reserved_info=(\(.reserved | join(" ")))"')"
    percent=80
    monitor_scale="${monitor_info[2]//./}"
    monitor_width=$((monitor_info[0] * percent / monitor_scale))
    monitor_height=$((monitor_info[1] * percent / monitor_scale))
    BG=$HOME/.local/share/hyde/rofi/assets/steamdeck_holographic.png
    BGfx=$HOME/.cache/hyde/landing/steamdeck_holographic_${monitor_width}x$monitor_height.png
    if [ ! -e "$BGfx" ]; then
        magick "$BG" -resize ${monitor_width}x$monitor_height -background none -gravity center -extent ${monitor_width}x$monitor_height "$BGfx"
    fi
    r_override="window {width: ${monitor_width}px; height: $monitor_height; background-image: url('$BGfx',width);}
                element-icon {border-radius:0px;}
                mainbox { padding: 17% 18%; }
                "
    ;;
*) ;;
esac

backend_command=()
rofi_args=()

case "$backend" in
steam)
    backend_command=(python3 "$LIB_DIR/hyde/gamelauncher/steam.py" --rofi-string)
    ;;
lutris)
    backend_command=(python3 "$LIB_DIR/hyde/gamelauncher/lutris.py" --rofi-string)
    ;;
*)
    backend_command=(python3 "$LIB_DIR/hyde/gamelauncher/catalog.py" --rofi-string)
    rofi_args=(-markup-rows)
    ;;
esac

selected=$("${backend_command[@]}" | rofi -dmenu -p Catalog \
    -theme-str "$r_override" \
    -display-columns 1 \
    "${rofi_args[@]}" \
    -config "$rofi_config")
if [ -z "$selected" ]; then
    exit 0
fi

cmd=${selected#*$'\t'}

eval exec "$cmd"

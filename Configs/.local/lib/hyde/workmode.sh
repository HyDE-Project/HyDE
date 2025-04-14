#!/usr/bin/env sh

MODE_PATH="$HOME/.cache/workflow"
TMP_PATH="$XDG_RUNTIME_DIR/workflow"

if [ "$1" = "g" ]; then
    mode=$(cat "$MODE_PATH")
    case $mode in
        0) echo "󰸶" ;;
        1) echo "󰸸" ;;
        2) echo "󰸷" ;;
        3) echo "󰸴" ;;
        4) echo "󰸵" ;;
    esac
    exit 0
fi

cycle_mode() {
    local mode=$1
    mode=$((mode + 1))
    [ $mode -gt 4 ] && mode=0
    echo $mode
}

update_mode_files() {
    local mode=$1
    echo $mode >"$TMP_PATH"
    echo $mode >"$MODE_PATH"
}

if [ ! -f "$TMP_PATH" ]; then
    mkdir -p "$(dirname "$MODE_PATH")"
    [ ! -f "$MODE_PATH" ] && echo 0 >"$MODE_PATH"
    mode=$(cat "$MODE_PATH")
else
    mode=$(cat "$TMP_PATH")
    [ $# -eq 0 ] && mode=$(cycle_mode "$mode") && hyprctl reload
fi

update_mode_files "$mode"

case $mode in
0)  
    ;;
1)
    hyprctl --batch "keyword decoration:blur:enabled 0; \
                     keyword decoration:shadow:enabled 0; \
                     keyword decoration:active_opacity 2; \
                     keyword decoration:inactive_opacity 2"
    hyprctl 'keyword windowrulev2 opaque,class:(.*)' # ensure all windows are opaque
    ;;
2)
    hyprctl --batch "keyword animations:enabled 0; \
                     keyword decoration:blur:enabled 0; \
                     keyword decoration:shadow:enabled 0; \
                     keyword general:gaps_in 0; \
                     keyword general:gaps_out 0; \
                     keyword general:border_size 0; \
                     keyword decoration:active_opacity 2; \
                     keyword decoration:inactive_opacity 2; \
                     keyword decoration:rounding 0"
    hyprctl 'keyword windowrulev2 opaque,class:(.*)' # ensure all windows are opaque
    ;;
3)
    hyprctl --batch "keyword animations:enabled 0; \
                     keyword decoration:blur:enabled 0; \
                     keyword decoration:shadow:enabled 0; \
                     keyword general:gaps_in 0; \
                     keyword general:gaps_out 0; \
                     keyword general:border_size 0; \
                     keyword decoration:rounding 0"
    ;;
4)
    hyprctl --batch "keyword animations:enabled 0; \
                     keyword general:gaps_in 0; \
                     keyword general:gaps_out 0; \
                     keyword general:border_size 0; \
                     keyword decoration:rounding 0"
    ;;
esac

pkill -RTMIN+10 waybar

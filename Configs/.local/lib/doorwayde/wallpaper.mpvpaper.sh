#!/usr/bin/env bash
if ! source "$(which doorwayde-shell)"; then
    echo "[wallbash] code :: Error: doorwayde-shell not found."
    echo "[wallbash] code :: Is DOORwayDE installed?"
    exit 1
fi
selected_wall="${1:-${XDG_CACHE_HOME:-$HOME/.cache}/doorwayde/wall.set}"
[ -z "$selected_wall" ] && echo "No input wallpaper" && exit 1
selected_wall="$(readlink -f "$selected_wall")"
pkill -O -x mpvpaper || true
mpvpaper -p '*' "$selected_wall" --fork --mpv-options "no-audio loop --geometry=100%:100% --panscan=1.0"

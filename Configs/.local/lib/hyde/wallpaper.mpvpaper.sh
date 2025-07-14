#!/usr/bin/env bash

[[ "${HYDE_SHELL_INIT}" -ne 1 ]] && eval "$(hyde-shell init)"

selected_wall="${1:-${XDG_CACHE_HOME:-$HOME/.cache}/hyde/wall.set}"
[ -z "${selected_wall}" ] && echo "No input wallpaper" && exit 1
selected_wall="$(readlink -f "${selected_wall}")"

# Let's kill all old mpvpaper instances
pkill -O -x mpvpaper || true
mpvpaper -p '*' "${selected_wall}" --fork --mpv-options "no-audio loop --geometry=100%:100% --panscan=1.0"

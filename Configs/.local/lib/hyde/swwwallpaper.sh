#!/usr/bin/env bash
cat << EOF
DEPRECATION: This script is deprecated, please use 'wallpaper.sh' instead."

-------------------------------------------------
example: 
wallpaper.sh --select --backend swww --global
-------------------------------------------------
EOF
script_dir="$(dirname "$(realpath "$0")")"
"$script_dir/wallpaper.sh" "$@" --backend swww --global

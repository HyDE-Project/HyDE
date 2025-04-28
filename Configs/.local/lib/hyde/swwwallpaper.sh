#!/usr/bin/env bash
# shellcheck disable=SC2154

cat <<EOF
DEPRECATION: This script is deprecated, please use 'wallpaper.sh' instead."

-------------------------------------------------
example: 
wallpaper.sh --select --backend swww --global
-------------------------------------------------
EOF

script_dir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
"${script_dir}/wallpaper.sh" "${@}" --backend swww --global

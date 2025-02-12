#!/usr/bin/env bash
# shellcheck disable=SC2154

cat <<EOF
DEPRECATION: This script is deprecated, please use 'wallpaper.sh' instead."

-------------------------------------------------
example: 
wallpaper.sh ${@} --backend swww --global
-------------------------------------------------
EOF

"wallpaper.sh" "${@}" --backend swww --global

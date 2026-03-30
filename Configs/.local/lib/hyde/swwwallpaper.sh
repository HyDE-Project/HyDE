#!/usr/bin/env bash
<<<<<<< HEAD
# shellcheck disable=SC2154

cat <<EOF
=======
cat << EOF
>>>>>>> master
DEPRECATION: This script is deprecated, please use 'wallpaper.sh' instead."

-------------------------------------------------
example: 
wallpaper.sh --select --backend awww --global
-------------------------------------------------
EOF
<<<<<<< HEAD

script_dir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
"${script_dir}/wallpaper.sh" "${@}" --backend awww --global
=======
script_dir="$(dirname "$(realpath "$0")")"
"$script_dir/wallpaper.sh" "$@" --backend awww --global
>>>>>>> master

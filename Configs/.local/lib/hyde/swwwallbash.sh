#!/usr/bin/env bash
# shellcheck disable=SC2154

cat <<EOF
DEPRECATION: This script is deprecated, please use 'color.set.sh' instead."

-------------------------------------------------
example: 
color.set.sh <path/to/image> 
-------------------------------------------------
EOF

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
"${scrDir}/color.set.sh" "${@}"

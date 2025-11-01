#!/usr/bin/env bash
cat <<EOF
DEPRECATION: This script is deprecated, please use 'color.set.sh' instead."

-------------------------------------------------
example: 
color.set.sh <path/to/image> 
-------------------------------------------------
EOF
scrDir="$(dirname "$(realpath "$0")")"
"$scrDir/color.set.sh" "$@"

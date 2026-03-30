#!/usr/bin/env bash
<<<<<<< HEAD
# shellcheck disable=SC2154

cat <<EOF
=======
cat << EOF
>>>>>>> master
DEPRECATION: This script is deprecated, please use 'color.set.sh' instead."

-------------------------------------------------
example: 
color.set.sh <path/to/image> 
-------------------------------------------------
EOF
<<<<<<< HEAD

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
"${scrDir}/color.set.sh" "${@}"
=======
scrDir="$(dirname "$(realpath "$0")")"
"$scrDir/color.set.sh" "$@"
>>>>>>> master

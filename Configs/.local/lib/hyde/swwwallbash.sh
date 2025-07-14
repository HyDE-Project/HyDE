#!/usr/bin/env bash
# shellcheck disable=SC2154

cat <<EOF
DEPRECATION: This script is deprecated, please use 'color.set.sh' instead."

-------------------------------------------------
example: 
color.set.sh <path/to/image> 
-------------------------------------------------
EOF

[[ "${HYDE_SHELL_INIT}" -ne 1 ]] && eval "$(hyde-shell init)"
"${LIB_DIR}/hyde/color.set.sh" "$@"

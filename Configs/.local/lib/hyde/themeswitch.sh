#!/usr/bin/env bash

echo "This script will be deprecated. Please use theme.switch.sh instead."
[[ "${HYDE_SHELL_INIT}" -ne 1 ]] && eval "$(hyde-shell init)"
"${LIB_DIR}/hyde/theme.switch.sh" "$@"

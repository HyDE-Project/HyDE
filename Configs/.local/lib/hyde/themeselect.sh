#!/usr/bin/env bash

[[ "${HYDE_SHELL_INIT}" -ne 1 ]] && eval "$(hyde-shell init)"
"${LIB_DIR}/hyde/theme.select.sh" "$@"

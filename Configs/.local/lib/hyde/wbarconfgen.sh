#!/usr/bin/env bash

# read control file and initialize variables

[[ "${HYDE_SHELL_INIT}" -ne 1 ]] && eval "$(hyde-shell init)"

echo "DEPRECATION: The $0 will be removed in the future."
if [ -z "${1}" ]; then
    "${LIB_DIR}/hyde/waybar.py" --update
else
    "${LIB_DIR}/hyde/waybar.py" --update "-${1}"
fi

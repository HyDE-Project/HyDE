#!/usr/bin/env bash

[[ "${HYDE_SHELL_INIT}" -ne 1 ]] && eval "$(hyde-shell init)"

echo "DEPRECATION: The $0 will be removed in the future."
if [ -z "${1}" ]; then
    waybar.py --update
else
    waybar.py --update "-${1}"
fi

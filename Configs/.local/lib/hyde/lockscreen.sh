#!/usr/bin/env bash

[[ "${HYDE_SHELL_INIT}" -ne 1 ]] && eval "$(hyde-shell init)"

lockscreen="${LOCKSCREEN:-hyprlock}"

if ! hyde-shell "${lockscreen}.sh" "${@}" ; then
    printf "Executing raw command: %s\n" "${lockscreen}"
    "${lockscreen}" "${@}"
fi

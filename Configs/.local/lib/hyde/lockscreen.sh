#!/usr/bin/env bash

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck source=$HOME/.local/lib/hyde/globalcontrol.sh
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"

lockscreen="${LOCKSCREEN:-hyprlock}"

if ! hyde-shell "${lockscreen}.sh" "${@}"; then
    printf "Executing raw command: %s\n" "${lockscreen}"
    app2unit.sh "${lockscreen}" "${@}"
fi

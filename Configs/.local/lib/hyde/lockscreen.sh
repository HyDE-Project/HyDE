#!/usr/bin/env bash

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck source=$HOME/.local/lib/hyde/globalcontrol.sh
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"

"${LOCKSCREEN:-hyprlock}" "${@}"

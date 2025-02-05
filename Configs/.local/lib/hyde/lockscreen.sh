#!/usr/bin/env bash

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck source=$HOME/.local/lib/hyde/globalcontrol.sh
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"
HYDE_RUNTIME_DIR="${HYDE_RUNTIME_DIR:-$XDG_RUNTIME_DIR/hyde}"
# shellcheck disable=SC1091
source "${HYDE_RUNTIME_DIR}/environment"

"${LOCKSCREEN}" "${@}"

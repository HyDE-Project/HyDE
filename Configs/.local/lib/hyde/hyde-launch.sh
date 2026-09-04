#!/usr/bin/env bash
[[ $HYDE_SHELL_INIT -ne 1 ]] && eval "$(hyde-shell init)"

# shellcheck disable=SC1091
[[ -f "${LIB_DIR}/hyde/shutils/l10n.sh" ]] && source "${LIB_DIR}/hyde/shutils/l10n.sh"

send_notifs -a "Deprecation Notice" "hyde-launch.sh is deprecated. Please use hyde-shell open instead." -i dialog-information

hyde-shell open "$@"

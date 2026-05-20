#!/usr/bin/env bash
[[ $DOORWAYDE_SHELL_INIT -ne 1 ]] && eval "$(doorwayde-shell init)"
notify-send -a "Deprecation Notice" "systemupdate is deprecated. Please use doorwayde-shell system.update instead." -i dialog-information
"${LIB_DIR}/doorwayde/system.update.sh" "$@"

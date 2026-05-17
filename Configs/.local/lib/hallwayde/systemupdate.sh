#!/usr/bin/env bash
[[ $HALLWAYDE_SHELL_INIT -ne 1 ]] && eval "$(hallwayde-shell init)"
notify-send -a "Deprecation Notice" "systemupdate is deprecated. Please use hallwayde-shell system.update instead." -i dialog-information
"${LIB_DIR}/hallwayde/system.update.sh" "$@"

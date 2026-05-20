#!/usr/bin/env bash
[[ $DOORWAYDE_SHELL_INIT -ne 1 ]] && eval "$(doorwayde-shell init)"

notify-send -a "Deprecation Notice" "doorwayde-launch.sh is deprecated. Please use doorwayde-shell open instead." -i dialog-information

"${LIB_DIR}/doorwayde/open.sh" "$@"

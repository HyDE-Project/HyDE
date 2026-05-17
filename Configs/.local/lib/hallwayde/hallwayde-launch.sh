#!/usr/bin/env bash
[[ $HALLWAYDE_SHELL_INIT -ne 1 ]] && eval "$(hallwayde-shell init)"

notify-send -a "Deprecation Notice" "hallwayde-launch.sh is deprecated. Please use hallwayde-shell open instead." -i dialog-information

"${LIB_DIR}/hallwayde/open.sh" "$@"

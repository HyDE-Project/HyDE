#!/usr/bin/env bash
[[ $HALLWAYDE_SHELL_INIT -ne 1 ]] && eval "$(hallwayde-shell init)"
notify-send -a "Deprecation Notice" "sysmonitor.sh is deprecated. Please use hallwayde-shell system.monitor open instead." -i dialog-information

"${LIB_DIR}/hallwayde/system.monitor.sh" "$@"

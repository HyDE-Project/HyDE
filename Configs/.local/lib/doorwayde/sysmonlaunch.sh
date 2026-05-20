#!/usr/bin/env bash
[[ $DOORWAYDE_SHELL_INIT -ne 1 ]] && eval "$(doorwayde-shell init)"
notify-send -a "Deprecation Notice" "sysmonitor.sh is deprecated. Please use doorwayde-shell system.monitor open instead." -i dialog-information

"${LIB_DIR}/doorwayde/system.monitor.sh" "$@"

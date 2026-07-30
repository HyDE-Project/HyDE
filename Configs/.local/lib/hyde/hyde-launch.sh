#!/usr/bin/env bash
[[ $HYDE_SHELL_INIT -ne 1 ]] && eval "$(hyde-shell init)"

notify-send -a "Deprecation Notice" "hyde-launch.sh is deprecated. Please use hyde-shell open instead." -i dialog-information

hyde-shell open "$@"

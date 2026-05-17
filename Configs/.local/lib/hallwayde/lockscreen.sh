#!/usr/bin/env bash
[[ $HALLWAYDE_SHELL_INIT -ne 1 ]] && eval "$(hallwayde-shell init)"
lockscreen="${HYPRLAND_LOCKSCREEN:-hyprlock}"
lockscreen="${LOCKSCREEN:-$lockscreen}"
lockscreen="${HALLWAYDE_LOCKSCREEN:-$lockscreen}"
source "${LIB_DIR}/hallwayde/shutils/argparse.sh"
argparse_init "$@"
argparse_program "hallwayde-shell lockscreen"
argparse_header "HALLwayDE Lockscreen Launcher"
argparse "--get" "" "Get the current lockscreen command"
argparse_finalize

case $ARGPARSE_ACTION in
    get) echo "$lockscreen" && exit 0 ;;
esac

unit_name="hallwayde-lockscreen.service"
args=(-u "$unit_name" -t service)
if which "$lockscreen.sh" 2> /dev/null 1>&2; then
    printf "Executing $lockscreen wrapper script : %s\n" "$lockscreen.sh"
    app2unit.sh "${args[@]}" -- "$lockscreen.sh" "$@"
else
    printf "Executing raw command: %s\n" "$lockscreen"
    app2unit.sh "${args[@]}" -- "$lockscreen" "$@"
fi

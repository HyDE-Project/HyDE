#!/usr/bin/env bash
<<<<<<< HEAD

[[ "${HYDE_SHELL_INIT}" -ne 1 ]] && eval "$(hyde-shell init)"

lockscreen="${HYPRLAND_LOCKSCREEN:-$lockscreen}"
lockscreen="${LOCKSCREEN:-hyprlock}"
lockscreen="${HYDE_LOCKSCREEN:-$lockscreen}"

case ${1} in
    --get)
        echo "${lockscreen}"
        exit 0
        ;;    
esac

#? To cleanly exit hyprlock we should use a systemd scope unit.
#? This allows us to manage the lockscreen process more effectively.
#? This fix the zombie process issue when hyprlock is unlocked but still running.
unit_id=(-u "hyde-lockscreen.scope")

if which "${lockscreen}.sh" 2>/dev/null 1>&2; then
    printf "Executing ${lockscreen} wrapper script : %s\n" "${lockscreen}.sh"
    app2unit.sh  "${unit_id[@]}"  -- "${lockscreen}.sh" "${@}"
else
    printf "Executing raw command: %s\n" "${lockscreen}"
    app2unit.sh "${unit_id[@]}" -- "${lockscreen}" "${@}"
=======
[[ $HYDE_SHELL_INIT -ne 1 ]] && eval "$(hyde-shell init)"
lockscreen="${HYPRLAND_LOCKSCREEN:-hyprlock}"
lockscreen="${LOCKSCREEN:-$lockscreen}"
lockscreen="${HYDE_LOCKSCREEN:-$lockscreen}"
source "${LIB_DIR}/hyde/shutils/argparse.sh"
argparse_init "$@"
argparse_program "hyde-shell lockscreen"
argparse_header "HyDE Lockscreen Launcher"
argparse "--get" "" "Get the current lockscreen command"
argparse_finalize

case $ARGPARSE_ACTION in
    get) echo "$lockscreen" && exit 0 ;;
esac

unit_name="hyde-lockscreen.service"
args=(-u "$unit_name" -t service)
if which "$lockscreen.sh" 2> /dev/null 1>&2; then
    printf "Executing $lockscreen wrapper script : %s\n" "$lockscreen.sh"
    app2unit.sh "${args[@]}" -- "$lockscreen.sh" "$@"
else
    printf "Executing raw command: %s\n" "$lockscreen"
    app2unit.sh "${args[@]}" -- "$lockscreen" "$@"
>>>>>>> master
fi

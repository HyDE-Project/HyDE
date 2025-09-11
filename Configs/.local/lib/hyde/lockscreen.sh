#!/usr/bin/env bash

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
fi

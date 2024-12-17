#!/bin/env bash

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"
pkgChk=("io.missioncenter.MissionCenter" "htop" "btop" "top")
pkgChk+=("${SYSMONITOR_COMMANDS[@]}")

executable="${SYSMONITOR_EXECUTE:-${pkgChk[sysMon]}}"

exec_cmd() {

    if pkg_installed "${executable}"; then
        if command -v "$term" >/dev/null; then
            hyprctl dispatch exec "[ float ] ${term} ${executable}" &
        else
            hyprctl dispatch exec "[ float ] ${executable}" &
        fi
    fi

}

for sysMon in "${!pkgChk[@]}"; do
    term=$(grep -E '^\s*'"$term" "$HOME/.config/hypr/keybindings.conf" | cut -d '=' -f2 | xargs) # dumb search the config
    term=${TERMINAL:-$term}                                                                      # Use env var
    term=${SYSMONITOR_TERMINAL:-$term}                                                           # use the declared variable
    pkill -x "${executable}" || exec_cmd "${executable}"
    break
done

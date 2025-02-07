#!/usr/bin/env bash

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"
pkgChk=(${UTILS_SYSTEM_MONITOR:-"io.missioncenter.MissionCenter" "htop" "btop" "top"})
pkgChk+=("${SYSMONITOR_COMMANDS[@]}")

for sysMon in "${!pkgChk[@]}"; do
  if [ "${sysMon}" != "io.missioncenter.MissionCenter" ]; then
    term=$(grep -E '^\s*'"$term" "$HOME/.config/hypr/keybindings.conf" | cut -d '=' -f2 | xargs) # dumb search the config
    term=${TERMINAL:-$term}                                                                      # Use env var
    term=${SYSMONITOR_TERMINAL:-$term}                                                           # use the declared variable
  fi

  if pkg_installed "${pkgChk[sysMon]}"; then
    pkill -x "${pkgChk[sysMon]}" || ${term} "${pkgChk[sysMon]}" &
    break
  fi
done

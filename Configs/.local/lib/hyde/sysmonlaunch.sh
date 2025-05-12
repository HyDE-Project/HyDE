#!/usr/bin/env bash

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"

show_help() {
  cat <<HELP
Usage: $(basename "$0") --[option] 
    -h, --help  Display this help and exit
    -e, --execute   Explicit command to execute

Config: ~/.config/hyde/config.toml
    
    [sysmonitor]
    execute = "btop"                    # Default command to execute // accepts executable or app.desktop
    commands = ["btop", "htop", "top"]  # Fallback command options
    terminal = "kitty"                  # Explicit terminal // uses \$TERMINAL if available


This script launches the system monitor application. 
    It will launch the first available system monitor 
    application from the list of 'commands' provided.


HELP
}

case $1 in
-h | --help)
  show_help
  exit 0
  ;;
-e | --execute)
  shift
  SYSMONITOR_EXECUTE=$1
  ;;
-*)
  echo "Unknown option: $1" >&2
  exit 1
  ;;
esac

pidFile="$HYDE_RUNTIME_DIR/sysmonlaunch.pid"

# TODO: As there is no proper protocol at terminals, we need to find a way to kill the processes
# * This enables toggling the sysmonitor on and off
if [ -f "$pidFile" ]; then
  while IFS= read -r line; do
    pid=$(awk -F ':::' '{print $1}' <<<"$line")
    if [ -d "/proc/${pid}" ]; then
      cmd=$(awk -F ':::' '{print $2}' <<<"$line")
      pkill -P "$pid"
      pkg_installed flatpak && flatpak kill "$cmd" 2>/dev/null
      rm "$pidFile"
      exit 0
    fi
  done <"$pidFile"
  rm "$pidFile"
fi

pkgChk=("io.missioncenter.MissionCenter" "htop" "btop" "top")                     # Array of commands to check
pkgChk+=("${SYSMONITOR_COMMANDS[@]}")                                             # Add the user defined array commands
[ -n "${SYSMONITOR_EXECUTE}" ] && pkgChk=("${SYSMONITOR_EXECUTE}" "${pkgChk[@]}") # Add the user defined executable

for sysMon in "${!pkgChk[@]}"; do
  if gtk-launch "${pkgChk[sysMon]}"; then
    pid=$(pgrep -n -f "${pkgChk[sysMon]}")
    echo "${pid}:::${pkgChk[sysMon]}" >"$pidFile" # Save the PID to the file
    break
  fi
  if pkg_installed "${pkgChk[sysMon]}"; then
    term=$(grep -E '^\s*'"$term" "$HOME/.config/hypr/keybindings.conf" | cut -d '=' -f2 | xargs) # dumb search the config
    term=${TERMINAL:-$term}                                                                      # Use env var
    term=${SYSMONITOR_TERMINAL:-$term}
    if ${term} "${pkgChk[sysMon]}"; then
      pid="${!}"
      echo "${pid}:::${pkgChk[sysMon]}" >"$pidFile" # Save the PID to the file
      disown
      break
    fi
  fi
done

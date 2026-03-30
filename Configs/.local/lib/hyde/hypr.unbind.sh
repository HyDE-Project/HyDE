#!/usr/bin/env bash
<<<<<<< HEAD

scrDir="$(dirname "$(realpath "$0")")"
source "${scrDir}/globalcontrol.sh"

# Generate the unbind config
"${scrDir}/keybinds.hint.py" --show-unbind >"$HYDE_STATE_HOME/unbind.conf"
# hyprctl -q keyword source "$HYDE_STATE_HOME/unbind.conf"
=======
scrDir="$(dirname "$(realpath "$0")")"
source "$scrDir/globalcontrol.sh"
"$scrDir/keybinds.hint.py" --show-unbind > "$HYDE_STATE_HOME/unbind.conf"
>>>>>>> master

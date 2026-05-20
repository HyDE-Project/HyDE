#!/usr/bin/env bash
scrDir="$(dirname "$(realpath "$0")")"
source "$scrDir/globalcontrol.sh"
"$scrDir/keybinds.hint.py" --show-unbind > "$DOORWAYDE_STATE_HOME/unbind.conf"

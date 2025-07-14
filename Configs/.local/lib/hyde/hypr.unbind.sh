#!/usr/bin/env bash

[[ "${HYDE_SHELL_INIT}" -ne 1 ]] && eval "$(hyde-shell init)"

# Generate the unbind config
"${LIB_DIR}/hyde/keybinds.hint.py" --show-unbind >"$HYDE_STATE_HOME/unbind.conf"
# hyprctl -q keyword source "$HYDE_STATE_HOME/unbind.conf"

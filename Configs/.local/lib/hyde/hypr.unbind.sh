#!/bin/env bash

scrDir="$(dirname "$(realpath "$0")")"
source "${scrDir}/globalcontrol.sh"
unbindConf="$HYDE_STATE_HOME/unbind.conf"
tempFile="$HYDE_RUNTIME_DIR/unbind.conf"
hyprctl keyword misc:disable_autoreload 1 -q
trap 'hyprctl keyword misc:disable_autoreload 0 -q' EXIT

# Generate the unbind config
content="$("${scrDir}/keybinds.hint.py" --show-unbind)"

echo "Unbind content:"
echo "${content}"
if echo "${content}" | grep -q "Error parsing JSON"; then
    echo "Error detected in JSON content, exiting"
    exit 1
fi

echo "${content}" >"${tempFile}"

if cmp -s "${unbindConf}" "${tempFile}"; then
    echo "No changes detected, skipping unbind"
else
    echo "Changes detected, applying unbind"
    mv "${tempFile}" "${unbindConf}"
fi

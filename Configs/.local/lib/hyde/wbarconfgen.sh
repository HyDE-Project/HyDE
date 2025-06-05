#!/usr/bin/env bash

# read control file and initialize variables

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"
# shellcheck disable=SC2154

echo "DEPRECATION: The $0 will be removed in the future."
if [ -z "${1}" ]; then
    "${scrDir}/waybar.py" --update
else
    "${scrDir}/waybar.py" --update "-${1}"
fi

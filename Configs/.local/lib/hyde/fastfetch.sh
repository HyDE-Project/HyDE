#!/bin/env bash

if [ -z "${*}" ]; then
  clear
  fastfetch
  exit
fi

confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
iconDir="${XDG_DATA_HOME:-$HOME/.local/share}/icons"

if [ -z "${*}" ]; then
  clear
  fastfetch
  exit
fi

confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
iconDir="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
image_dirs=()

image_dirs=(
  "${confDir}/fastfetch/logo"
  "${iconDir}/Wallbash-Icon/fastfetch/"
)

# shellcheck source=/dev/null
[ -f "${confDir}/hyde/hyderc" ] && source "${confDir}/hyde/hyderc"
# shellcheck disable=SC1091
[ -f "/etc/os-release" ] && source "/etc/os-release"

if [ -n "${hydeTheme}" ] && [ -d "${confDir}/hyde/themes/${hydeTheme}" ]; then
  image_dirs+=("${confDir}/hyde/themes/${hydeTheme}")
fi

hyde_distro_logo=${iconDir}/Wallbash-Icon/distro/$LOGO
(
  [ -f "$hyde_distro_logo" ] && echo "${hyde_distro_logo}"
  find "${image_dirs[@]}" \( -name "*.icon" -o -name "*logo*" \) 2>/dev/null
) | shuf -n 1

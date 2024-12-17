#!/bin/env bash

can_render_images() {
  case "$TERM" in
  xterm*)
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

# if can_render_images; then
# echo "This terminal can render images."
# else
# echo "This terminal cannot render images."
# fi
# exit 0

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
[ -f "$HYDE_STATE_HOME/staterc" ] && source "$HYDE_STATE_HOME/staterc"
# shellcheck disable=SC1091
[ -f "/etc/os-release" ] && source "/etc/os-release"

if [ -n "${HYDE_THEME}" ] && [ -d "${confDir}/hyde/themes/${HYDE_THEME}" ]; then
  image_dirs+=("${confDir}/hyde/themes/${HYDE_THEME}")
fi

hyde_distro_logo=${iconDir}/Wallbash-Icon/distro/$LOGO
(
  [ -f "$hyde_distro_logo" ] && echo "${hyde_distro_logo}"
  find "${image_dirs[@]}" \( -name "*.icon" -o -name "*logo*" \) 2>/dev/null
) | shuf -n 1

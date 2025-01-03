#!/bin/env bash

# Early load to maintain fastfetch speed
if [ -z "${*}" ]; then
  clear
  fastfetch --logo-type kitty
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

hyde_distro_logo=${iconDir}/Wallbash-Icon/distro/$LOGO
case $1 in
logo) # eats around 13 ms
  random() {
    (
      if [ -n "${HYDE_THEME}" ] && [ -d "${confDir}/hyde/themes/${HYDE_THEME}/logo" ]; then
        image_dirs+=("${confDir}/hyde/themes/${HYDE_THEME}")
      fi
      [ -d "$HYDE_CACHE_HOME" ] && image_dirs+=("$HYDE_CACHE_HOME")
      [ -f "$hyde_distro_logo" ] && echo "${hyde_distro_logo}"
      [ -f "$HOME/.face.icon" ] && echo "$HOME/.face.icon"

      find -L "${image_dirs[@]}" -maxdepth 1 -type f \( -name "wall.quad" -o -name "wall.sqre" -o -name "*.icon" -o -name "*logo*" -o -name "*.png" \) ! -path "*/wall.set*" ! -path "*/wallpapers/*.png" 2>/dev/null
    ) | shuf -n 1
  }
  help() {
    cat <<HELP
    Usage: ${0##*/} logo [option]

options:
  --quad  Display a quad wallpaper logo
  --sqre  Display a square wallpaper logo
  --prof  Display your profile picture (~/.face.icon)
  --rand  Display a random logo
  *       Display a random logo
  *help*  Display this help message
HELP
  }

  shift
  [ -z "${*}" ] && random && exit
  [[ "$1" = *"help"* ]] && help && exit
  (
    for arg in "$@"; do
      case $arg in
      --quad)
        echo "$HYDE_CACHE_HOME/wall.quad"
        ;;
      --sqre)
        echo "$HYDE_CACHE_HOME/wall.sqre"
        ;;
      --prof)
        [ -f "$HOME/.face.icon" ] && echo "$HOME/.face.icon"
        ;;
      --rand)
        random
        ;;
      esac
    done
  ) | shuf -n 1

  ;;
help)
  cat <<EOF
Usage: fastfetch [commands] [options]

commands:
  logo  Display a random logo
  help  Display this help message

options:
  --help Display command's help message

EOF
  ;;
*)
  clear
  fastfetch --logo-type kitty
  ;;
esac

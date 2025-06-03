#!/usr/bin/env bash

# Early load to maintain fastfetch speed
if [ -z "${*}" ]; then
  clear
  exec fastfetch --logo-type kitty
  exit
fi

USAGE() {
  cat <<USAGE
Usage: fastfetch [commands] [options]

commands:
  logo    Display a random logo

options:
  -h, --help,     Display command's help message

USAGE
}

# Source state and os-release
# shellcheck source=/dev/null
[ -f "$HYDE_STATE_HOME/staterc" ] && source "$HYDE_STATE_HOME/staterc"
# shellcheck disable=SC1091
[ -f "/etc/os-release" ] && source "/etc/os-release"

# Set the variables
confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
iconDir="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
image_dirs=()
hyde_distro_logo=${iconDir}/Wallbash-Icon/distro/$LOGO

# Parse the main command
case $1 in
logo) # eats around 13 ms
  random() {
    (
      image_dirs+=("${confDir}/fastfetch/logo")
      image_dirs+=("${iconDir}/Wallbash-Icon/fastfetch/")
      if [ -n "${HYDE_THEME}" ] && [ -d "${confDir}/hyde/themes/${HYDE_THEME}/logo" ]; then
        image_dirs+=("${confDir}/hyde/themes/${HYDE_THEME}/logo")
      fi
      # [ -d "$HYDE_CACHE_HOME" ] && image_dirs+=("$HYDE_CACHE_HOME")
      [ -f "$hyde_distro_logo" ] && echo "${hyde_distro_logo}"
      image_dirs+=("$HYDE_CACHE_HOME/wall.quad")
      image_dirs+=("$HYDE_CACHE_HOME/wall.sqre")
      [ -f "$HOME/.face.icon" ] && image_dirs+=("$HOME/.face.icon")
      # also .bash_logout may be matched with this find
      find -L "${image_dirs[@]}" -maxdepth 1 -type f \( -name "wall.quad" -o -name "wall.sqre" -o -name "*.icon" -o -name "*logo*" -o -name "*.png" \) ! -path "*/wall.set*" ! -path "*/wallpapers/*.png" 2>/dev/null
    ) | shuf -n 1
  }
  help() {
    cat <<HELP
Usage: ${0##*/} logo [option]

options:
  --quad    Display a quad wallpaper logo
  --sqre    Display a square wallpaper logo
  --prof    Display your profile picture (~/.face.icon)
  --os      Display the distro logo
  --local   Display a logo inside the fastfetch logo directory
  --wall    Display a logo inside the wallbash fastfetch directory
  --theme   Display a logo inside the hyde theme directory
  --rand    Display a random logo
  *         Display a random logo
  *help*    Display this help message

Note: Options can be combined to search across multiple sources
Example: ${0##*/} logo --local --os --prof
HELP
  }

  # Parse the logo options
  shift
  [ -z "${*}" ] && random && exit
  [[ "$1" = "--rand" ]] && random && exit
  [[ "$1" = *"help"* ]] && help && exit
  (
    image_dirs=()
    for arg in "$@"; do
      case $arg in
      --quad)
        image_dirs+=("$HYDE_CACHE_HOME/wall.quad")
        ;;
      --sqre)
        image_dirs+=("$HYDE_CACHE_HOME/wall.sqre")
        ;;
      --prof)
        [ -f "$HOME/.face.icon" ] && image_dirs+=("$HOME/.face.icon")
        ;;
      --os)
        [ -f "$hyde_distro_logo" ] && image_dirs+=("$hyde_distro_logo")
        ;;
      --local)
        image_dirs+=("${confDir}/fastfetch/logo")
        ;;
      --wall)
        image_dirs+=("${iconDir}/Wallbash-Icon/fastfetch/")
        ;;
      --theme)
        if [ -n "${HYDE_THEME}" ] && [ -d "${confDir}/hyde/themes/${HYDE_THEME}/logo" ]; then
          image_dirs+=("${confDir}/hyde/themes/${HYDE_THEME}/logo")
        fi
        ;;
      esac
    done
    find -L "${image_dirs[@]}" -maxdepth 1 -type f \( -name "wall.quad" -o -name "wall.sqre" -o -name "*.icon" -o -name "*logo*" -o -name "*.png" \) ! -path "*/wall.set*" ! -path "*/wallpapers/*.png" 2>/dev/null
  ) | shuf -n 1

  ;;
--select | -S)
  :

  ;;
help | --help | -h)
  USAGE
  ;;
*)
  clear
  exec fastfetch --logo-type kitty
  ;;
esac

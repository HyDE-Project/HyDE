#!/usr/bin/env bash
if [ -z "$*" ]; then
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
[ -f "$HYDE_STATE_HOME/staterc" ] && source "$HYDE_STATE_HOME/staterc"
[ -f "/etc/os-release" ] && source "/etc/os-release"
confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
iconDir="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
cacheDir="${XDG_CACHE_HOME:-$HOME/.cache}/hyde"
image_dirs=()
hyde_distro_logo=$iconDir/Wallbash-Icon/distro/$LOGO
case $1 in
logo)
    random() {
        (
            image_dirs+=("$confDir/fastfetch/logo")
            image_dirs+=("$iconDir/Wallbash-Icon/fastfetch/")
            if [ -n "$HYDE_THEME" ] && [ -d "$confDir/hyde/themes/$HYDE_THEME/logo" ]; then
                image_dirs+=("$confDir/hyde/themes/$HYDE_THEME/logo")
            fi
            [ -f "$hyde_distro_logo" ] && echo "$hyde_distro_logo"
            image_dirs+=("$cacheDir/wall.quad")
            image_dirs+=("$cacheDir/wall.sqre")
            [ -f "$HOME/.face.icon" ] && image_dirs+=("$HOME/.face.icon")
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
    shift
    [ -z "$*" ] && random && exit
    [[ $1 == "--rand" ]] && random && exit
    [[ $1 == *"help"* ]] && help && exit
    (
        image_dirs=()
        for arg in "$@"; do
            case $arg in
            --quad)
                image_dirs+=("$cacheDir/wall.quad")
                ;;
            --sqre)
                image_dirs+=("$cacheDir/wall.sqre")
                ;;
            --prof)
                [ -f "$HOME/.face.icon" ] && image_dirs+=("$HOME/.face.icon")
                ;;
            --os)
                [ -f "$hyde_distro_logo" ] && image_dirs+=("$hyde_distro_logo")
                ;;
            --local)
                image_dirs+=("$confDir/fastfetch/logo")
                ;;
            --wall)
                image_dirs+=("$iconDir/Wallbash-Icon/fastfetch/")
                ;;
            --theme) if
                [ -n "$HYDE_THEME" ] && [ -d "$confDir/hyde/themes/$HYDE_THEME/logo" ]
            then
                image_dirs+=("$confDir/hyde/themes/$HYDE_THEME/logo")
            fi ;;
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

#!/bin/bash
# Rofi menu for Quick Edit / View of Settings (SUPER E)

# define your preferred text editor and terminal to use
editor=${EDITOR:-nvim}
tty=kitty

scriptDir="$HOME/.config/hypr/scripts"
UserConfigs="$HOME/.config/hypr"
QSDir="$HOME/.local/share/bin/custom"
SDDMDir="/usr/share/sddm/themes/sequoia"

menu(){
  printf "0. edit Quick Edit\n"
  printf "1. edit Animation Config\n"
  printf "2. edit Hyprland Config\n"
  printf "3. edit User-Keybinds\n"
  printf "4. edit Monitors\n"
  printf "5. edit Userprefs\n"
  printf "6. edit Window Rules\n"
  printf "7. edit Pyprland Config\n" 
  printf "8. edit SDDM Config\n" 
}

main() {
    choice=$(menu | rofi -i -dmenu -config ~/.local/share/rofi/themes/clipboard.rasi | cut -d. -f1)
    case $choice in
        0)  $tty $editor "$QSDir/QuickEdit.sh"
	    ;;	    
        1)
            $tty $editor "$UserConfigs/animations.conf"
            ;;
        2)
            $tty $editor "$UserConfigs/hyprland.conf"
            ;;
        3)
            $tty $editor "$UserConfigs/keybindings.conf"
            ;;
        4)
            $tty $editor "$UserConfigs/monitors.conf"
            ;;
        5)
            $tty $editor "$UserConfigs/userprefs.conf"
            ;;
        6)
            $tty $editor "$UserConfigs/windowsrules.conf"
            ;;
      	7)
	          $tty $editor "$UserConfigs/pyprland.toml"
	          ;;
      	8)
	          $tty $editor "$SDDMDir/theme.conf"
	          ;;
        *)
            ;;
    esac
}

main

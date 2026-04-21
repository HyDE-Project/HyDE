# NOTE: This script is now deprecated as hyprland no longer fully kills steam!
# You shouldn't need to use it in any of your keybindings!

if [[ $(hyprctl activewindow -j | jq -r ".class") == "Steam" ]]; then
    xdotool windowunmap $(xdotool getactivewindow)
else
    hyprctl dispatch killactive ""
fi

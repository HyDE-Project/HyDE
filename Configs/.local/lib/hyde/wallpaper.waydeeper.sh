#!/usr/bin/env bash

selected_wall="${1:-"$HYDE_CACHE_HOME/wall.set"}"
lockFile="$XDG_RUNTIME_DIR/hyde/$(basename "$0").lock"
if [ -e "$lockFile" ]; then
    cat << EOF

Error: Another instance of $(basename "$0") is running.
If you are sure that no other instance is running, remove the lock file:
    $lockFile
EOF
    exit 1
fi
touch "$lockFile"
trap 'rm -f "${lockFile}"' EXIT
scrDir="$(dirname "$(realpath "$0")")"
source "$scrDir/globalcontrol.sh"

selected_wall="$1"
[ -z "$selected_wall" ] && echo "No input wallpaper" && exit 1
selected_wall="$(readlink -f "$selected_wall")"

is_video=$(file --mime-type -b "$selected_wall" | grep -c '^video/')
if [ "$is_video" -eq 1 ]; then
    print_log -sec "wallpaper" -stat "converting video" "$selected_wall"
    mkdir -p "$HYDE_CACHE_HOME/wallpapers/thumbnails"
    cached_thumb="$HYDE_CACHE_HOME/wallpapers/$(${hashMech:-sha1sum} "$selected_wall" | cut -d' ' -f1).png"
    extract_thumbnail "$selected_wall" "$cached_thumb"
    selected_wall="$cached_thumb"
fi

# Ensure waydeeper is installed
if ! command -v waydeeper &>/dev/null; then
    print_log -err "waydeeper not found"
    notify-send -a "HyDE Alert" "ERROR: waydeeper is not installed"
    exit 1
fi

# Ensure the inpaint model is downloaded
if [ ! -d "$XDG_DATA_HOME/waydeeper/models/inpaint" ] && [ ! -d "$HOME/.local/share/waydeeper/models/inpaint" ]; then
    print_log -sec "wallpaper" -stat "downloading inpaint model"
    waydeeper download-model inpaint
fi

# Build waydeeper command with --inpaint always enabled
waydeeper_cmd="waydeeper set"
waydeeper_args="\"$selected_wall\" --inpaint"

# Add strength settings if configured
[ -n "$WALLPAPER_WAYDEEPER_STRENGTH" ] && waydeeper_args="$waydeeper_args --strength $WALLPAPER_WAYDEEPER_STRENGTH"
[ -n "$WALLPAPER_WAYDEEPER_STRENGTH_X" ] && waydeeper_args="$waydeeper_args --strength-x $WALLPAPER_WAYDEEPER_STRENGTH_X"
[ -n "$WALLPAPER_WAYDEEPER_STRENGTH_Y" ] && waydeeper_args="$waydeeper_args --strength-y $WALLPAPER_WAYDEEPER_STRENGTH_Y"

# Add animation settings if configured
[ -n "$WALLPAPER_WAYDEEPER_ANIMATION_SPEED" ] && waydeeper_args="$waydeeper_args --animation-speed $WALLPAPER_WAYDEEPER_ANIMATION_SPEED"
[ -n "$WALLPAPER_WAYDEEPER_FPS" ] && waydeeper_args="$waydeeper_args --fps $WALLPAPER_WAYDEEPER_FPS"
[ -n "$WALLPAPER_WAYDEEPER_ACTIVE_DELAY" ] && waydeeper_args="$waydeeper_args --active-delay $WALLPAPER_WAYDEEPER_ACTIVE_DELAY"
[ -n "$WALLPAPER_WAYDEEPER_IDLE_TIMEOUT" ] && waydeeper_args="$waydeeper_args --idle-timeout $WALLPAPER_WAYDEEPER_IDLE_TIMEOUT"

# Add depth model if configured
[ -n "$WALLPAPER_WAYDEEPER_MODEL" ] && waydeeper_args="$waydeeper_args --model $WALLPAPER_WAYDEEPER_MODEL"

# Add smooth animation toggle (default: enabled)
if [ "$WALLPAPER_WAYDEEPER_SMOOTH_ANIMATION" = "false" ]; then
    waydeeper_args="$waydeeper_args --smooth-animation=false"
fi

# Add invert depth if configured
[ "$WALLPAPER_WAYDEEPER_INVERT_DEPTH" = "true" ] && waydeeper_args="$waydeeper_args --invert-depth"

# Add regenerate flag if configured
[ "$WALLPAPER_WAYDEEPER_REGENERATE" = "true" ] && waydeeper_args="$waydeeper_args --regenerate"

# Set wallpaper on all monitors (waydeeper handles multi-monitor by default)
print_log -sec "wallpaper" -stat "apply" "$selected_wall"
eval "$waydeeper_cmd $waydeeper_args" &

# Start daemon if not already running
if ! pgrep -f "waydeeper daemon" &>/dev/null; then
    print_log -sec "wallpaper" -stat "starting waydeeper daemon"
    waydeeper daemon &
    disown
fi

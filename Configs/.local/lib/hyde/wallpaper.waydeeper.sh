#!/usr/bin/env bash

scrDir="$(dirname "$(realpath "$0")")"
source "$scrDir/globalcontrol.sh"

lockDir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hyde"
mkdir -p "$lockDir"
lockFile="$lockDir/$(basename "$0").lock"

if ! ( set -o noclobber; : > "$lockFile" ) 2>/dev/null; then
    cat << EOF

Error: Another instance of $(basename "$0") is running.
If you are sure that no other instance is running, remove the lock file:
    $lockFile
EOF
    exit 1
fi
touch "$lockFile"
trap 'rm -f "${lockFile}"' EXIT

selected_wall="${1:-"$HYDE_CACHE_HOME/wall.set"}"
selected_wall="$(readlink -f "$selected_wall")"

is_video=$(file --mime-type -b "$selected_wall" | grep -c '^video/')
if [ "$is_video" -eq 1 ]; then
    print_log -sec "wallpaper" -stat "converting video" "$selected_wall"
    cached_thumb="$HYDE_CACHE_HOME/wallpapers/$(${hashMech:-sha1sum} "$selected_wall" | cut -d' ' -f1).png"
    extract_thumbnail "$selected_wall" "$cached_thumb"
    if [ ! -f "$cached_thumb" ]; then
        print_log -err "failed to extract thumbnail from" "$selected_wall"
        notify-send -a "HyDE Alert" "ERROR: failed to extract thumbnail from video"
        exit 1
    fi
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
    if ! waydeeper download-model inpaint; then
        print_log -err "failed to download waydeeper inpaint model"
        notify-send -a "HyDE Alert" "ERROR: failed to download waydeeper inpaint model"
        exit 1
    fi
fi

# Build waydeeper command with --inpaint always enabled
waydeeper_args=(waydeeper set "$selected_wall" --inpaint)

# Add depth model if configured
if [ -n "$WALLPAPER_WAYDEEPER_MODEL" ]; then
    waydeeper_args+=(--model "$WALLPAPER_WAYDEEPER_MODEL")
    # Ensure selected model is downloaded
    if [ ! -f "$XDG_DATA_HOME/waydeeper/models/$WALLPAPER_WAYDEEPER_MODEL.onnx" ] && [ ! -f "$HOME/.local/share/waydeeper/models/$WALLPAPER_WAYDEEPER_MODEL.onnx" ]; then
        print_log -sec "wallpaper" -stat "downloading $WALLPAPER_WAYDEEPER_MODEL model"
        if ! waydeeper download-model $WALLPAPER_WAYDEEPER_MODEL; then
            print_log -err "failed to download waydeeper $WALLPAPER_WAYDEEPER_MODEL model"
            notify-send -a "HyDE Alert" "ERROR: failed to download waydeeper $WALLPAPER_WAYDEEPER_MODEL model"
            exit 1
        fi
    fi
fi

# Add strength settings if configured
if [ -n "$WALLPAPER_WAYDEEPER_STRENGTH" ]; then
    waydeeper_args+=(--strength "$WALLPAPER_WAYDEEPER_STRENGTH")
fi
if [ -n "$WALLPAPER_WAYDEEPER_STRENGTH_X" ]; then
    waydeeper_args+=(--strength-x "$WALLPAPER_WAYDEEPER_STRENGTH_X")
fi
if [ -n "$WALLPAPER_WAYDEEPER_STRENGTH_Y" ]; then
    waydeeper_args+=(--strength-y "$WALLPAPER_WAYDEEPER_STRENGTH_Y")
fi

# Add animation settings if configured
if [ -n "$WALLPAPER_WAYDEEPER_ANIMATION_SPEED" ]; then
    waydeeper_args+=(--animation-speed "$WALLPAPER_WAYDEEPER_ANIMATION_SPEED")
fi
if [ -n "$WALLPAPER_WAYDEEPER_FPS" ]; then
    waydeeper_args+=(--fps "$WALLPAPER_WAYDEEPER_FPS")
fi
if [ -n "$WALLPAPER_WAYDEEPER_ACTIVE_DELAY" ]; then
    waydeeper_args+=(--active-delay "$WALLPAPER_WAYDEEPER_ACTIVE_DELAY")
fi
if [ -n "$WALLPAPER_WAYDEEPER_IDLE_TIMEOUT" ]; then
    waydeeper_args+=(--idle-timeout "$WALLPAPER_WAYDEEPER_IDLE_TIMEOUT")
fi

# Add smooth animation toggle (default: enabled)
if [ "$WALLPAPER_WAYDEEPER_SMOOTH_ANIMATION" = "false" ]; then
    waydeeper_args+=(--no-smooth-animation)
fi

# Add invert depth if configured
if [ "$WALLPAPER_WAYDEEPER_INVERT_DEPTH" = "true" ]; then
    waydeeper_args+=(--invert-depth)
fi

# Add regenerate flag if configured
if [ "$WALLPAPER_WAYDEEPER_REGENERATE" = "true" ]; then
    waydeeper_args+=(--regenerate)
fi

# Set wallpaper on all monitors (waydeeper handles multi-monitor by default)
print_log -sec "wallpaper" -stat "apply" "$selected_wall"
"${waydeeper_args[@]}" &

# Start daemon if not already running
if ! pgrep -f "waydeeper daemon" &>/dev/null; then
    print_log -sec "wallpaper" -stat "starting waydeeper daemon"
    waydeeper daemon &
    disown
fi

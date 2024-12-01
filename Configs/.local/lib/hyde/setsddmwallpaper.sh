#!/usr/bin/env sh

# Configuration
SDDM_THEME_CONFIG="/usr/share/sddm/themes/Corners/theme.conf"
BACKGROUND_DIR="/usr/share/sddm/themes/Corners/backgrounds"
WALLPAPER_NAME="customwallpaper"

# Log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1"
}

# Validate input
if [ -z "$1" ]; then
    log "ERROR: No wallpaper path provided."
    exit 1
fi

WALLPAPER_PATH="$1"
if [ ! -f "$WALLPAPER_PATH" ]; then
    log "ERROR: Wallpaper file does not exist: $WALLPAPER_PATH"
    exit 1
fi

# Update SDDM wallpaper
cp -f "$WALLPAPER_PATH" "$BACKGROUND_DIR/$WALLPAPER_NAME"
sed -i "s|^Background=.*|Background=\"backgrounds/$WALLPAPER_NAME\"|" "$SDDM_THEME_CONFIG"

log "SDDM wallpaper updated to: $BACKGROUND_DIR/$WALLPAPER_NAME"

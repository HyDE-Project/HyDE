#!/usr/bin/env sh

##################################################
### This will only work if using Corners theme ###
##################################################

# Check if the wallpaper path argument is provided
if [ -z "$1" ]; then
    echo "ERROR: No wallpaper path provided."
    exit 1
fi

WALLPAPER_PATH="$1"

# Ensure the wallpaper path is quoted to handle spaces
if [ ! -f "$WALLPAPER_PATH" ]; then
    echo "ERROR: Wallpaper file does not exist: $WALLPAPER_PATH"
    exit 1
fi

# Set the path to the theme configuration file
SDDM_THEME_CONFIG="/usr/share/sddm/themes/Corners/theme.conf"

# Set the background directory for SDDM theme
BACKGROUND_DIR="/usr/share/sddm/themes/Corners/backgrounds"

# Define the fixed name for the wallpaper
WALLPAPER_NAME="customwallpaper"

# Copy the wallpaper to the backgrounds directory with the fixed name
cp -f "$WALLPAPER_PATH" "$BACKGROUND_DIR/$WALLPAPER_NAME"

# Update the theme configuration file to point to the new background
sed -i "s|^Background=.*|Background=\"backgrounds/$WALLPAPER_NAME\"|" "$SDDM_THEME_CONFIG"

echo "SDDM wallpaper updated successfully to: backgrounds/$WALLPAPER_NAME"

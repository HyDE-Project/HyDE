#!/usr/bin/env sh

# Paths to "hyde" scripts
WALL_SCRIPT="$HOME/.local/share/bin/swwwallpaper.sh"
THEME_SCRIPT="$HOME/.local/share/bin/themeswitch.sh"

# Log file for debugging
LOG_FILE="$HOME/.local/share/cyclewallpaperandtheme.log"

# State tracking files
WALL_CYCLE_FILE="$HOME/.local/share/cyclewallpapercount"
THEME_CYCLE_FILE="$HOME/.local/share/cyclethemecount"
THEME_CHANGE_FLAG_FILE="$HOME/.local/share/cyclethemeflag"

# Directory where themes are stored
THEMES_DIR="$HOME/.config/hyde/themes"

# If it's time to change the theme
if [ -f "$THEME_CHANGE_FLAG_FILE" ]; then
    # Get the list of themes and cycle through them (ensure spaces in file names are treated correctly)
    themes=()
    while IFS= read -r theme; do
        themes+=("$theme")
    done < <(find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d | sort)
    themes=("${themes[@]##*/}")  # Strip path to get only names

    # Read or initialize the theme counter
    if [ ! -f "$THEME_CYCLE_FILE" ]; then
        echo 0 > "$THEME_CYCLE_FILE"
    fi
    theme_count=$(cat "$THEME_CYCLE_FILE")

    # Get the theme in the list and set it
    next_theme="${themes[$theme_count]}"
    "$THEME_SCRIPT" -s "$next_theme" >> "$LOG_FILE" 2>&1

    # Update the theme counter
    echo $((theme_count + 1)) > "$THEME_CYCLE_FILE"

    # Sleep for 3 seconds to ensure theme is totally changed and new variables are set
    sleep 3

    # Clear the theme change flag
    rm "$THEME_CHANGE_FLAG_FILE"
fi

# Extract the current theme from the config file
current_theme=$(grep -oP '(?<=^hydeTheme=").*(?=")' "$HOME/.config/hyde/hyde.conf")

if [ -z "$current_theme" ] || [ ! -d "$THEMES_DIR/$current_theme" ]; then
    echo "ERROR: Unable to determine current theme or theme directory does not exist" >> "$LOG_FILE"
    exit 1
fi

WALLPAPER_DIR="$THEMES_DIR/$current_theme/wallpapers"

# Check if the wallpaper directory exists
if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "ERROR: Wallpaper directory for theme '$current_theme' does not exist: $WALLPAPER_DIR" >> "$LOG_FILE"
    exit 1
fi

# Read or initialize the wallpaper counter
if [ ! -f "$WALL_CYCLE_FILE" ]; then
    echo 0 > "$WALL_CYCLE_FILE"
fi
wall_count=$(cat "$WALL_CYCLE_FILE")

# Get list of wallpapers and set it
wallpapers=("$WALLPAPER_DIR"/*)
"$WALL_SCRIPT" -s "${wallpapers[$wall_count]}" >> "$LOG_FILE" 2>&1
# Call the setsddmwallpaper script to update the login screen wallpaper
"$HOME/.local/share/bin/setsddmwallpaper.sh" "${wallpapers[$wall_count]}" >> "$LOG_FILE" 2>&1

# If all wallpapers have been cycled, set the flag to change the theme on the next run
if [ "$wall_count" -ge $(( ${#wallpapers[@]} - 1 )) ]; then
    echo "theme_change_needed" > "$THEME_CHANGE_FLAG_FILE"
    # Reset wallpaper counter for the next run
    echo 0 > "$WALL_CYCLE_FILE"
else
    # Increment wallpaper count and update the file
    wall_count=$((wall_count + 1))
    echo $wall_count > "$WALL_CYCLE_FILE"
fi

echo "Wallpaper and theme updated successfully." >> "$LOG_FILE"

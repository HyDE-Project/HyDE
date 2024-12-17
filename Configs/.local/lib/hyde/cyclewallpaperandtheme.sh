#! /bin/env bash

scrDir=$(dirname "$(realpath "$0")")
source "$scrDir/globalcontrol.sh"

# Paths to scripts and directories
WALL_SCRIPT="$scrDir/swwwallpaper.sh"
THEME_SCRIPT="$scrDir/themeswitch.sh"
#SDDM_SCRIPT="$HOME/bin/setsddmwallpaper"
SDDM_SCRIPT="$scrDir/setsddmwallpaper.sh"
LOG_FILE="$HOME/.cache/cyclewallpaperandtheme.log"
WALL_CYCLE_FILE="$HOME/.local/share/cyclewallpapercount"
THEME_CYCLE_FILE="$HOME/.local/share/cyclethemecount"
THEME_CHANGE_FLAG_FILE="$HOME/.local/share/cyclethemeflag"
THEMES_DIR="$hydeConfDir/themes"
HYDE_CONFIG="$hydeConfDir/hyde.conf"

# Log messages to file
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

# Safely read a counter file or initialize it
read_or_initialize_counter() {
    local file="$1"
    [ ! -f "$file" ] && echo 0 > "$file"
    cat "$file"
}

# Increment and save a counter
increment_counter() {
    local count="$1"
    local max="$2"
    local file="$3"
    echo $(( (count + 1) % max )) > "$file"
}

# Cycle to the next theme
cycle_theme() {
    # Get theme list
    themes=()
    while IFS= read -r theme; do
        themes+=("$theme")
    done < <(find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d | sort)
    themes=("${themes[@]##*/}")  # Strip path to get only names

    # Read and increment theme counter
    theme_count=$(read_or_initialize_counter "$THEME_CYCLE_FILE")
    next_theme="${themes[$theme_count]}"
    increment_counter "$theme_count" "${#themes[@]}" "$THEME_CYCLE_FILE"

    # Apply theme and wait for stability
    "$THEME_SCRIPT" -s "$next_theme" >> "$LOG_FILE" 2>&1
    log "Theme changed to: $next_theme"
    sleep 3
}

# Cycle to the next wallpaper
cycle_wallpaper() {
    # Determine current theme and wallpaper directory
    current_theme=$(grep '^hydeTheme=' "$HYDE_CONFIG" | sed -E 's/^hydeTheme="([^"]+)"/\1/')
    if [ -z "$current_theme" ]; then
        log "ERROR: Unable to determine current theme from $HYDE_CONFIG."
        exit 1
    fi

    wallpaper_dir="$THEMES_DIR/$current_theme/wallpapers"
    if [ ! -d "$wallpaper_dir" ]; then
        log "ERROR: Wallpaper directory for theme '$current_theme' does not exist: $wallpaper_dir"
        exit 1
    fi

    # Get wallpaper list
    wallpapers=("$wallpaper_dir"/*)
    total_wallpapers=${#wallpapers[@]}
    if [ "$total_wallpapers" -eq 0 ]; then
        log "ERROR: No wallpapers found in $wallpaper_dir"
        exit 1
    fi

    # Read and increment wallpaper counter
    wall_count=$(read_or_initialize_counter "$WALL_CYCLE_FILE")
    next_wallpaper="${wallpapers[$wall_count]}"
    increment_counter "$wall_count" "$total_wallpapers" "$WALL_CYCLE_FILE"

    # Set wallpaper
    "$WALL_SCRIPT" -s "$next_wallpaper" >> "$LOG_FILE" 2>&1
    "$SDDM_SCRIPT" "$next_wallpaper" >> "$LOG_FILE" 2>&1
    log "Wallpaper changed to: $next_wallpaper"

    # If all wallpapers are cycled, flag theme change
    if [ "$wall_count" -eq $((total_wallpapers - 1)) ]; then
        touch "$THEME_CHANGE_FLAG_FILE"
        echo 0 > "$WALL_CYCLE_FILE"
        log "Theme change flagged for next run."
    fi
}

# Main execution
if [ -f "$THEME_CHANGE_FLAG_FILE" ]; then
    cycle_theme
    rm -f "$THEME_CHANGE_FLAG_FILE"
fi

cycle_wallpaper
log "Cycle operation completed."

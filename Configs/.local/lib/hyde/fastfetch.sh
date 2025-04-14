#!/usr/bin/env bash

# Clear the screen for a fresh start
clear

# Function to find and display a random logo from the specific directory
random_logo() {
    # Define the directory to search for logos
    image_dirs="${confDir}/fastfetch/logo"

    # Find and randomize logos, display one
    find -L "${image_dirs}" -maxdepth 1 -type f \( -name "wall.quad" -o -name "wall.sqre" -o -name "*.icon" -o -name "*logo*" -o -name "*.png" \) 2>/dev/null | shuf -n 1
}

# Set the configuration directory
confDir="${XDG_CONFIG_HOME:-$HOME/.config}"

# Run the random logo function if no arguments are provided
random_logo
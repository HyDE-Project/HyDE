WAYBAR STYLES
=============

WHAT IS THIS DIRECTORY?
-----------------------
This directory contains style files for Waybar, a customizable status bar for Wayland compositors.

WHAT ARE STYLES?
----------------
Styles are CSS files that define the appearance of your Waybar, including colors, fonts, spacing, and other visual elements. You can create different styles for:
* Light and dark themes
* Specific monitor configurations
* Custom setups to match your desktop environment

HOW TO USE STYLES:
------------------
1. Style files (.css) in this directory can be selected using the `-s, --style` option:
   ```
   waybar -s /path/to/style.css
   ```
2. Alternatively, use the `--select, -S` option to select a layout and style pair:
   ```
   waybar --select
   ```
   Note: The selected layout (config/*.jsonc) and style (styles/*.css) should have the same name. If no matching style is found, Waybar will fallback to `default.css`.

GETTING STARTED WITH STYLES:
----------------------------
* View sample styles in: ~/.local/share/waybar/styles/
* Copy a sample to this directory and customize it to your needs
* For detailed configuration options, see: https://man.archlinux.org/man/waybar.5.en
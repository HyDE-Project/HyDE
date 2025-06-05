WAYBAR LAYOUTS
==============

WHAT IS THIS DIRECTORY?
-----------------------
This directory contains layout files for Waybar, a customizable status bar for Wayland compositors.

WHAT ARE LAYOUTS?
----------------
Layouts are configuration files that define how Waybar appears on your screen. You can create different layouts for:
* Multiple status bars
* Single status bar
* Specific monitor configurations
* And more custom setups

HOW TO USE LAYOUTS:
------------------
1. Layout files (.jsonc) in this directory can be selected using: waybar.py --select
2. When selected, a layout file is copied to ~/.config/waybar/config.jsonc to take effect
3. Each layout file should follow the Waybar config.jsonc format
4. Use the `--select, -S` option to select a layout and style pair:
   
   waybar --select
   
   Note: The selected layout (config/*.jsonc) and style (styles/*.css) should have the same name. If no matching style is found, Waybar will fallback to `default.css`.
5. Use the `-c, --config` option to specify the path to a custom config.jsonc file:
   
   waybar -c /path/to/config.jsonc

GETTING STARTED WITH LAYOUTS:
----------------------------
* View sample layouts in: ~/.local/share/waybar/layouts/
* Copy a sample to this directory and customize it to your needs
* For detailed configuration options, see: https://man.archlinux.org/man/waybar

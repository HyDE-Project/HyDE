# Changelog

All notable changes to `HyDE` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to _Modified_ [CalVer](https://calver.org/). See [Versioning](https://github.com/HyDE-Project/HyDE/blob/master/RELEASE_POLICY.md#versioning-yymq) For more info

## v25.8.3 (Unreleased)

### Fixed

- Typos,spelling and and cleanup
- Dunst: Fix dunst crashing when the font cannot handle unsupported characters -- Thanks to [#1131](https://github.com/HyDE-Project/HyDE/issues/1131)

### Changed

- Core: Move wallbash to ~/.local/share/wallbash
- wlogout: Add support for for uwsm

### Added

- hyde-shell: Add `logout` command to handle with/out uwsm


## v25.8.1

Big CHANGE in HyDE! We are now using `uwsm` for session management and app2unit for application management.

**PLEASE run install.sh again to upgrade and install missing dependencies and REBOOT!**

In SDDM, please choose `Hyprland (UWSM Managed)` as your session. Or else you will handle the session yourself!

### Changed

- Hyprlock: Sourcing hyprlock/HyDE.conf as default theme
- Core: Improved theming script stack
- Removed `xdg-config/hypr/hyde.conf` as it is too brittle. Use hyprland.conf instead!
- Moved all core hypr stuff to `~/.local/share/hypr`

### Added

- Core: Added 'app2unit.sh' as core script. This is a wrapper for the 'app' e.g. 'hyde-shell app mediaplayer.py' this runs the script as systemd scope. Using app2unit.sh as 'uwsm app' is slower.
- Core: Added 'xdg-terminal-exec' as core script. Added this in here because the upstream xdg-terminal-exec is not yet available officially.
- Development: Added 'Scripts/hydevm' for development. See its README.md for more info.
- Package: UWSM as dependency for HyDE.
- Core: app2unit.sh and xdg-terminal-exec as as static dependencies. These tools are not widely available and are not part of the core dependencies.
- The ~/.config/xdg-terminals.list file is now used to determine which terminal to use.
- Wallbash: Added spotify flatpak support
- Migration script implementation

### Fixed

- Waybar: Some fixes for modules
- Waybar: gpuinfo throws errors eg broken pipe
- Lib: Clean up variables that are using HYDE*, we will try to use the XDG\_* variables instead.
- Core: Fixed some issues with the theming script stack.

## v25.7.3

We use a dedicated Python environment to keep HyDE clean and dependency-free. Just run your scripts with `hyde-shell`— this handles the environment for you.

Examples:  
 `hyde-shell mediaplayer.py`  
 `hyde-shell waybar`

### Added

- CHANGELOG.md to track notable changes.
- Features and fixes for mediaplayer. #865
- HyDE's python environment rebuild on installation
- PyGObject for the python environment
- Mediaplayer: Add support for generic MPRIS metadata
- Mediaplayer: RIght click menu for mediaplayer
- Mediaplayer: Scroll up/down to seek
- Waybar: Added a POC implementation of drawers in group modules
- Waybar: Made mpris comparable to custom/mediaplayer. Should be noted mpris is not very customizable.
- Waybar: Added generic gamemode module which detects if games are running in feral mode
- Waybar: 'hyde-shell waybar --select' now will ask for **layout and style** options.
- Core:Solid theming fallback

### Removed

- Waybar: Remove test layouts.

### Changed

- Launch Scripts using 'hyde-shell' instead of '$scrPath/'
- Hyprland: Remove dconf setting in Hyprland config and add a separate dconf stack on color setup. This removes some hiccups on hyprctl reload.
- Updated `hyq` hyprquery v0.6.3r2
- Updated `hydectl`

### Fixed

- Waybar: Avoid multi user process conflict
- Mediaplayer: crash when player is not playing.
- Waybar: QOL fixes.
- Rofi: Fallback scaling for some script to not rely with hyprland

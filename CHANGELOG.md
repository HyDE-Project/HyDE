# Changelog

All notable changes to `HyDE` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to _Modified_ [CalVer](https://calver.org/). See [Versioning](https://github.com/HyDE-Project/HyDE/blob/master/RELEASE_POLICY.md#versioning-yymq) For more info

## v25.7.3

We use a dedicated Python environment to keep HyDE clean and dependency-free. Just run your scripts with `hyde-shell`— this handles the environment for you.

Examples:  
 `hyde-shell mediaplayer.py`  
 `hyde-shell waybar`

### Added

- CHANGELOG.md to track notable changes
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

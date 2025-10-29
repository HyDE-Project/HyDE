# Changelog

All notable changes to `HyDE` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to _Modified_ [CalVer](https://calver.org/). See [Versioning](https://github.com/HyDE-Project/HyDE/blob/master/RELEASE_POLICY.md#versioning-yymq) For more info

## v25.11.1

### Fixed

- Gamelauncher: steamdeck holograph
- Formatting using 

### Added

- Cliphist: image-history #1360
- Cliphist: Rofi binds #1360
- Gamelauncher: lutris inspector py script now uses the lutris DB to get meta dat making it faster than using lutris CLI
- Gamelauncher: steam inspector py script is translated from fn_steam shell script. 
- Gamelancher: catalog backend will merge both lutris and steam with hints for duplicates
- Gamelauncher: "hyde-shell gamelauncher" now has --style and --backend args
- Python: added pyproject.toml for ruff formatter
- Shell: Added ".editorconfig" for shell scripts.

### Changed

- Core: Moved core "color" switch inside directory in lib path. Prepare to make `~/.local/lib/hyde` external only scripts and corresponding directories will be sourced or executed internally. 
- Wallbash: Remove wallbash.qt as it is a simple cp command now in the qtct.dcol template



## v25.10.1

### Fixed
- Hyprland: Fix errors when `HYPRLAND_CONFIG` is not set yet
- Fish: Please Move you configs to `~/.config/fish/conf.d`

### Added

- QT6CT: Added explicit font configuration for QT6 Applications see [#1309](https://github.com/HyDE-Project/HyDE/issues/1309)
- QT5CT: Added explicit font configuration for QT5 Applications see [#1309](https://github.com/HyDE-Project/HyDE/issues/1309)
- GTK3: Added explicit font configuration for GTK3 Applications see [#1309](https://github.com/HyDE-Project/HyDE/issues/1309)

### Changed

- Audio volume control: use `wpctl` instead of `pamixer` for managing audio volume when PipeWire server is running.
- Fish: `config.fish` is now user defined config
- Fish: `confi.d/hyde.fish` is used for HyDE only stuff. To override this create a separate file or use `config.fish` 


### Migration

For fish shell users: 
Please empty your `~/.config/fish/config.fish` and use it to modify fish configurations.

## v25.9.3

### Changed

- OCR: `imagemagick` screenshot preprocessing tuned for better recognition results
- Docs: Improves release policy documentation by #1265

### Added

- Turkish documentation.
- No changes have been made to other codes.
- OCR: `tesseract` now supports explicit language settings via `hyde/config.toml`:
    ```toml
    [screenshot.ocr]
    tesseract_languages = ["eng"]
    ```
    To use text recognition bind `hyde-shell screenshot sc` to any hotkey.
- Hyprlock: Added hyprlock preview
- File chooser dialogs in Hyprland now open centered and floating instead of off-screen

### Fixed

- Hyprlock: fix hyprlock crashing by handling it as a systemd scope unit
- Hyprland: Backport Fix installation/update errors 

## v25.9.1

This release delivers a new gesture syntax for hyprland v0.51.0. This is a breaking change for users of the previous gesture syntax. Please update HyDE before opening an issue.

For contributors, if you need to make the workspace animation vertical, example the `vertical.conf` animation, please **explicitly** add the following line to file.


```
gesture = 3, horizontal, unset # unsets the default horizontal gesture
gesture = 3, vertical, workspace
```

### Changed

- Waybar: Make temperature background transparent
- hyde-shell: silent pyinit command
- Binds: Use `hyde-shell logout` for cleaner session logout
- Gestures: Chase hyprland v0.51.0 gesture syntax

### Added
- pinch gesture to toggle tile and floating

## v25.8.3

### Fixed

- Typos,spelling and and cleanup
- Dunst: Fix dunst crashing when the font cannot handle unsupported characters -- Thanks to [#1131](https://github.com/HyDE-Project/HyDE/issues/1131)
- UWSM: Clean up the xdg freedesktop.org spec as uwsm handles it
- Wallpaper: fix #1136 as exporting arrays are not supported in bash
- Lockscreen: Fix zombie hyprlock

### Changed

- Core: Move wallbash to ~/.local/share/wallbash
- Wlogout: Add support for for uwsm
- Flatpak: make themes,icons as rw for flatpak --user
- Added multi-gpu message to nvidia.conf
- Logs now will have '\*.log' as extension
- Waybar: run as a systemd scope unit on startup
- Wallpaper: run as a systemd scope unit on startup

### Added

- hyde-shell: Add 'logout' command to handle with/out uwsm
- waybar: Add lighter temperature module (Needs manual setup)
- Add credits page
- waybar: Try to force initialization on restore (redundancy) might fix [#1160](https://github.com/HyDE-Project/HyDE/issues/1160)
- Added pyprland boilerplate, no configs for now
- Hyprland: Graciously handle some of the issues hyprland config issues for unknown SHELL
- Pyprland: Use nc or socat to communicate with pyprland instead of pure python
- Pyprland: Add boilerplate config for pyprland

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

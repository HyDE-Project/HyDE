# Changelog

<!--
All notable changes to 'HyDE' will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to _Modified_ [CalVer](https://calver.org/). See [Versioning](https://github.com/HyDE-Project/HyDE/blob/master/RELEASE_POLICY.md#versioning-yymq) For more info
 -->

## Unreleased

### Added
- Docs: `MIGRATION-LUA.md`, a transition guide for upgrading from the hyprlang configuration — what moved where, the silent failures and their causes, and the files the upgrade leaves behind

### Removed
- Hyprland: dropped the legacy hyprlang dot, the files it deployed no longer exist

### Fixed
- Hyprland: restored missing background blur on UI layers (Waybar, Rofi, etc.)
- Core: `keyboardswitch.sh` triggers correct language notification; layout switch targets current device instead of cycling all devices, eliminating the IPC race condition and preventing multiple input devices from desyncing
- Rofi selector: the launcher grid is sized from the display again when the focused-monitor query comes back empty, instead of collapsing to a single column; the width had no fallback while the other two selectors both default to 1920
- Waybar: the theme picker opens again from the theme module, the HyDE menu and the macOS layout's menu; all three called `themeselect`, which the v26.7.4 migration renamed to `theme.select`
- Hyprlock: the lock screen comes up with its layout again instead of a black screen; the directory holding the shipped layouts was left behind by the move to the dot metafiles, so the selector listed nothing, `$LAYOUT_PATH` pointed at a file that was never deployed, and wallbash skipped the template rather than create the directory
- Hyprland: the shader selector offers the shipped shaders again, and the colors wallbash writes for the lock screen have somewhere to land; both directories stopped being deployed when the installer moved off the restore list
- wlogout: the menu is drawn with the HyDE layouts, icons and styles again instead of the upstream defaults
- Notifications: an install brings a notification daemon again; `dunst` and the configuration it reads were left in a group the installer never loads, so nothing served notifications and every wallbash pass reported a missing directory for a dot that was never deployed
- Core: an install no longer leaves the whole core package set uninstalled because one name is missing from the Arch repositories; `wlogout` and `libinput-gestures` are asked of an AUR helper, which is where they live, instead of pacman, which installs a dependency block with a single command and aborts all of it on a name it cannot resolve
- Core: the dependency steps install the packages they were given again; the configs the installer writes at run time declared their group include at the document root, where deez does not read it, so both steps resolved an empty set, installed nothing but the machine-specific packages, and reported the packages verified
- Hyprland: rofi style selector keybind now correctly opens style menu instead of the default application launcher
- Hyprland: a session started without `HYPRLAND_CONFIG`, from a TTY or a display manager, no longer trips emergency mode with `module 'lua.hyde.path' not found`; the entry point resolves the modules shipped beside it from its own path
- Fish: `~/.local/bin` reaches `PATH` again, so `hyde-shell` and everything the keybinds call resolve in a fish session; the directory was handed to `fish_add_path` joined to the rest of `PATH` by colons, which is one path that exists nowhere and is dropped without a word
- Weather Applet: Avoid crashes from unknown weather codes or unavailable wttr.in responses.
- Core: an install no longer ends at the Lua step on a machine that cannot build `lgi`; the introspection headers it compiles against are declared as a dependency, and an optional rock that still fails is reported and skipped instead of taking the run down before any dotfile is deployed
- Hyprland: a session on a machine with a discrete NVIDIA GPU no longer comes up with a timed-out configuration; driver detection reads `/proc` and `/sys`, and the library directories are found by opening the candidate paths, so the budget Hyprland allows the whole configuration is no longer spent waiting on a subprocess
- Core: an install deploys the cursor dots again instead of aborting on an existing theme file; the locked `deez-dots` revision predated the extraction fix, so every install kept running the defect the fix had already closed
- Core: Pyprland commands keep their arguments when `nc`, `socat`, and `ncat` are unavailable, so commands such as `hyde-shell pypr toggle console` work through the CLI fallback again
- Hyprland: a session started without `XDG_CONFIG_HOME`, such as one launched from a TTY, no longer dies with a Lua error before the first window; the unset variable is treated as unset instead of being pasted into a path
- Hyprland: a home directory containing an apostrophe no longer makes the session load its libraries from the system directory instead of the user's own, and an empty `XDG_RUNTIME_DIR` reads as unset rather than resolving against the working directory
- Waybar: the theme module and the HyDE menu call `theme.switch` again; `themeswitch` was removed and the calls failed outright
- Dolphin: the "Set As Wallpaper" service menu switches the theme again
- Fish: `HYPRLAND_CONFIG` points at the deployed `hypr/hyde.lua` instead of a config the Lua release deleted, so a session started outside uwsm no longer comes up without a config
- Hyprland: the config editor offers the user's `hypr/hyprland.lua` instead of four files nothing reads, which it used to create empty on save
- System monitor: a console monitor no longer launches with no terminal attached, and `[sysmonitor] terminal` is a real setting
- Docs: the keybinding reference describes the Lua configuration instead of the removed `userprefs.conf`, documents binds that were missing from it, corrects four descriptions that no longer matched the code, and explains why an override needs the original bind's flags
- Docs: the shipped `hypr/hyprland.lua` stub shows a working bind instead of pointing at a wiki that does not exist
- Docs: the keybinding links in the German, Arabic, French, Dutch and Turkish readmes resolve again
- Core: every migration that has not been applied yet now runs in version order and is recorded, instead of only the newest one running and retiring the rest unseen
- Core: app launchers no longer show a false error when an unrelated `DEBUG` variable contains a non-boolean value such as `release`
- Desktop: the generated battery notification startup command now launches `batterynotify.lua` instead of the removed shell implementation
- Hyprland: Lua keybinds again match the documented shortcuts for window management, screenshots, wallpapers, Waybar, selectors, workspaces and the scratchpad
- Screenshot: area capture now uses the fixed upstream Grimblast selector instead of prompting for the region twice
- Screenshot: Satty defaults to the compatible GTK GL renderer when no explicit `GSK_RENDERER` is configured
- Screenshot: the "print all monitors" keybind now invokes a full-output capture instead of capturing only the focused monitor
- Waybar `hyprland/workspaces` module adapted to use lua dispatchers
- Hyprland: `Super + Ctrl + arrows` no longer changes the group and the workspace at the same time.
  Group navigation uses `Super + Ctrl + H/L`
- Hyprland: the right Control key no longer hides Waybar on its own. Hiding moved to `Super + Ctrl + B`
- Hyprland: workspaces 11-20 on the numpad respond again
- OCR: the language list in the result notification is no longer split across arguments
- Wallpaper: the duplicate check in the kon backend compares against the whole hash list again
- Repo: dropped two stray gitlinks that made `git submodule` fail on a fresh clone

## v26.7.4 | 4th Week of July 2026 Release

**Alright** Looks like hyprland 0.56.1 warns user to use lua so here you go!

Run `install.sh -r` to update.

Please report and try to fix any bugs. Thank you!
Life is tight as of the moment. Any help will do. 💓


### Added
- GTK: hyde will have our own dconf db called 'hyde_hyprland'. That means dconf settings are isolated for HyDE Hyprland ONLY
- Hyprland: Added 'hyde-shell layouts --select' to select hyprland layouts from default or custom layouts.
  Add your custom layout modifications to '~/.config/hypr/lua/layouts/custom.lua'


### Changed

- Hyprland: Use lua for all its config
- Hyprland: Deprecate old hyprlang configs
- Core: Added lua and luarocks dependencies
- Core: Convert some script to lua
- Hyprland: Removed '[hyprland-start]'. Use 'desktop.start' instead.
- Desktop: Added 'desktop.start' to handle startup commands.
- Core: Some config changes in '~/.config/hyde/config.toml', Please see the schema for more info.
- Hyprland: Drop of hyprlang support
- GTK: Have a separate 'DCONF_PROFILE' for GTK apps! For QT, twas always handled by qt6ct and should not
    mangle with QT. But KDE apps uses ~/.config/kdeglobals which might break KDE apps for multi DE. (No fix for now)


### Fixed
- Fix cantarell font
- Some minor bugs

## v26.4.5 | End of April Release

### Changed
- Pyprland: Upgraded to v3.3.1
- Hypr: removed 'hypr.altab.py' as it is too slow and and use 'hypr.altab.lua' instead. Test using 'hyde-shell altab' to see if it works!

### Added
- Core: Use 'rsync' for file copy operations. Only recommended if users already have 'rsync' installed.
- Package Manager: Added --no-confirm flag to 'hyde-shell pm.py' commands.
- Lua: Added 'hyde-shell luainit' to initialize the Lua runtime. It is slow and should be optional for now.
- Python: 'hyde-shell pyinit' will now sync like pip to preserve user packages.

## v26.4.3 | 3rd week of April 2026 Release!

### Changed

- Wallpaper: Pt. 1 of multi theming backend.
- Hyprland: Remove 'hyde.conf' as it is too brittle. Use 'hyprland.conf' instead!
- Window: Moved 'windowpin' to 'window.pin'. For consistency.
- pyutils: Kinda clean up libnotify wrapper.
- Updated app2unit. https://github.com/Vladimir-csp/app2unit/blob/87dd9cd14e020b199256854c84f31b62680d1b21/app2unit
- Changed Shader main manu into 'Eye Care' and sub menus will have Temperature, Gamma and the Shaders Selector.
- Waybar: waybar now uses systemd run instead of app2unit to handle env properly.
- Updated the hyde-config binary
- Python-env: Deprecate pip and use uv instead.
- Hypr: Removed '~/.config/hypr/hyde.conf' as it is not being used or a long time now. Please use the 'config.toml' instead
- hyprlock: Added options under [hyprlock]: hide_cursor,ignore_empty_input,immediate_render,text_trim,fractional_scaling,screencopy_mode,fail_timeout. See https://wiki.hypr.land/Hypr-Ecosystem/hyprlock/
- Core: Removed hyq binary .Please install it using your own package-manager. 'yay -Sy hyprquery'

### Added
- Window: added 'hyde-shell window.mute' to toggle window audio. This is a python implementation for 'wl-togglesink'
- Windowrules: add opacity rule and floating rules for Blender to disable transparency, float render window, and set render window size to 50% of monitor
- l10n: Added a bash POC for localization. Python already has built in support for localization. This is just a POC for bash scripts. It is not yet fully implemented and is not yet available for all scripts. So we can share language packs. Please open a discussion if you are interested in helping with localization. (keeping this here just to see who really cared lol.)
- hyprsunset: Added identity param to be used temp
- Waybar: Added Eyecare menu
- Session: *Experimental* feature which might be helpful as session restore in wayland is being worked on. 'hyde-shell session --help' to learn more!
- Hyprland: *Experimental* Added an Alt-tab like feature that behaves like a browser. It is slow so I might port it to go.
- Wallpaper: [waydeeper](https://github.com/EdenQwQ/waydeeper) can be used as wallpaper backend. To use it, waydeeper should be installed manually.
- Lua: ****Experimental** Lua support. Please open a discussion if you are interested in helping with Lua support. Uses hererocks to install lua.

### Fixed
- Weather: Fix [#1664](https://github.com/HyDE-Project/HyDE/issues/1664)
- Waybar: Fix some errors on env.


## v26.1.2


### Fixed

- Waybar: visual fixes for menus, tooltips and tray (borders, radii, checkbox/radio shapes)
- Broken venvs are now auto-rebuilt when installing a dependency

### Changed

- Waybar: improved menus and popups; added fade animation and theme color support (#1542, #1549)
- Font: avoid forcing font hinting to "full"; prefer system default (commits 7ceff6a, bf7cee2)
- Misc: removed stray "hyprquery" binary (af551c6) and branch sync/merges (dev → rc, docs-ptbr)
- Docs: Portuguese translations for documentation and keybinds (#1543)
- Cpuinfo: colors are now available as css class instead hardcoding in scripts.
- Gpuinfo: colors are now available as css class instead hardcoding in scripts.


## v25.12.4

### Fixed

- Game launcher: steamdeck holograph
- Formatting using
- Hyprland 0.53 Syntax Revamp
- Some old hyprdots theme parsing.

### Added

- Wallpaper: Added wallpaper '--multi-select' for multiple --outputs. Useful for per monitor or lockscreen/display manager background.
- Wallpaper: Selector option to modify column count
- Theme: Selector option to modify thumbnail types and column count
- CLI: Added 'hyde-shell open' for apps with mimetypes
- Core: Clean up 'hyde-shell wallpaper' script
- Restore: Added option to trash the config to avoid conflicts
- Waybar: Added pavucontrol-qt in the module
- Rofi: Added search functionality to the game launcher menu.
- Cliphist: image-history #1360
- Cliphist: Rofi binds #1360
- Game launcher: lutris inspector py script now uses the lutris DB to get meta dat making it faster than using lutris CLI
- Game launcher: steam inspector py script is translated from fn_steam shell script.
- Game launcher: catalog backend will merge both lutris and steam with hints for duplicates
- Game launcher: "hyde-shell game launcher" now has --style and --backend args
- Python: added pyproject.toml for ruff formatter
- Shell: Added ".editorconfig" for shell scripts.
- Cliphist: Added OCR backend. Invoking "hyde-shell cliphist -scan-image" or 'Alt+V' on clipboard will extract the text of the latest image that exist in cliphist.
- Screenshot: Added QR code reading feature using 'zbar' package. No default hotkey is provided. Call it via 'hyde-shell screenshot sq'
- Weather Applet: Added automatic locale detection for temperature units (°C/°F), time formats (12h/24h), and wind speed (km/h/mph).
- Weather Applet: Implemented multi-language support based on system locale and added 'WEATHER_LANG' for manual overrides.
- Weather Applet: Added support for a user-defined configuration file at '~/.config/weather.env'.

### Changed

- NVIDIA: Updated driver database to separate legacy and modern GPU support. 'nvidia-open-dkms' now targets Turing (NV160) and newer, while 'nvidia-580xx-dkms' covers Maxwell (NV110) through Volta (NV140).
- QT: Move qtXct/colors.conf into qtXct/colors/wallbash.conf. This is how qtXct Settings parses color schemes the proper way.
- Core: Moved core "color" switch inside directory in lib path. Prepare to make '~/.local/lib/hyde' external only scripts and corresponding directories will be sourced or executed internally.
- Wallbash: Remove wallbash.qt as it is a simple cp command now in the qtct.dcol template
- UWSM: Start processes launched with app2unit.sh,rofi,'hyde-shell app' as services

### Migration

##### Hyprland v0.53.0

- Before updating HyDE, Please make sure your hyprland version is 0.53.0!
- After Updating HyDE please make sure to fix any syntax error in ~/.config/hypr/*

We are trying our best to fix any issues. So please try to your best to search for any duplicate issues and potential fixes!

Stay HyDErated!

##### NVIDIA Legacy Support

The driver selection/installation logic has been updated to align with Arch Linux recommendations.

- **Turing (NV160) and newer**: Now defaults to 'nvidia-open-dkms'.
- **Maxwell (NV110) to Volta (NV140)**: Now defaults to 'nvidia-580xx-dkms'.


**Existing Users**
- nv110-nv140 cards, please install 'nvidia-580xx-dkms' before updating your whole system or before rebooting. 'nvidia-open-dkms' could potentially borke your display. Goodluck!
- nv160 (Turing) and above see **Fallback**

**Fallback:**
Users with Turing or newer cards using 'nvidia-open-dkms' can fallback to 'nvidia-580xx-dkms' if they encounter issues, as the 580xx branch still supports these architectures.


- Read wiki https://wiki.archlinux.org/title/NVIDIA
- See common solutions https://github.com/HyDE-Project/HyDE/discussions/1477


## v25.10.1

### Fixed
- Hyprland: Fix errors when 'HYPRLAND_CONFIG' is not set yet
- Fish: Please Move you configs to '~/.config/fish/conf.d'

### Added

- QT6CT: Added explicit font configuration for QT6 Applications see [#1309](https://github.com/HyDE-Project/HyDE/issues/1309)
- QT5CT: Added explicit font configuration for QT5 Applications see [#1309](https://github.com/HyDE-Project/HyDE/issues/1309)
- GTK3: Added explicit font configuration for GTK3 Applications see [#1309](https://github.com/HyDE-Project/HyDE/issues/1309)

### Changed

- Audio volume control: use 'wpctl' instead of 'pamixer' for managing audio volume when PipeWire server is running.
- Fish: 'config.fish' is now user defined config
- Fish: 'confi.d/hyde.fish' is used for HyDE only stuff. To override this create a separate file or use 'config.fish'


### Migration

For fish shell users:
Please empty your '~/.config/fish/config.fish' and use it to modify fish configurations.

## v25.9.3

### Changed

- OCR: 'imagemagick' screenshot preprocessing tuned for better recognition results
- Docs: Improves release policy documentation by #1265

### Added

- Turkish documentation.
- No changes have been made to other codes.
- OCR: 'tesseract' now supports explicit language settings via 'hyde/config.toml':
    '''toml
    [screenshot.ocr]
    tesseract_languages = ["eng"]
    '''
    To use text recognition bind 'hyde-shell screenshot sc' to any hotkey.
- Hyprlock: Added hyprlock preview
- File chooser dialogs in Hyprland now open centered and floating instead of off-screen

### Fixed

- Hyprlock: fix hyprlock crashing by handling it as a systemd scope unit
- Hyprland: Backport Fix installation/update errors

## v25.9.1

This release delivers a new gesture syntax for hyprland v0.51.0. This is a breaking change for users of the previous gesture syntax. Please update HyDE before opening an issue.

For contributors, if you need to make the workspace animation vertical, example the 'vertical.conf' animation, please **explicitly** add the following line to file.


'''
gesture = 3, horizontal, unset # unsets the default horizontal gesture
gesture = 3, vertical, workspace
'''

### Changed

- Waybar: Make temperature background transparent
- hyde-shell: silent pyinit command
- Binds: Use 'hyde-shell logout' for cleaner session logout
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

Big CHANGE in HyDE! We are now using 'uwsm' for session management and app2unit for application management.

**PLEASE run install.sh again to upgrade and install missing dependencies and REBOOT!**

In SDDM, please choose 'Hyprland (UWSM Managed)' as your session. Or else you will handle the session yourself!

### Changed

- Hyprlock: Sourcing hyprlock/HyDE.conf as default theme
- Core: Improved theming script stack
- Removed 'xdg-config/hypr/hyde.conf' as it is too brittle. Use hyprland.conf instead!
- Moved all core hypr stuff to '~/.local/share/hypr'

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

We use a dedicated Python environment to keep HyDE clean and dependency-free. Just run your scripts with 'hyde-shell'— this handles the environment for you.

Examples:
 'hyde-shell mediaplayer.py'
 'hyde-shell waybar'

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
- Updated 'hyq' hyprquery v0.6.3r2
- Updated 'hydectl'

### Fixed

- Waybar: Avoid multi user process conflict
- Mediaplayer: crash when player is not playing.
- Waybar: QOL fixes.
- Rofi: Fallback scaling for some script to not rely with hyprland

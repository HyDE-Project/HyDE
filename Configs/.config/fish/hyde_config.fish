#!/usr/bin/env fish
#!          ░▒▓         
#!        ░▒▒░▓▓         
#!      ░▒▒▒░░░▓▓           ___________
#!    ░░▒▒▒░░░░░▓▓        //___________/
#!   ░░▒▒▒░░░░░▓▓     _   _ _    _ _____
#!   ░░▒▒░░░░░▓▓▓▓▓▓ | | | | |  | |  __/
#!    ░▒▒░░░░▓▓   ▓▓ | |_| | |_/ /| |___
#!     ░▒▒░░▓▓   ▓▓   \__  |____/ |____/  █▀▀ █ █▀ █░█
#!       ░▒▓▓   ▓▓  //____/               █▀  █ ▄█ █▀█

# HyDE's fish env configuration
# This file is sourced by fish on startup

# Ensure XDG base directories are set, using defaults if not already defined
if test -z "$XDG_CONFIG_HOME"
    set -gx XDG_CONFIG_HOME "$HOME/.config"
end

if test -z "$XDG_CONFIG_DIR"
    set -gx XDG_CONFIG_DIR "$HOME/.config"
end

if test -z "$XDG_DATA_HOME"
    set -gx XDG_DATA_HOME "$HOME/.local/share"
end

if test -z "$XDG_DATA_DIRS"
    set -gx XDG_DATA_DIRS "$XDG_DATA_HOME:/usr/local/share:/usr/share"
end

if test -z "$XDG_STATE_HOME"
    set -gx XDG_STATE_HOME "$HOME/.local/state"
end

if test -z "$XDG_CACHE_HOME"
    set -gx XDG_CACHE_HOME "$HOME/.cache"
end

# Load user-defined directories from user-dirs.dirs if available
if test -f "$XDG_CONFIG_HOME/user-dirs.dirs"
    source "$XDG_CONFIG_HOME/user-dirs.dirs"
end

# Dynamically retrieve user directories using xdg-user-dir
set -gx XDG_DESKTOP_DIR (xdg-user-dir DESKTOP)
set -gx XDG_DOWNLOAD_DIR (xdg-user-dir DOWNLOAD)
set -gx XDG_TEMPLATES_DIR (xdg-user-dir TEMPLATES)
set -gx XDG_PUBLICSHARE_DIR (xdg-user-dir PUBLICSHARE)
set -gx XDG_DOCUMENTS_DIR (xdg-user-dir DOCUMENTS)
set -gx XDG_MUSIC_DIR (xdg-user-dir MUSIC)
set -gx XDG_PICTURES_DIR (xdg-user-dir PICTURES)
set -gx XDG_VIDEOS_DIR (xdg-user-dir VIDEOS)

# Other settings
if test -z "$LESSHISTFILE"
    set -gx LESSHISTFILE "/tmp/less-hist"
end

set -gx PARALLEL_HOME "$XDG_CONFIG_HOME/parallel"
set -gx WGETRC "$XDG_CONFIG_HOME/wgetrc"
set -gx SCREENRC "$XDG_CONFIG_HOME/screen/screenrc"

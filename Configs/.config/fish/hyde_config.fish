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

if test -z "$XDG_DATA_HOME"
    set -gx XDG_DATA_HOME "$HOME/.local/share"
end

if test -z "$XDG_STATE_HOME"
    set -gx XDG_STATE_HOME "$HOME/.local/state"
end

if test -z "$XDG_CACHE_HOME"
    set -gx XDG_CACHE_HOME "$HOME/.cache"
end

if test -z "$XDG_DATA_DIRS"
    set -gx XDG_DATA_DIRS "$XDG_DATA_HOME:/usr/local/share:/usr/share"
end

if test -z "$XDG_CONFIG_DIR"
    set -gx XDG_CONFIG_DIR "$XDG_CONFIG_HOME"
end

# User Dirs: static fallback, used only if `xdg-user-dir` is not available
if test -z "$XDG_DESKTOP_DIR"
    set -gx XDG_DESKTOP_DIR "$HOME/Desktop"
end

if test -z "$XDG_DOWNLOAD_DIR"
    set -gx XDG_DOWNLOAD_DIR "$HOME/Downloads"
end

if test -z "$XDG_TEMPLATES_DIR"
    set -gx XDG_TEMPLATES_DIR "$HOME/Templates"
end

if test -z "$XDG_PUBLICSHARE_DIR"
    set -gx XDG_PUBLICSHARE_DIR "$HOME/Public"
end

if test -z "$XDG_DOCUMENTS_DIR"
    set -gx XDG_DOCUMENTS_DIR "$HOME/Documents"
end

if test -z "$XDG_MUSIC_DIR"
    set -gx XDG_MUSIC_DIR "$HOME/Music"
end

if test -z "$XDG_PICTURES_DIR"
    set -gx XDG_PICTURES_DIR "$HOME/Pictures"
end

if test -z "$XDG_VIDEOS_DIR"
    set -gx XDG_VIDEOS_DIR "$HOME/Videos"
end

# Load user-defined directories from user-dirs.dirs if available
if test -f "$XDG_CONFIG_HOME/user-dirs.dirs"
    source "$XDG_CONFIG_HOME/user-dirs.dirs"
end

# Dynamically retrieve user directories using xdg-user-dir
function set-xdg-dir
    set -l name $argv[1]
    set -l varname (string join _ XDG $name DIR)

    if type -q xdg-user-dir
        set -l result (xdg-user-dir $name)
        if test -n "$result"
            set -gx $varname "$result"
        end
    else
        # fallback to $HOME/<dirName> if xdg-user-dir is not available
        switch $name
            case DESKTOP DOWNLOAD TEMPLATES PUBLICSHARE DOCUMENTS MUSIC PICTURES VIDEOS
                set -gx $varname "$HOME/$name"
        end
    end
end

for dir in DESKTOP DOWNLOAD TEMPLATES PUBLICSHARE DOCUMENTS MUSIC PICTURES VIDEOS
    set-xdg-dir $dir
end

# Other env variables
if test -z "$LESSHISTFILE"
    set -gx LESSHISTFILE "/tmp/less-hist"
end

set -gx PARALLEL_HOME "$XDG_CONFIG_HOME/parallel"
set -gx WGETRC "$XDG_CONFIG_HOME/wgetrc"
set -gx SCREENRC "$XDG_CONFIG_HOME/screen/screenrc"

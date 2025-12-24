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

# ensure that the XDG variables are set
if test -z "$XDG_CONFIG_HOME"
set -gx XDG_CONFIG_HOME "$HOME/.config"
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

if test -z "$LESSHISTFILE"
set -gx LESSHISTFILE "/tmp/less-hist"
end

if test -z "$PARALLEL_HOME"
set -gx PARALLEL_HOME "$XDG_CONFIG_HOME/parallel"
end

if test -z "$HYPRLAND_CONFIG"
set -gx HYPRLAND_CONFIG "$XDG_DATA_HOME/hypr/hyprland.conf"
end

fish_add_path $HOME/.local/bin:$PATH


if type -q starship
starship init fish | source
set -gx STARSHIP_CACHE $XDG_CACHE_HOME/starship
set -gx STARSHIP_CONFIG $XDG_CONFIG_HOME/starship/starship.toml
end


if type -q duf
function df -d "Run duf with last argument if valid, else run duf"
if set -q argv[-1] && test -e $argv[-1]
duf $argv[-1]
else
duf
end
end
end

# # fzf
# if type -q fzf
#     fzf --fish | source
#     for file in ~/.config/fish/functions/fzf/*.fish
#         source $file
#         # NOTE: these functions are built on top of fzf builtin widgets
#         # they help you navigate through directories and files "Blazingly" fast
#         # to get help on each one, just type `ff` in terminal and press `TAB`
#         # keep in mind all of them require an argument to be passed after the alias
#     end
# end


# NOTE: binds Alt+n to inserting the nth command from history in edit buffer
# e.g. Alt+4 is same as pressing Up arrow key 4 times
# really helpful if you get used to it
bind_M_n_history



# example integration with bat : <cltr+f>
# bind -M insert \ce '$EDITOR $(fzf --preview="bat --color=always --plain {}")'


set fish_pager_color_prefix cyan
set fish_color_autosuggestion brblack

# List Directory
alias c='clear'
alias l='eza -lh --icons=auto'
alias ls='eza -1 --icons=auto'
alias ll='eza -lha --icons=auto --sort=name --group-directories-first'
alias ld='eza -lhD --icons=auto'
alias lt='eza --icons=auto --tree'
alias in='hyde-shell pm install'
alias un='hyde-shell pm remove'
alias up='hyde-shell pm upgrade'
alias pl='hyde-shell pm search installed'
alias pa='hyde-shell pm search all'
alias g='git'
alias fastfetch='fastfetch --logo-type kitty'

# Directory navigation shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'

alias vc='code'

abbr mkdir 'mkdir -p'

set -g fish_greeting

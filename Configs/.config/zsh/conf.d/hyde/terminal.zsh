#!/usr/bin/env zsh

#! ██████╗░░█████╗░  ███╗░░██╗░█████╗░████████╗  ███████╗██████╗░██╗████████╗
#! ██╔══██╗██╔══██╗  ████╗░██║██╔══██╗╚══██╔══╝  ██╔════╝██╔══██╗██║╚══██╔══╝
#! ██║░░██║██║░░██║  ██╔██╗██║██║░░██║░░░██║░░░  █████╗░░██║░░██║██║░░░██║░░░
#! ██║░░██║██║░░██║  ██║╚████║██║░░██║░░░██║░░░  ██╔══╝░░██║░░██║██║░░░██║░░░
#! ██████╔╝╚█████╔╝  ██║░╚███║╚█████╔╝░░░██║░░░  ███████╗██████╔╝██║░░░██║░░░
#! ╚═════╝░░╚════╝░  ╚═╝░░╚══╝░╚════╝░░░░╚═╝░░░  ╚══════╝╚═════╝░╚═╝░░░╚═╝░░░

# HyDE's ZSH env configuration
# This file is sourced by ZSH on startup
# And ensures that we have an obstruction-free .zshrc file
# This also ensures that the proper HyDE $ENVs are loaded

function _load_zsh_plugins {
    unset -f _load_zsh_plugins
    # Oh-my-zsh installation path
    zsh_paths=(
        "$HOME/.oh-my-zsh"
        "/usr/local/share/oh-my-zsh"
        "/usr/share/oh-my-zsh"
    )
    for zsh_path in "${zsh_paths[@]}"; do [[ -d $zsh_path ]] && export ZSH=$zsh_path && break; done
    # Load Plugins
    hyde_plugins=(git zsh-256color zsh-autosuggestions zsh-syntax-highlighting)
    plugins+=("${plugins[@]}" "${hyde_plugins[@]}")
    # Deduplicate plugins
    plugins=("${plugins[@]}")
    plugins=($(printf "%s\n" "${plugins[@]}" | sort -u))
    # Defer oh-my-zsh loading until after prompt appears
    typeset -g DEFER_OMZ_LOAD=1
}

function _load_persistent_aliases {
    # Persistent aliases are loaded after the plugin is loaded
    # This way omz will not override them
    unset -f _load_persistent_aliases

    if [[ -x "$(command -v eza)" ]]; then
        alias l='eza -lh --icons=auto' \
            ll='eza -lha --icons=auto --sort=name --group-directories-first' \
            ld='eza -lhD --icons=auto' \
            lt='eza --icons=auto --tree'
    fi

}

function _load_post_init() {
    #! Never load time consuming functions here
    _load_persistent_aliases

    # Add your completions directory to fpath
    fpath=($ZDOTDIR/completions "${fpath[@]}")

    autoload -U compinit && compinit

    for file in "${ZDOTDIR:-$HOME/.config/zsh}/completions/"*.zsh; do
        [ -r "$file" ] && source "$file"
    done

    # zsh-autosuggestions won't work on first prompt when deferred
    if typeset -f _zsh_autosuggest_start >/dev/null; then
        _zsh_autosuggest_start
    fi

    # User rc file always overrides
    [[ -f $HOME/.zshrc ]] && source $HOME/.zshrc

}

function _load_omz_on_init() {
    # Load oh-my-zsh when line editor initializes // before user input
    if [[ -n $DEFER_OMZ_LOAD ]]; then
        unset DEFER_OMZ_LOAD
        [[ -r $ZSH/oh-my-zsh.sh ]] && source $ZSH/oh-my-zsh.sh
        ZDOTDIR="${__ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
        _load_post_init
    fi
}

function do_render {
    # Check if the terminal supports images
    local type="${1:-image}"
    # TODO: update this list if needed
    TERMINAL_IMAGE_SUPPORT=(kitty konsole ghostty WezTerm)
    local terminal_no_art=(vscode code codium)
    TERMINAL_NO_ART="${TERMINAL_NO_ART:-${terminal_no_art[@]}}"
    CURRENT_TERMINAL="${TERM_PROGRAM:-$(ps -o comm= -p $(ps -o ppid= -p $$))}"

    case "${type}" in
    image)
        if [[ " ${TERMINAL_IMAGE_SUPPORT[@]} " =~ " ${CURRENT_TERMINAL} " ]]; then
            return 0
        else
            return 1
        fi
        ;;
    art)
        if [[ " ${TERMINAL_NO_ART[@]} " =~ " ${CURRENT_TERMINAL} " ]]; then
            return 1
        else
            return 0
        fi
        ;;
    *)
        return 1
        ;;
    esac
}

_load_deferred_plugin_system_by_hyde() {

    # Exit early if HYDE_ZSH_DEFER is not set to 1
    if [[ -z "${HYDE_ZSH_DEFER}" ]]; then
        unset -f _load_deferred_plugin_system_by_hyde
        return
    fi

    # Load plugins
    _load_zsh_plugins

    # Load zsh hooks module once

    #? Methods to load oh-my-zsh lazily
    __ZDOTDIR="${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
    # Temporarily set ZDOTDIR to /tmp to isolate deferred plugin loading from the user's primary configuration directory.
    ZDOTDIR=/tmp
    zle -N zle-line-init _load_omz_on_init # Loads when the line editor initializes // The best option

    #  Below this line are the commands that are executed after the prompt appears

    autoload -Uz add-zsh-hook
    # add-zsh-hook zshaddhistory load_omz_deferred # loads after the first command is added to history
    # add-zsh-hook precmd load_omz_deferred # Loads when shell is ready to accept commands
    # add-zsh-hook preexec load_omz_deferred # Loads before the first command executes

    # TODO: add handlers in pm.sh
    # for these aliases please manually add the following lines to your .zshrc file.(Using yay as the aur helper)
    # pc='yay -Sc' # remove all cached packages
    # po='yay -Qtdq | ${PM_COMMAND[@]} -Rns -' # remove orphaned packages

    # Some binds won't work on first prompt when deferred
    bindkey '\e[H' beginning-of-line
    bindkey '\e[F' end-of-line

}

#? Override this environment variable in ~/.zshrc
# cleaning up home folder
# ZSH Plugin Configuration
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# History configuration
HISTFILE=${HISTFILE:-$HOME/.zsh_history}
if [[ ! -f $HISTFILE ]]; then
    HISTFILE=${ZDOTDIR/.zsh_history/}
fi
HISTSIZE=10000
SAVEHIST=10000
setopt EXTENDED_HISTORY       # Write the history file in the ':start:elapsed;command' format
setopt INC_APPEND_HISTORY     # Write to the history file immediately, not when the shell exits
setopt SHARE_HISTORY          # Share history between all sessions
setopt HIST_EXPIRE_DUPS_FIRST # Expire a duplicate event first when trimming history
setopt HIST_IGNORE_DUPS       # Do not record an event that was just recorded again
setopt HIST_IGNORE_ALL_DUPS   # Delete an old recorded event if a new event is a duplicate

# Export ZSH-specific variables
export ZSH_AUTOSUGGEST_STRATEGY HISTFILE

# HyDE Package Manager
PM_COMMAND=(hyde-shell pm)

# Optionally load user configuration // useful for customizing the shell without modifying the main file
if [[ -f $HOME/.hyde.zshrc ]]; then
    source $HOME/.hyde.zshrc # for backward compatibility
elif [[ -f $HOME/.user.zsh ]]; then
    source $HOME/.user.zsh # renamed to .user.zsh for intuitiveness that it is a user config
elif [[ -f $ZDOTDIR/user.zsh ]]; then
    source $ZDOTDIR/user.zsh
fi

# Try to load prompts immediately
[[ -f $ZDOTDIR/conf.d/hyde/prompt.zsh ]] && source $ZDOTDIR/conf.d/hyde/prompt.zsh

_load_deferred_plugin_system_by_hyde

alias c='clear' \
    in='${PM_COMMAND[@]} install' \
    un='${PM_COMMAND[@]} remove' \
    up='${PM_COMMAND[@]} upgrade' \
    pl='${PM_COMMAND[@]} search installed' \
    pa='${PM_COMMAND[@]} search all' \
    vc='code' \
    fastfetch='fastfetch --logo-type kitty' \
    ..='cd ..' \
    ...='cd ../..' \
    .3='cd ../../..' \
    .4='cd ../../../..' \
    .5='cd ../../../../..' \
    mkdir='mkdir -p'

# revert to proper ZDOTDIR
export ZDOTDIR="${__ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}"
unset __ZDOTDIR

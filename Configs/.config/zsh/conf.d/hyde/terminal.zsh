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

function _load_functions() {
    # Load all custom function files // Directories are ignored
    for file in "${ZDOTDIR:-$HOME/.config/zsh}/functions/"*.zsh; do
        [ -r "$file" ] && source "$file"
    done
}

function _load_completions() {
    for file in "${ZDOTDIR:-$HOME/.config/zsh}/completions/"*.zsh; do
        [ -r "$file" ] && source "$file"
    done
}

function _dedup_zsh_plugins {
    unset -f _dedup_zsh_plugins
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

function _defer_omz_after_prompt_before_input() {

    [[ -r $ZSH/oh-my-zsh.sh ]] && source $ZSH/oh-my-zsh.sh
    #! Never load time consuming functions here

    # Add your completions directory to fpath
    fpath=($ZDOTDIR/completions "${fpath[@]}")

    _load_compinit
    _load_functions
    _load_completions

    # zsh-autosuggestions won't work on first prompt when deferred
    if typeset -f _zsh_autosuggest_start >/dev/null; then
        _zsh_autosuggest_start
    fi

    chmod +r $ZDOTDIR/.zshrc # Make sure .zshrc is readable
    [[ -r $ZDOTDIR/.zshrc ]] && source $ZDOTDIR/.zshrc
}

function _load_deferred_plugin_system_by_hyde() {

    # Exit early if HYDE_ZSH_DEFER is not set to 1
    if [[ "${HYDE_ZSH_DEFER}" != "1" ]]; then
        unset -f _load_deferred_plugin_system_by_hyde
        return
    fi

    # Defer oh-my-zsh loading until after prompt appears
    # Load oh-my-zsh when line editor initializes // before user input
    if [[ -n $DEFER_OMZ_LOAD ]]; then
        unset DEFER_OMZ_LOAD
        [[ ${VSCODE_INJECTION} == 1 ]] || chmod -r $ZDOTDIR/.zshrc # let vscode read .zshrc
        zle -N zle-line-init _defer_omz_after_prompt_before_input  # Loads when the line editor initializes // The best option
    fi
    #  Below this line are the commands that are executed after the prompt appears

    # autoload -Uz add-zsh-hook
    # add-zsh-hook zshaddhistory load_omz_deferred # loads after the first command is added to history
    # add-zsh-hook precmd load_omz_deferred # Loads when shell is ready to accept commands
    # add-zsh-hook preexec load_omz_deferred # Loads before the first command executes

    # TODO: add handlers in pm.sh
    # for these aliases please manually add the following lines to your .zshrc file.(Using yay as the aur helper)
    # pc='yay -Sc' # remove all cached packages
    # po='yay -Qtdq | ${PM_COMMAND[@]} -Rns -' # remove orphaned packages

    # zsh-autosuggestions won't work on first prompt when deferred
    if typeset -f _zsh_autosuggest_start >/dev/null; then
        _zsh_autosuggest_start
    fi

    # Some binds won't work on first prompt when deferred
    bindkey '\e[H' beginning-of-line
    bindkey '\e[F' end-of-line

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

function _load_compinit() {
    # Initialize completions with optimized performance
    autoload -Uz compinit

    # Enable extended glob for the qualifier to work
    setopt EXTENDED_GLOB

    # Fastest - use glob qualifiers on directory pattern
    if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+${HYDE_ZSH_COMPINIT_CHECK:-1}) ]]; then
        compinit
    else
        compinit -C
    fi

    _comp_options+=(globdots) # tab complete hidden files
}

function _load_prompt() {
    # Try to load prompts immediately
    if ! source ${ZDOTDIR}/prompt.zsh > /dev/null 2>&1; then
        [[ -f $ZDOTDIR/conf.d/hyde/prompt.zsh ]] && source $ZDOTDIR/conf.d/hyde/prompt.zsh
    fi
}

# Override this environment variable in ~/.zshrc
# cleaning up home folder
# ZSH Plugin Configuration

HYDE_ZSH_DEFER="1"      #Unset this variable in $ZDOTDIR/user.zsh to disable HyDE's deferred Zsh loading.
HYDE_ZSH_PROMPT="1"     #Unset this variable in $ZDOTDIR/user.zsh to disable HyDE's prompt customization.
HYDE_ZSH_NO_PLUGINS="0" #Set this variable to "1" in $ZDOTDIR/user.zsh to disable HyDE's Zsh plugin loading.

ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# # History configuration
HISTFILE=${HISTFILE:-$ZDOTDIR/.zsh_history}
if [[ -f $HOME/.zsh_history ]] && [[ ! -f $HISTFILE ]]; then
    echo "Please manually move $HOME/.zsh_history to $HISTFILE"
    echo "Or move it somewhere else to avoid conflicts"
fi

export HISTFILE ZSH_AUTOSUGGEST_STRATEGY

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

_load_compinit


if [[ ${HYDE_ZSH_NO_PLUGINS} != "1" ]]; then
    # Deduplicate omz plugins()
    _dedup_zsh_plugins

    if [[ "$HYDE_ZSH_OMZ_DEFER" == "1" ]]; then
        _load_deferred_plugin_system_by_hyde
        _load_prompt # This disables transient prompts sadly
    else
        [[ -r $ZSH/oh-my-zsh.sh ]] && source $ZSH/oh-my-zsh.sh
        _load_prompt
        _load_functions
        _load_completions
    fi
else
    _load_prompt
    _load_functions
    _load_completions

    chmod +r $ZDOTDIR/.zshrc # Make sure .zshrc is readable
    [[ -r $ZDOTDIR/.zshrc ]] && source $ZDOTDIR/.zshrc
fi

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

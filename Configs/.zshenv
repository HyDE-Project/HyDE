#!/usr/bin/env zsh
#!          ░▒▓
#!        ░▒▒░▓▓
#!      ░▒▒▒░░░▓▓           ___________
#!    ░░▒▒▒░░░░░▓▓        //___________/
#!   ░░▒▒▒░░░░░▓▓     _   _ _    _ _____
#!   ░░▒▒░░░░░▓▓▓▓▓ | | | | |  | |  __/
#!    ░▒▒░░░░▓▓   ▓▓ | |_| | |_/ /| |___
#!     ░▒▒░░▓▓   ▓▓   \__  |____/ |____/    ▀█ █▀ █░█
#!       ░▒▓▓   ▓▓  //____/                █▄ ▄█ █▀█

# HyDE's ZSH env configuration
# This file is sourced by ZSH on startup
# And ensures that we have an obstruction-free ~/.zshrc file
# This also ensures that the proper HyDE $ENVs are loaded

function command_not_found_handler {
    local purple='\e[1;35m' bright='\e[0;1m' green='\e[1;32m' reset='\e[0m'
    printf "${green}zsh${reset}: command ${purple}NOT${reset} found: ${bright}'%s'${reset}\n" "$1"

    if ! ${PM_COMMAND[@]} -h &>/dev/null; then
        return 127
    fi

    printf "${bright}Searching for packages that provide '${bright}%s${green}'...\n${reset}" "${1}"

    if ! "${PM_COMMAND[@]}" fq "/usr/bin/$1"; then
        printf "${bright}${green}[ ${1} ]${reset} ${purple}NOT${reset} found in the system and no package provides it.\n"
        return 127
    else
        printf "${green}[ ${1} ] ${reset} might be provided by the above packages.\n"
        for entry in $entries; do
            # Assuming the entry already has ANSI color codes, we don't add more colors
            printf "  %s\n" "${entry}"
        done

    fi
    return 127
}

function load_zsh_plugins {
    unset -f load_zsh_plugins
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

# Function to display a slow load warning
# the intention is for hyprdots users who might have multiple zsh initialization
function slow_load_warning {
    local lock_file="/tmp/.hyde_slow_load_warning.lock"
    local load_time=$SECONDS

    # Check if the lock file exists
    if [[ ! -f $lock_file ]]; then
        # Create the lock file
        touch $lock_file

        # Display the warning if load time exceeds the limit
        time_limit=3
        if ((load_time > time_limit)); then
            cat <<EOF
    ⚠️ Warning: Shell startup took more than ${time_limit} seconds. Consider optimizing your configuration.
        1. This might be due to slow plugins, slow initialization scripts.
        2. Duplicate plugins initialization.
            - navigate to ~/.zshrc and remove any 'source ZSH/oh-my-zsh.sh' or
                'source ~/.oh-my-zsh/oh-my-zsh.sh' lines.
            - HyDE already sources the oh-my-zsh.sh file for you.
            - It is important to remove all HyDE related
                configurations from your .zshrc file as HyDE will handle it for you.
            - Check the '.zshrc' file from the repo for a clean configuration.
                https://github.com/HyDE-Project/HyDE/blob/master/Configs/.zshrc
        3. Check the '~/.hyde.zshrc' file for any slow initialization scripts.

    For more information, on the possible causes of slow shell startup, see:
        🌐 https://github.com/HyDE-Project/HyDE/wiki

EOF
        fi
    fi
}

# Function to handle initialization errors
function handle_init_error {
    if [[ $? -ne 0 ]]; then
        echo "Error during initialization. Please check your configuration."
    fi
}

function no_such_file_or_directory_handler {
    local red='\e[1;31m' reset='\e[0m'
    printf "${red}zsh: no such file or directory: %s${reset}\n" "$1"
    return 127
}

function load_persistent_aliases {
    #! Persistent Aliases are loaded after zshrc is loaded you cannot overwrite them
    unset -f load_persistent_aliases

    if [[ -x "$(command -v eza)" ]]; then
        alias l='eza -lh --icons=auto' \
            ll='eza -lha --icons=auto --sort=name --group-directories-first' \
            ld='eza -lhD --icons=auto' \
            lt='eza --icons=auto --tree'
    fi

}

load_zsh_dot_files() {
    local dots
    local dot_dir="${ZDOTDIR:-$HOME}"
    dots=(
        "$dot_dir/.zprofile"
        "$dot_dir/.zshrc"
        "$dot_dir/.zlogin"
        "$dot_dir/.zlogout"
    )

    for dot in "${dots[@]}"; do
        if [[ -f $dot ]]; then
            source "$dot"
        fi
    done

}

# Load oh-my-zsh when line editor initializes // before user input
function load_omz_on_init() {
    if [[ -n $DEFER_OMZ_LOAD ]]; then
        unset DEFER_OMZ_LOAD
        [[ -r $ZSH/oh-my-zsh.sh ]] && source $ZSH/oh-my-zsh.sh

        load_persistent_aliases

        # Load the  .zshrc file
        ZDOTDIR="${__ZDOTDIR}"
        load_zsh_dot_files
        autoload -U compinit && compinit

        # Load hydectl completion
        if command -v hydectl &>/dev/null; then
            compdef _hydectl hydectl
            eval "$(hydectl completion zsh)"
        fi
    fi
}

function load_if_terminal {
    if [ -t 1 ]; then

        unset -f load_if_terminal

        # Currently We are loading Starship and p10k prompts on start so users can see the prompt immediately
        # You can remove either starship or p10k to slightly improve start time

        if command -v starship &>/dev/null; then
            # ===== START Initialize Starship prompt =====
            eval "$(starship init zsh)"
            export STARSHIP_CACHE=$XDG_CACHE_HOME/starship
            export STARSHIP_CONFIG=$XDG_CONFIG_HOME/starship/starship.toml
        # ===== END Initialize Starship prompt =====
        elif [ -r $HOME/.p10k.zsh ]; then
            # ===== START Initialize Powerlevel10k theme =====
            POWERLEVEL10K_TRANSIENT_PROMPT=same-dir
            P10k_THEME=${P10k_THEME:-/usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme}
            [[ -r $P10k_THEME ]] && source $P10k_THEME
            # To customize prompt, run `p10k configure` or edit $HOME/.p10k.zsh
            [[ ! -f $HOME/.p10k.zsh ]] || source $HOME/.p10k.zsh
        # ===== END Initialize Powerlevel10k theme =====
        fi
        # initialize fzf
        if command -v fzf &>/dev/null; then
            eval "$(fzf --zsh)"
        fi

        # Optionally load user configuration // useful for customizing the shell without modifying the main file
        if [[ -f $HOME/.hyde.zshrc ]]; then
            source $HOME/.hyde.zshrc # for backward compatibility
        elif [[ -f $HOME/.user.zsh ]]; then
            source $HOME/.user.zsh # renamed to .user.zsh for intuitiveness that it is a user config
        fi

        # Load plugins
        load_zsh_plugins

        # Load zsh hooks module once

        #? Methods to load oh-my-zsh lazily
        __ZDOTDIR="${ZDOTDIR:-$HOME}"
        readonly __ZDOTDIR
        ZDOTDIR=/tmp
        zle -N zle-line-init load_omz_on_init # Loads when the line editor initializes // The best option

        autoload -Uz add-zsh-hook
        # add-zsh-hook zshaddhistory load_omz_deferred # loads after the first command is added to history
        # add-zsh-hook precmd load_omz_deferred # Loads when shell is ready to accept commands
        # add-zsh-hook preexec load_omz_deferred # Loads before the first command executes

        # TODO: add handlers in pm.sh
        # for these aliases please manually add the following lines to your .zshrc file.(Using yay as the aur helper)
        # pc='yay -Sc' # remove all cached packages
        # po='yay -Qtdq | ${PM_COMMAND[@]} -Rns -' # remove orphaned packages

        # Warn if the shell is slow to load
        add-zsh-hook -Uz precmd slow_load_warning

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
            mkdir='mkdir -p'\ # Always mkdir a path (this doesn't inhibit functionality to make a single dir)

    fi

}

# cleaning up home folder
PATH="$HOME/.local/bin:$PATH"
XDG_CONFIG_DIR="${XDG_CONFIG_DIR:-"$(xdg-user-dir CONFIG)"}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_DATA_DIRS="${XDG_DATA_DIRS:-$XDG_DATA_HOME:/usr/local/share:/usr/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# XDG User Directories
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-"$(xdg-user-dir CONFIG)"}"
XDG_DESKTOP_DIR="${XDG_DESKTOP_DIR:-"$(xdg-user-dir DESKTOP)"}"
XDG_DOWNLOAD_DIR="${XDG_DOWNLOAD_DIR:-"$(xdg-user-dir DOWNLOAD)"}"
XDG_TEMPLATES_DIR="${XDG_TEMPLATES_DIR:-"$(xdg-user-dir TEMPLATES)"}"
XDG_PUBLICSHARE_DIR="${XDG_PUBLICSHARE_DIR:-"$(xdg-user-dir PUBLICSHARE)"}"
XDG_DOCUMENTS_DIR="${XDG_DOCUMENTS_DIR:-"$(xdg-user-dir DOCUMENTS)"}"
XDG_MUSIC_DIR="${XDG_MUSIC_DIR:-"$(xdg-user-dir MUSIC)"}"
XDG_PICTURES_DIR="${XDG_PICTURES_DIR:-"$(xdg-user-dir PICTURES)"}"
XDG_VIDEOS_DIR="${XDG_VIDEOS_DIR:-"$(xdg-user-dir VIDEOS)"}"

LESSHISTFILE=${LESSHISTFILE:-/tmp/less-hist}
PARALLEL_HOME="$XDG_CONFIG_HOME/parallel"
SCREENRC="$XDG_CONFIG_HOME"/screen/screenrc

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
HISTFILE=${HISTFILE:-$HOME/.zsh_history}

# HyDE Package Manager
PM_COMMAND=(hyde-shell pm)

export XDG_CONFIG_HOME XDG_CONFIG_DIR XDG_DATA_HOME XDG_STATE_HOME \
    XDG_CACHE_HOME XDG_DESKTOP_DIR XDG_DOWNLOAD_DIR \
    XDG_TEMPLATES_DIR XDG_PUBLICSHARE_DIR XDG_DOCUMENTS_DIR \
    XDG_MUSIC_DIR XDG_PICTURES_DIR XDG_VIDEOS_DIR \
    SCREENRC ZSH_AUTOSUGGEST_STRATEGY HISTFILE

load_if_terminal

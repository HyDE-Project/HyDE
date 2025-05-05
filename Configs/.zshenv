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

# Function to display a slow load warning
# the intention is for hyprdots users who might have multiple zsh initialization
function _slow_load_warning {
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

function _load_omz_on_init() {
    # Load oh-my-zsh when line editor initializes // before user input
    if [[ -n $DEFER_OMZ_LOAD ]]; then
        unset DEFER_OMZ_LOAD
        [[ -r $ZSH/oh-my-zsh.sh ]] && source $ZSH/oh-my-zsh.sh
        ZDOTDIR="${__ZDOTDIR:-$HOME}"
        _load_post_init
    fi
}

# fzf aliases ever
_fuzzy_change_directory() {
    # Set search directory from argument, default to current directory
    local search_dir="."
    [[ $# -gt 0 && -d "${(e)1}" ]] && search_dir="${(e)1}"

    # Initialize variables for fuzzy search
    local selected_dir
    local max_depth=5 # How deep to search
    local fzf_options=()

    # Configure preview with tree if available, else ls
    if command -v tree &>/dev/null; then
        fzf_options+=(--preview 'tree -C {} | head -200 2>/dev/null')
    elif command -v eza &>/dev/null; then
        fzf_options+=(--preview 'eza -T --color=always {} | head -200 2>/dev/null')
    elif command -v ls &>/dev/null; then
        fzf_options+=(--preview 'ls --color=always -la {} 2>/dev/null')
    fi

    # Add fuzzy matching options to make it more flexible
    fzf_options+=(
        --height "80%"
        --layout=reverse
        # Enhanced fuzzy matching
        --exact
        --nth=1
        # Improve scoring for adjacent character matches
        --algo=v2
        --preview-window
        right:60% --cycle
    )

    # Create the progressive depth search command
    local search_cmd='
        query={q}
        if [[ -n "$query" ]]; then
            # First add parent directories for quick navigation
            echo "../"
            echo "../.."
            echo "../../.."
            
            # Level 1 (current directory)
            find '$search_dir' -maxdepth 1 -type d \
                 | grep -i "$query" 2>/dev/null
                
            # Level 2
            find '$search_dir' -mindepth 2 -maxdepth 2 -type d \
                 | grep -i "$query" 2>/dev/null
                
            # Level 3
            find '$search_dir' -mindepth 3 -maxdepth 3 -type d \
                 | grep -i "$query" 2>/dev/null
                
            # Level 4+
            find '$search_dir' -mindepth 4 -type d \
                 | grep -i "$query" 2>/dev/null
        else
            # Default: list parent directories first
            echo "../"
            echo "../.."
            echo "../../.."
            
            # Then list all directories up to depth 3
            find '$search_dir' -type d \
                -maxdepth 3 2>/dev/null
        fi || echo ""
    '

    # Set up fzf with both start and change events
    fzf_options+=(
        --bind "start:reload:$search_cmd"
        --bind "change:reload:sleep 0.1; $search_cmd"
        --ansi --phony
    )

    # Start with an empty list - will be populated by start event
    selected_dir=$(echo "" | fzf ${fzf_options[@]} 2>/dev/null)

    # Change to the selected directory if valid
    if [[ -n "$selected_dir" && -d "$selected_dir" ]]; then
        cd "$selected_dir" || return 1 #  if cd fails
    else
        echo "No directory selected or invalid directory." >&2
        return 1
    fi
}

_fuzzy_edit_search_file() {
    # Parse arguments
    local content_search=false
    local use_regex=false
    local args=()
    local search_dir="."
    local search_term=""

    # Parse command arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
        --content)
            content_search=true
            shift
            ;;
        --regex)
            use_regex=true
            shift
            ;;
        -d | --dir)
            search_dir="$2"
            shift 2
            ;;
        *)
            # Collect remaining args
            args+=("$1")
            shift
            ;;
        esac
    done

    # Set search term from first arg if available
    [[ ${#args[@]} -gt 0 ]] && search_term="${args[0]}"

    # Initialize variables
    local selected_file
    local max_search_depth=5 # How deep to search
    local fzf_options=()

    # Configure preview
    if command -v bat &>/dev/null; then
        fzf_options+=(--preview 'bat --color=always --style=numbers --line-range :500 {} 2>/dev/null')
    elif command -v cat &>/dev/null; then
        fzf_options+=(--preview 'cat {} 2>/dev/null')
    fi

    # Add fuzzy matching options to make it more flexible
    fzf_options+=(
        --height "80%"
        --layout=reverse
        # Enhanced fuzzy matching
        --exact
        --nth=1
        # Improve scoring for adjacent character matches
        --algo=v2
        --preview-window
        right:60% --cycle
    )

    # If search term is provided, add it as initial query
    [[ -n "$search_term" ]] && fzf_options+=(--query="$search_term")

    # Set grep options based on regex flag
    local grep_options="-i"                        # Default to case-insensitive
    [[ "$use_regex" = true ]] && grep_options="-E" # Use extended regex if --regex flag is set

    # Create the search command based on the mode (content or filename)
    if [[ "$content_search" = true ]]; then
        # Content search mode
        if [[ -n "$search_term" ]]; then
            # If search term provided, use grep directly with exclusions
            selected_file=$(grep -l --include="*" $grep_options -r "$search_term" "$search_dir" 2>/dev/null |
                fzf ${fzf_options[@]} 2>/dev/null)
        else
            # Set up fzf with dynamic content search
            fzf_options+=(--bind "change:reload:sleep 0.1; {
                query={q}
                if [[ -n \"\$query\" ]]; then
                    grep -l --include=\"*\" \
                        $grep_options -r \"\$query\" \"$search_dir\" 2>/dev/null || echo ''
                else
                    find '$search_dir' -type f -maxdepth 3 2>/dev/null
                fi
            }"
                --ansi --phony)

            # Start with an empty list - will be populated by change event
            selected_file=$(echo "" | fzf ${fzf_options[@]} 2>/dev/null)
        fi
    else
        # Filename search mode (existing functionality)
        # Adjust grep command based on regex flag
        local grep_cmd=""
        if [[ "$use_regex" = true ]]; then
            grep_cmd="grep -E"
        else
            grep_cmd="grep -i"
        fi

        local search_cmd='
            query={q}
            if [[ -n "$query" ]]; then
                # Progressive depth search only when there is a query
                # Level 1 (current directory)
                find '$search_dir' -maxdepth 1 -type f 2>/dev/null | '"$grep_cmd"' "$query" 2>/dev/null
                    
                # Level 2
                find '$search_dir' -mindepth 2 -maxdepth 2 -type f 2>/dev/null | '"$grep_cmd"' "$query" 2>/dev/null
                    
                # Level 3
                find '$search_dir' -mindepth 3 -maxdepth 3 -type f 2>/dev/null | '"$grep_cmd"' "$query" 2>/dev/null
                    
                # Level 4+
                find '$search_dir' -mindepth 4 -type f 2>/dev/null | '"$grep_cmd"' "$query" 2>/dev/null
            else
                # If no query, list all files recursively
                find '$search_dir' -type f -maxdepth 3 2>/dev/null
            fi || echo ""
        '

        # Set up fzf with both start and change events
        fzf_options+=(
            --bind "start:reload:$search_cmd"
            --bind "change:reload:sleep 0.1; $search_cmd"
            --ansi --phony
        )

        # Start with an empty list
        selected_file=$(echo "" | fzf ${fzf_options[@]} 2>/dev/null)
    fi

    # Open selected file with editor
    if [[ -n "$selected_file" && -f "$selected_file" ]]; then
        if command -v "$EDITOR" &>/dev/null; then
            "$EDITOR" "$selected_file"
        elif command -v nvim &>/dev/null; then
            nvim "$selected_file"
        elif command -v vim &>/dev/null; then
            vim "$selected_file"
        elif command -v vi &>/dev/null; then
            vi "$selected_file"
        elif command -v nano &>/dev/null; then
            nano "$selected_file"
        else
            echo "EDITOR is not specified. set 'EDITOR' in your ~/.zshrc file, e.g. 'export EDITOR=nano"
        fi
    else
        echo "No file selected." >&2
        return 1
    fi
}

function _load_post_init() {
    #! Never load time consuming functions here
    _load_persistent_aliases
    autoload -U compinit && compinit

    # Load hydectl completion
    if command -v hydectl &>/dev/null; then
        compdef _hydectl hydectl
        eval "$(hydectl completion zsh)"
    fi

    # Initiate fzf
    if command -v fzf &>/dev/null; then
        eval "$(fzf --zsh)"
    fi

    # User rc file always overrides
    [[ -f $HOME/.zshrc ]] && source $HOME/.zshrc

}

function _load_if_terminal {
    if [ -t 1 ]; then

        unset -f _load_if_terminal

        # Currently We are loading Starship and p10k prompts on start so users can see the prompt immediately

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

        # Optionally load user configuration // useful for customizing the shell without modifying the main file
        if [[ -f $HOME/.hyde.zshrc ]]; then
            source $HOME/.hyde.zshrc # for backward compatibility
        elif [[ -f $HOME/.user.zsh ]]; then
            source $HOME/.user.zsh # renamed to .user.zsh for intuitiveness that it is a user config
        fi

        # Load plugins
        _load_zsh_plugins

        # Load zsh hooks module once

        #? Methods to load oh-my-zsh lazily
        __ZDOTDIR="${ZDOTDIR:-$HOME}"
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

        # Warn if the shell is slow to load
        add-zsh-hook -Uz precmd _slow_load_warning

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
            mkdir='mkdir -p' \
            ffec='_fuzzy_edit_search_file --content' \
            ffcd='_fuzzy_change_directory' \
            ffe='_fuzzy_edit_search_file'

    fi

}

#? Override this environment variable in ~/.zshrc

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

# History configuration // explicit to not nuke history
HISTFILE=${HISTFILE:-$HOME/.zsh_history}
HISTSIZE=10000
SAVEHIST=10000
setopt EXTENDED_HISTORY       # Write the history file in the ':start:elapsed;command' format
setopt INC_APPEND_HISTORY     # Write to the history file immediately, not when the shell exits
setopt SHARE_HISTORY          # Share history between all sessions
setopt HIST_EXPIRE_DUPS_FIRST # Expire a duplicate event first when trimming history
setopt HIST_IGNORE_DUPS       # Do not record an event that was just recorded again
setopt HIST_IGNORE_ALL_DUPS   # Delete an old recorded event if a new event is a duplicate

# HyDE Package Manager
PM_COMMAND=(hyde-shell pm)

export XDG_CONFIG_HOME XDG_CONFIG_DIR XDG_DATA_HOME XDG_STATE_HOME \
    XDG_CACHE_HOME XDG_DESKTOP_DIR XDG_DOWNLOAD_DIR \
    XDG_TEMPLATES_DIR XDG_PUBLICSHARE_DIR XDG_DOCUMENTS_DIR \
    XDG_MUSIC_DIR XDG_PICTURES_DIR XDG_VIDEOS_DIR \
    SCREENRC ZSH_AUTOSUGGEST_STRATEGY HISTFILE

_load_if_terminal

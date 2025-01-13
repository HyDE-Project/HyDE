#!          ░▒▓         
#!        ░▒▒░▓▓         
#!      ░▒▒▒░░░▓▓           ___________
#!    ░░▒▒▒░░░░░▓▓        //___________/
#!   ░░▒▒▒░░░░░▓▓     _   _ _    _ _____
#!   ░░▒▒░░░░░▓▓▓▓▓▓ | | | | |  | |  __/
#!    ░▒▒░░░░▓▓   ▓▓ | |_| | |_/ /| |___
#!     ░▒▒░░▓▓   ▓▓   \__  |____/ |____/    ▀█ █▀ █░█
#!       ░▒▓▓   ▓▓  //____/                █▄ ▄█ █▀█

# HyDE's ZSH env configuration
# This file is sourced by ZSH on startup
# And ensures that we have an obstruction free ~/.zshrc file
# This also ensures that the proper HyDE $ENVs are loaded


# Command not found handler
function command_not_found_handler {
    local purple='\e[1;35m' bright='\e[0;1m' green='\e[1;32m' reset='\e[0m'
    printf 'zsh: command not found: %s\n' "$1"
    local entries=( ${(f)"$(/usr/bin/pacman -F --machinereadable -- "/usr/bin/$1")"} )
    if (( ${#entries[@]} > 0 )); then
        printf "${bright}$1${reset} may be found in the following packages:\n"
        local pkg
        for entry in "${entries[@]}"; do
            local fields=( ${(0)entry} )
            if [[ "$pkg" != "${fields[2]}" ]]; then
                printf "${purple}%s/${bright}%s ${green}%s${reset}\n" "${fields[1]}" "${fields[2]}" "${fields[3]}"
            fi
            printf '    /%s\n' "${fields[4]}"
            pkg="${fields[2]}"
        done
    fi
    return 127
}

function load_zsh_plugins {
# Oh-my-zsh installation path
zsh_paths=(
    "$HOME/.oh-my-zsh"
    "/usr/local/share/oh-my-zsh"
    "/usr/share/oh-my-zsh"
)
for zsh_path in "${zsh_paths[@]}"; do [[ -d $zsh_path ]] && export ZSH=$zsh_path && break; done
# Load Plugins
hyde_plugins=( git zsh-256color zsh-autosuggestions zsh-syntax-highlighting )
plugins+=( "${plugins[@]}" "${hyde_plugins[@]}" git zsh-256color zsh-autosuggestions zsh-syntax-highlighting)
# Deduplicate plugins
plugins=("${plugins[@]}")
plugins=($(printf "%s\n" "${plugins[@]}" | sort -u))

# Loads om-my-zsh
[[ -r $ZSH/oh-my-zsh.sh ]] && source $ZSH/oh-my-zsh.sh
}

# Install packages from both Arch and AUR
function in {
local -a inPkg=("$@")
local -a arch=()
local -a aur=()

for pkg in "${inPkg[@]}"; do
if pacman -Si "${pkg}" &>/dev/null; then
arch+=("${pkg}")
else
aur+=("${pkg}")
fi
done

if [[ ${#arch[@]} -gt 0 ]]; then
sudo pacman -S "${arch[@]}"
fi

if [[ ${#aur[@]} -gt 0 ]]; then
${aurhelper} -S "${aur[@]}"
fi
}

# Function to display a slow load warning
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
        4. Check the '~/.p10k.zsh' file for any slow initialization scripts.

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

# Function to remove the lock file on exit
function cleanup {
    rm -f /tmp/.hyde_slow_load_warning.lock
}

function no_such_file_or_directory_handler {
    local red='\e[1;31m' reset='\e[0m'
    printf "${red}zsh: no such file or directory: %s${reset}\n" "$1"
    return 127
}

# We are loading the prompt on start so users can see the prompt immediately
# Powerlevel10k theme path
P10k_THEME=${P10k_THEME:-/usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme}
[[ -r $P10k_THEME ]] && source $P10k_THEME

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Detect AUR wrapper and cache it for faster subsequent loads
aur_cache_file="/tmp/.aurhelper.zshrc"
if [[ -f $aur_cache_file ]]; then
    aurhelper=$(<"$aur_cache_file")
else
    if pacman -Qi yay &>/dev/null; then
        aurhelper="yay"
    elif pacman -Qi paru &>/dev/null; then
        aurhelper="paru"
    fi
    echo "$aurhelper" > "$aur_cache_file"
fi


# Optionally load user configuration // usefull for customizing the shell without modifying the main file
[[ -f ~/.hyde.zshrc ]] && source ~/.hyde.zshrc

# Load plugins
load_zsh_plugins

# Warn if the shell is slow to load
autoload -Uz add-zsh-hook
add-zsh-hook -Uz precmd slow_load_warning
# add-zsh-hook zshexit cleanup


# Helpful aliases
if [[ -x "$(which eza)" ]]; then
    alias ls='eza' \
        l='eza -lh --icons=auto' \
        ll='eza -lha --icons=auto --sort=name --group-directories-first' \
        ld='eza -lhD --icons=auto' \
        lt='eza --icons=auto --tree'
fi

alias c='clear' \
    un='$aurhelper -Rns' \
    up='$aurhelper -Syu' \
    pl='$aurhelper -Qs' \
    pa='$aurhelper -Ss' \
    pc='$aurhelper -Sc' \
    po='$aurhelper -Qtdq | $aurhelper -Rns -' \
    vc='code' \
    fastfetch='fastfetch --logo-type kitty' \
    ..='cd ..' \
    ...='cd ../..' \
    .3='cd ../../..' \
    .4='cd ../../../..' \
    .5='cd ../../../../..' \
    mkdir='mkdir -p' # Always mkdir a path (this doesn't inhibit functionality to make a single dir)


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
        3. Check the '~/.user.zsh' file for any slow initialization scripts.

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

# ------------------------------------------------------------

# # Warn if the shell is slow to load
# add-zsh-hook -Uz precmd _slow_load_warning #! try to not use for now as we already move zshrc

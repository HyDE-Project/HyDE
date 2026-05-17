# Fish completion for hallwayde-shell

function __hallwayde_shell_get_commands
    echo "--help
help
-h
-r
reload
wallbash
--version
version
-v
--release-notes
release-notes
--list-script
--list-script-path
--completions"
    
    # Get hallwayde scripts
    if command -v hallwayde-shell >/dev/null 2>&1
        hallwayde-shell --list-script 2>/dev/null | sed 's/\.[^.]*$//'
    end
end

function __hallwayde_shell_get_wallbash_scripts
    # Just --help for now
    echo "--help"
end

# Main completions
complete -c hallwayde-shell -f

# First argument completions
complete -c hallwayde-shell -n "not __fish_seen_subcommand_from (__hallwayde_shell_get_commands)" -a "(__hallwayde_shell_get_commands)" -d "Hyde shell commands"

# Wallbash subcommand completions
complete -c hallwayde-shell -n "__fish_seen_subcommand_from wallbash" -a "(__hallwayde_shell_get_wallbash_scripts)" -d "Wallbash scripts"

# Completions subcommand
complete -c hallwayde-shell -n "__fish_seen_subcommand_from --completions" -a "bash zsh fish" -d "Shell completion types"

# Option descriptions
complete -c hallwayde-shell -s h -l help -d "Display help message"
complete -c hallwayde-shell -s r -d "Reload HyDE"
complete -c hallwayde-shell -s v -l version -d "Show version information"
complete -c hallwayde-shell -l release-notes -d "Show release notes"
complete -c hallwayde-shell -l list-script -d "List available scripts"
complete -c hallwayde-shell -l list-script-path -d "List scripts with full paths"
complete -c hallwayde-shell -l completions -d "Generate shell completions"

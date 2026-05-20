# Fish completion for doorwayde-shell

function __doorwayde_shell_get_commands
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
    
    # Get doorwayde scripts
    if command -v doorwayde-shell >/dev/null 2>&1
        doorwayde-shell --list-script 2>/dev/null | sed 's/\.[^.]*$//'
    end
end

function __doorwayde_shell_get_wallbash_scripts
    # Just --help for now
    echo "--help"
end

# Main completions
complete -c doorwayde-shell -f

# First argument completions
complete -c doorwayde-shell -n "not __fish_seen_subcommand_from (__doorwayde_shell_get_commands)" -a "(__doorwayde_shell_get_commands)" -d "Hyde shell commands"

# Wallbash subcommand completions
complete -c doorwayde-shell -n "__fish_seen_subcommand_from wallbash" -a "(__doorwayde_shell_get_wallbash_scripts)" -d "Wallbash scripts"

# Completions subcommand
complete -c doorwayde-shell -n "__fish_seen_subcommand_from --completions" -a "bash zsh fish" -d "Shell completion types"

# Option descriptions
complete -c doorwayde-shell -s h -l help -d "Display help message"
complete -c doorwayde-shell -s r -d "Reload HyDE"
complete -c doorwayde-shell -s v -l version -d "Show version information"
complete -c doorwayde-shell -l release-notes -d "Show release notes"
complete -c doorwayde-shell -l list-script -d "List available scripts"
complete -c doorwayde-shell -l list-script-path -d "List scripts with full paths"
complete -c doorwayde-shell -l completions -d "Generate shell completions"

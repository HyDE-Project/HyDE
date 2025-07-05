# Fish completion for hyde-shell

function __hyde_shell_get_commands
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
    
    # Get hyde scripts
    if command -v hyde-shell >/dev/null 2>&1
        hyde-shell --list-script 2>/dev/null | sed 's/\.[^.]*$//'
    end
end

function __hyde_shell_get_wallbash_scripts
    # Just --help for now
    echo "--help"
end

# Main completions
complete -c hyde-shell -f

# First argument completions
complete -c hyde-shell -n "not __fish_seen_subcommand_from (__hyde_shell_get_commands)" -a "(__hyde_shell_get_commands)" -d "Hyde shell commands"

# Wallbash subcommand completions
complete -c hyde-shell -n "__fish_seen_subcommand_from wallbash" -a "(__hyde_shell_get_wallbash_scripts)" -d "Wallbash scripts"

# Completions subcommand
complete -c hyde-shell -n "__fish_seen_subcommand_from --completions" -a "bash zsh fish" -d "Shell completion types"

# Option descriptions
complete -c hyde-shell -s h -l help -d "Display help message"
complete -c hyde-shell -s r -d "Reload HyDE"
complete -c hyde-shell -s v -l version -d "Show version information"
complete -c hyde-shell -l release-notes -d "Show release notes"
complete -c hyde-shell -l list-script -d "List available scripts"
complete -c hyde-shell -l list-script-path -d "List scripts with full paths"
complete -c hyde-shell -l completions -d "Generate shell completions"

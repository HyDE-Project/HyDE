# Fish completion for hyde-shell

function __hyde_shell_get_commands
    set -l result (hyde-shell completion --list-all 2>/dev/null | string split '\n')
    if test -z "$result"
        set -l hyde_bin (command -s hyde-shell 2>/dev/null)
        set -l lib_dir ""
        if set -q hyde_bin[1]
            set lib_dir (command python3 -c "import os; b=os.path.realpath('$hyde_bin'); print(os.path.realpath(os.path.join(os.path.dirname(b),'..','lib','hyde')))" 2>/dev/null)
        end
        if set -q lib_dir[1]; and test -f "$lib_dir/completions.py"
            set result (python3 "$lib_dir/completions.py" --list-all 2>/dev/null | string split '\n')
        end
    end
    for line in $result
        echo $line
    end
end

function __hyde_shell_get_commands_desc
    set -l result (hyde-shell completion --list-all-desc 2>/dev/null | string split '\n')
    if test -z "$result"
        set -l hyde_bin (command -s hyde-shell 2>/dev/null)
        set -l lib_dir ""
        if set -q hyde_bin[1]
            set lib_dir (command python3 -c "import os; b=os.path.realpath('$hyde_bin'); print(os.path.realpath(os.path.join(os.path.dirname(b),'..','lib','hyde')))" 2>/dev/null)
        end
        if set -q lib_dir[1]; and test -f "$lib_dir/completions.py"
            set result (python3 "$lib_dir/completions.py" --list-all-desc 2>/dev/null | string split '\n')
        end
    end
    for line in $result
        echo $line
    end
end

function __hyde_shell_get_scripts_desc
    set -l result (hyde-shell completion --list-script-desc 2>/dev/null | string split '\n')
    if test -z "$result"
        set -l hyde_bin (command -s hyde-shell 2>/dev/null)
        set -l lib_dir ""
        if set -q hyde_bin[1]
            set lib_dir (command python3 -c "import os; b=os.path.realpath('$hyde_bin'); print(os.path.realpath(os.path.join(os.path.dirname(b),'..','lib','hyde')))" 2>/dev/null)
        end
        if set -q lib_dir[1]; and test -f "$lib_dir/completions.py"
            set result (python3 "$lib_dir/completions.py" --list-script-desc 2>/dev/null | string split '\n')
        end
    end
    for line in $result
        echo $line
    end
end

function __hyde_shell_get_subcommands_desc
    set -l cmd $argv[1]
    set -l result (hyde-shell completion --list-commands-desc "$cmd" 2>/dev/null | string split '\n')
    if test -z "$result"
        set -l hyde_bin (command -s hyde-shell 2>/dev/null)
        set -l lib_dir ""
        if set -q hyde_bin[1]
            set lib_dir (command python3 -c "import os; b=os.path.realpath('$hyde_bin'); print(os.path.realpath(os.path.join(os.path.dirname(b),'..','lib','hyde')))" 2>/dev/null)
        end
        if set -q lib_dir[1]; and test -f "$lib_dir/completions.py"
            set result (python3 "$lib_dir/completions.py" --list-commands-desc "$cmd" 2>/dev/null | string split '\n')
        end
    end
    for line in $result
        echo $line
    end
end

function __hyde_shell_get_options_desc
    set -l cmd $argv[1]
    set -l subcmd $argv[2]
    set -l result (hyde-shell completion --list-options-desc "$cmd" "$subcmd" 2>/dev/null | string split '\n')
    if test -z "$result"
        set -l hyde_bin (command -s hyde-shell 2>/dev/null)
        set -l lib_dir ""
        if set -q hyde_bin[1]
            set lib_dir (command python3 -c "import os; b=os.path.realpath('$hyde_bin'); print(os.path.realpath(os.path.join(os.path.dirname(b),'..','lib','hyde')))" 2>/dev/null)
        end
        if set -q lib_dir[1]; and test -f "$lib_dir/completions.py"
            set result (python3 "$lib_dir/completions.py" --list-options-desc "$cmd" "$subcmd" 2>/dev/null | string split '\n')
        end
    end
    for line in $result
        echo $line
    end
end

function __hyde_shell_get_flags_desc
    set -l cmd $argv[1]
    set -l subcmd $argv[2]
    set -l result (hyde-shell completion --list-flags-desc "$cmd" "$subcmd" 2>/dev/null | string split '\n')
    if test -z "$result"
        set -l hyde_bin (command -s hyde-shell 2>/dev/null)
        set -l lib_dir ""
        if set -q hyde_bin[1]
            set lib_dir (command python3 -c "import os; b=os.path.realpath('$hyde_bin'); print(os.path.realpath(os.path.join(os.path.dirname(b),'..','lib','hyde')))" 2>/dev/null)
        end
        if set -q lib_dir[1]; and test -f "$lib_dir/completions.py"
            set result (python3 "$lib_dir/completions.py" --list-flags-desc "$cmd" "$subcmd" 2>/dev/null | string split '\n')
        end
    end
    for line in $result
        echo $line
    end
end

function __hyde_shell_no_subcommand
    not __fish_seen_subcommand_from (__hyde_shell_get_commands)
end

complete -c hyde-shell -f -n "__hyde_shell_no_subcommand" \
    -a "(__hyde_shell_get_commands_desc)"

complete -c hyde-shell -f -n "__fish_seen_subcommand_from wallbash" \
    -a "(__hyde_shell_get_scripts_desc)"

complete -c hyde-shell -f -n "__fish_seen_subcommand_from completion; or __fish_seen_subcommand_from completions" \
    -a "--list-builtins" -d "List built-in commands"
complete -c hyde-shell -f -n "__fish_seen_subcommand_from completion; or __fish_seen_subcommand_from completions" \
    -a "--list-script" -d "List available scripts"
complete -c hyde-shell -f -n "__fish_seen_subcommand_from completion; or __fish_seen_subcommand_from completions" \
    -a "--list-script-path" -d "List script paths"
complete -c hyde-shell -f -n "__fish_seen_subcommand_from completion; or __fish_seen_subcommand_from completions" \
    -a "--list-all" -d "List all autocomplete options"
complete -c hyde-shell -f -n "__fish_seen_subcommand_from completion; or __fish_seen_subcommand_from completions" \
    -a "bash" -d "Output bash completion"
complete -c hyde-shell -f -n "__fish_seen_subcommand_from completion; or __fish_seen_subcommand_from completions" \
    -a "zsh" -d "Output zsh completion"
complete -c hyde-shell -f -n "__fish_seen_subcommand_from completion; or __fish_seen_subcommand_from completions" \
    -a "fish" -d "Output fish completion"
complete -c hyde-shell -f -n "__fish_seen_subcommand_from completion; or __fish_seen_subcommand_from completions" \
    -a "--help" -d "Show completion help"

complete -c hyde-shell -f -n "not __hyde_shell_no_subcommand; and not __fish_seen_subcommand_from wallbash completion completions" \
    -a "(__hyde_shell_get_subcommands_desc (commandline -opc)[2])"

complete -c hyde-shell -f -n "not __hyde_shell_no_subcommand; and not __fish_seen_subcommand_from wallbash completion completions" \
    -a "(__hyde_shell_get_options_desc (commandline -opc)[2] (commandline -opc)[3])"
complete -c hyde-shell -f -n "not __hyde_shell_no_subcommand; and not __fish_seen_subcommand_from wallbash completion completions" \
    -a "(__hyde_shell_get_flags_desc (commandline -opc)[2] (commandline -opc)[3])"

complete -c hyde-shell -s h -l help -d "Show this help message"
complete -c hyde-shell -s r -l reload -d "Reload HyDE assets or environment"
complete -c hyde-shell -s s -l scripts -d "List available scripts"
complete -c hyde-shell -s v -l version -d "Show version information"
complete -c hyde-shell -l release-notes -d "Show latest release notes"
complete -c hyde-shell -l list-script -d "List available script names"
complete -c hyde-shell -l list-script-path -d "List script paths"
complete -c hyde-shell -l list-builtins -d "List built-in commands"

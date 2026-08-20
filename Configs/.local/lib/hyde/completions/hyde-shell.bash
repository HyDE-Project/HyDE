#!/usr/bin/env bash
# Bash completion for hyde-shell

_hyde_shell_completion() {
    local cur prev words cword
    COMPREPLY=()
    _init_completion -n ":" 2>/dev/null || {
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
        cword="${COMP_CWORD}"
    }

    __hyde_shell_run() {
        local result
        result=$(hyde-shell completion "$@" 2>/dev/null)
        if [[ -z "$result" ]]; then
            local hyde_bin lib_dir
            hyde_bin=$(command -v hyde-shell 2>/dev/null)
            if [[ -n "$hyde_bin" ]]; then
                lib_dir=$(python3 -c "
import os
bin_path = os.path.realpath('$hyde_bin')
print(os.path.realpath(os.path.join(os.path.dirname(bin_path), '..', 'lib', 'hyde')))
" 2>/dev/null)
                if [[ -n "$lib_dir" && -f "$lib_dir/completions.py" ]]; then
                    result=$(python3 "$lib_dir/completions.py" "$@" 2>/dev/null)
                fi
            fi
        fi
        echo "$result" | tr '\n' ' '
    }

    if [[ $cword -eq 1 ]]; then
        COMPREPLY=($(compgen -W "$(__hyde_shell_run --list-all)" -- "$cur"))
        return 0
    fi

    if [[ $cword -eq 2 ]]; then
        case "$prev" in
            wallbash)
                COMPREPLY=($(compgen -W "$(__hyde_shell_run --list-script)" -- "$cur"))
                return 0
                ;;
            completion|completions)
                local subs="--list-builtins --list-script --list-script-path --list-all bash zsh fish --help"
                COMPREPLY=($(compgen -W "$subs" -- "$cur"))
                return 0
                ;;
            *)
                local script_cmds
                script_cmds=$(__hyde_shell_run --list-commands "$prev")
                if [[ -n "$script_cmds" ]]; then
                    COMPREPLY=($(compgen -W "$script_cmds" -- "$cur"))
                    return 0
                fi
                ;;
        esac
        return 0
    fi

    if [[ $cword -ge 3 ]]; then
        local cmd="${COMP_WORDS[1]}"
        local subcmd="${COMP_WORDS[2]}"
        local opts
        opts=$(__hyde_shell_run --list-options "$cmd" "$subcmd")
        local flags
        flags=$(__hyde_shell_run --list-flags "$cmd" "$subcmd")
        local all="$opts $flags"
        if [[ -n "$all" ]]; then
            COMPREPLY=($(compgen -W "$all" -- "$cur"))
            return 0
        fi
    fi

    return 0
}

complete -F _hyde_shell_completion hyde-shell

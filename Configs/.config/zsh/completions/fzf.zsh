    # Ctrl-R fzf completio
    if command -v fzf &>/dev/null; then
        eval "$(fzf --zsh)"
    fi

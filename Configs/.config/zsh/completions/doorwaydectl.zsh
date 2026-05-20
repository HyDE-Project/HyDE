    # doorwaydectl tab completion
    if command -v doorwaydectl &>/dev/null; then
        compdef _doorwaydectl doorwaydectl
        eval "$(doorwaydectl completion zsh)"
    fi

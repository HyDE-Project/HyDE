    # hydectl tab completion
    if command -v hydectl &>/dev/null; then
        compdef _hydectl hydectl
        eval "$(hydectl completion zsh)"
    fi

    # hallwaydectl tab completion
    if command -v hallwaydectl &>/dev/null; then
        compdef _hallwaydectl hallwaydectl
        eval "$(hallwaydectl completion zsh)"
    fi

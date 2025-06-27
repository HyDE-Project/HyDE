#!/usr/bin/env zsh

#! ██████╗░░█████╗░  ███╗░░██╗░█████╗░████████╗  ███████╗██████╗░██╗████████╗
#! ██╔══██╗██╔══██╗  ████╗░██║██╔══██╗╚══██╔══╝  ██╔════╝██╔══██╗██║╚══██╔══╝
#! ██║░░██║██║░░██║  ██╔██╗██║██║░░██║░░░██║░░░  █████╗░░██║░░██║██║░░░██║░░░
#! ██║░░██║██║░░██║  ██║╚████║██║░░██║░░░██║░░░  ██╔══╝░░██║░░██║██║░░░██║░░░
#! ██████╔╝╚█████╔╝  ██║░╚███║╚█████╔╝░░░██║░░░  ███████╗██████╔╝██║░░░██║░░░
#! ╚═════╝░░╚════╝░  ╚═╝░░╚══╝░╚════╝░░░░╚═╝░░░  ╚══════╝╚═════╝░╚═╝░░░╚═╝░░░

# Let HyDE immediately load prompts
# For now supported prompts are Starship and Powerlevel10k (p10k)

# Exit early if HYDE_ZSH_PROMPT is not set to 1
if [[ "${HYDE_ZSH_PROMPT}" != "1" ]]; then
    return
fi

if command -v starship &>/dev/null; then
    # ===== START Initialize Starship prompt =====
    eval "$(starship init zsh)"
    export STARSHIP_CACHE=$XDG_CACHE_HOME/starship
    export STARSHIP_CONFIG=$XDG_CONFIG_HOME/starship/starship.toml
# ===== END Initialize Starship prompt =====
elif [ -r $HOME/.p10k.zsh ] || [ -r $ZDOTDIR/.p10k.zsh ]; then
    # ===== START Initialize Powerlevel10k theme =====
    POWERLEVEL10K_TRANSIENT_PROMPT=same-dir
    P10k_THEME=${P10k_THEME:-/usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme}
    [[ -r $P10k_THEME ]] && source $P10k_THEME
    # To customize prompt, run `p10k configure` or edit $HOME/.p10k.zsh
    if [[ -f $HOME/.p10k.zsh ]]; then
        source $HOME/.p10k.zsh
    elif [[ -f $ZDOTDIR/.p10k.zsh ]]; then
        source $ZDOTDIR/.p10k.zsh
    fi
# ===== END Initialize Powerlevel10k theme =====
fi

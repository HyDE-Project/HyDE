#   Overrides 
# HYDE_ZSH_NO_PLUGINS=1 # Set to 1 to disable loading of oh-my-zsh plugins, useful if you want to use your zsh plugins system
# unset HYDE_ZSH_PROMPT # Uncomment to unset/disable loading of prompts from HyDE and let you load your own prompts
# HYDE_ZSH_COMPINIT_CHECK=1 # Set 24 (hours) per compinit security check // lessens startup time
# HYDE_ZSH_OMZ_DEFER=1 # Set to 1 to defer loading of oh-my-zsh plugins ONLY if prompt is already loaded

# Personal command-line tools migrated from the pre-HyDE ~/.zshrc.
# Keep prompt and Oh My Zsh initialization under HyDE; only restore environment paths here.
typeset -U path PATH

export BUN_INSTALL="$HOME/.bun"
export VOLTA_HOME="$HOME/.volta"
export PNPM_HOME="$HOME/.local/share/pnpm"

path=(
    "$HOME/.local/bin"
    "$BUN_INSTALL/bin"
    "$VOLTA_HOME/bin"
    "$PNPM_HOME/bin"
    "$PNPM_HOME"
    $path
)

if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
fi

if [[ "$TERM_PROGRAM" == "kiro" ]] && command -v kiro >/dev/null; then
    . "$(kiro --locate-shell-integration-path zsh)"
fi

if [[ ${HYDE_ZSH_NO_PLUGINS} != "1" ]]; then
    #  OMZ Plugins 
    # manually add your oh-my-zsh plugins here
    plugins=(
        "sudo"
    )
fi

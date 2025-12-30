#  Startup 
# Commands to execute on startup (before the prompt is shown)
# Check if the interactive shell option is set

#   Overrides 
# HYDE_ZSH_NO_PLUGINS=1 # Set to 1 to disable loading of oh-my-zsh plugins, useful if you want to use your zsh plugins system 
# unset HYDE_ZSH_PROMPT # Uncomment to unset/disable loading of prompts from HyDE and let you load your own prompts
# HYDE_ZSH_COMPINIT_CHECK=1 # Set 24 (hours) per compinit security check // lessens startup time
# HYDE_ZSH_OMZ_DEFER=1 # Set to 1 to defer loading of oh-my-zsh plugins ONLY if prompt is already loaded

unset HYDE_ZSH_PROMPT # Uncomment to unset/disable loading of prompts from HyDE and let you load your own prompts
HYDE_ZSH_COMPINIT_CHECK=24 # Set 24 (hours) per compinit security check // lessens startup time

ZSH_THEME=""
DISABLE_AUTO_TITLE="true"
DISABLE_UPDATE_PROMPT="true"
VSCODE_INJECTION=1

if [[ ${HYDE_ZSH_NO_PLUGINS} != "1" ]]; then
    #  OMZ Plugins 
    # manually add your oh-my-zsh plugins here
    plugins=(
        "sudo"
        "copyfile"
        "copypath"
        "zsh-256color"
        "zsh-autosuggestions"
        "zsh-syntax-highlighting"
        "zsh-completions"
        "zsh-history-substring-search"
        "fzf-tab"
        "autoupdate"
    )
fi

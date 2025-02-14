nerdfetch
set -g fish_greeting

if status is-interactive
    starship init fish | source
end

# List Directory
alias l='eza -lh  --icons=auto' # long list
alias ls='eza -1   --icons=auto' # short list
alias ll='eza -lha --icons=auto --sort=name --group-directories-first' # long list all
alias ld='eza -lhD --icons=auto' # long list dirs
alias lt='eza --icons=auto --tree' # list folder as tree

# Handy change dir shortcuts
abbr .. 'cd ..'
abbr ... 'cd ../..'
abbr .3 'cd ../../..'
abbr .4 'cd ../../../..'
abbr .5 'cd ../../../../..'

# Always mkdir a path (this doesn't inhibit functionality to make a single dir)
abbr mkdir 'mkdir -p'


#NIX ALIASES
alias hms='home-manager switch'
alias ns='nix-store --gc'
alias nsall='nix-collect-garbage -d'
alias nel='nix-env -q'
alias neg='nix-env --list-generations'
alias hmg='home-manager generations'
alias hmp='home-manager packages'

fzf --fish | source


# Custom Aliases
alias v='nvim'
alias vi='nvim'
alias va='vim'
alias cat='bat'
#alias nix='fish'
alias 'e.'='exit'
alias fast='fastfetch'

#NIX ALIASES
alias hms='home-manager switch'
alias ns='nix-store --gc'
alias nsall='nix-collect-garbage -d'
alias nel='nix-env -q'
alias neg='nix-env --list-generations'
alias hmg='home-manager generations'
alias hmp='home-manager packages'
alias nx='cd /home/zaryu/GitHub/hyprnix'
alias sddmbg='cd /usr/share/sddm/themes/sequoia/backgrounds'
alias gdir='cd /home/zaryu/GitHub'

#GIT ALIASES
alias ga='git add .'
alias gc='git commit -m'
alias gpm='git push -u origin main'
alias gpms='git push -u origin master'
alias gs='git status'
alias gl='git log'


# FZF
alias see='fzf --preview="bat --color=always {}"'
alias seevi='vi $(fzf --preview="bat --color=always {}")'

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix"
export FZF_DEFAULT_OPTS="--height 70% --layout=reverse --border --color=hl:#2dd4bf"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always -n --line-range :500 {}' --bind 'enter:execute(nvim {})'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

alias fy="wtype -M ctrl t"

export PATH="$PATH:/home/zaryu/ZHALL_ABSTRACT/UsefulCMD"

set -g fish_greeting

source ~/.config/fish/conf.d/hyde.fish
source ~/.config/fish/user.fish



if type -q starship
    starship init fish | source
    set -gx STARSHIP_CACHE $XDG_CACHE_HOME/starship
    set -gx STARSHIP_CONFIG $XDG_CONFIG_HOME/starship/starship.toml
end


if type -q duf
    function df -d "Run duf with last argument if valid, else run duf"
        if set -q argv[-1] && test -e $argv[-1]
            duf $argv[-1]
        else
            duf
        end
    end
end

# fzf
if type -q fzf
    fzf --fish | source
    for file in ~/.config/fish/functions/fzf/*.fish
        source $file
        # NOTE: these functions are built on top of fzf builtin widgets
        # they help you navigate through directories and files "Blazingly" fast
        # to get help on each one, just type `ff` in terminal and press `TAB`
        # keep in mind all of them require an argument to be passed after the alias
    end
end

# NOTE: binds Alt+n to inserting the nth command from history in edit buffer
# e.g. Alt+4 is same as pressing Up arrow key 4 times
# really helpful if you get used to it
bind_M_n_history

set fish_pager_color_prefix cyan
set fish_color_autosuggestion brblack

if type -q eza
    # List Directory
    alias l='eza -lh  --icons=auto' # long list
    alias ls='eza -1   --icons=auto' # short list
    alias ll='eza -lha --icons=auto --sort=name --group-directories-first' # long list all
    alias ld='eza -lhD --icons=auto' # long list dirs
    alias lt='eza --icons=auto --tree' # list folder as tree
    alias vc='code'
end

if type -q bat
    abbr -a --position anywhere -- --help '--help | bat --language=help --style=plain --paging=never --color always'
    abbr -a --position anywhere -- -h '-h | bat --language=help --style=plain --paging=never --color always'
    abbr cat 'bat --style=plain --paging=never --color auto'
end

alias c='clear'
alias un='$aurhelper -Rns'
alias up='$aurhelper -Syu'
alias pl='$aurhelper -Qs'
alias pa='$aurhelper -Ss'
alias pc='$aurhelper -Sc'
alias po='$aurhelper -Qtdq | $aurhelper -Rns -'
alias vc='code'
alias fastfetch='fastfetch --logo-type kitty'

# Directory navigation shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'

abbr mkdir 'mkdir -p'







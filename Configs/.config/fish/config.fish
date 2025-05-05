set -g fish_greeting

source ~/.config/fish/hyde_config.fish

if type -q starship
    starship init fish | source
    set -gx STARSHIP_CACHE $XDG_CACHE_HOME/starship
    set -gx STARSHIP_CONFIG $XDG_CONFIG_HOME/starship/starship.toml
end


# fzf 
if type -q fzf
    fzf --fish | source 
end

function ffcd
    set initial_query
    set max_depth 7
    if set -q argv[1]
        set initial_query $argv[1]
    end

    set fzf_options '--preview=ls -p {} | grep /' \
                    '--preview-window=right:60%' \
                    '--height' '80%' \
                    '--layout=reverse' \
                    '--preview-window' 'right:60%' \
                    '--cycle'

    if set -q initial_query
        set fzf_options $fzf_options "--query=$initial_query"
    end


    set selected_dir (find . -maxdepth $max_depth \( -name .git -o -name node_modules -o -name .venv -o -name target -o -name .cache \) -prune -o -type d -print 2>/dev/null | fzf $fzf_options)

    if test -n "$selected_dir"; and test -d "$selected_dir"
        cd "$selected_dir"; or return 1
    else
        return 1
    end
end



function ffe
    set initial_query
    if set -q argv[1]
        set initial_query $argv[1]
    end

    set fzf_options '--height' '80%' \
                    '--layout' 'reverse' \
                    '--preview-window' 'right:60%' \
                    '--cycle'

    if set -q initial_query
        set fzf_options $fzf_options "--query=$initial_query"
    end

    set max_depth 5

    set selected_file (find . -maxdepth $max_depth -type f 2>/dev/null | fzf $fzf_options)

    if test -n "$selected_file"; and test -f "$selected_file"
        nvim "$selected_file"
    else
        return 1
    end
end


function ffe
    set initial_query
    if set -q argv[1]
        set initial_query $argv[1]
    end

    set fzf_options '--height' '80%' \
                    '--layout' 'reverse' \
                    '--preview-window' 'right:60%' \
                    '--cycle'

    if set -q initial_query
        set fzf_options $fzf_options "--query=$initial_query"
    end

    set max_depth 5

    set selected_file (find . -maxdepth $max_depth -type f 2>/dev/null | fzf $fzf_options)

    if test -n "$selected_file"; and test -f "$selected_file"
        nvim "$selected_file"
    else
        return 1
    end
end

function ffec
    set grep_pattern ""
    if set -q argv[1]
        set grep_pattern $argv[1]
    end

    set fzf_options '--height' '80%' \
                    '--layout' 'reverse' \
                    '--preview-window' 'right:60%' \
                    '--cycle' \
                    '--preview' 'bat --color always {}' \
                    '--preview-window' 'right:60%'

    set selected_file (grep -irl -- "$grep_pattern" ./ 2>/dev/null | fzf $fzf_options)

    if test -n "$selected_file"
        nvim "$selected_file"
    else
        echo "No file selected or search returned no results."
    end
end





# example integration with bat : <cltr+f>
# bind -M insert \ce '$EDITOR $(fzf --preview="bat --color=always --plain {}")' 


set fish_pager_color_prefix cyan
set fish_color_autosuggestion brblack 

# List Directory
alias l='eza -lh  --icons=auto' # long list
alias ls='eza -1   --icons=auto' # short list
alias ll='eza -lha --icons=auto --sort=name --group-directories-first' # long list all
alias ld='eza -lhD --icons=auto' # long list dirs
alias lt='eza --icons=auto --tree' # list folder as tree
alias vc='code'

# Handy change dir shortcuts
abbr .. 'cd ..'
abbr ... 'cd ../..'
abbr .3 'cd ../../..'
abbr .4 'cd ../../../..'
abbr .5 'cd ../../../../..'

# Always mkdir a path (this doesn't inhibit functionality to make a single dir)
abbr mkdir 'mkdir -p'

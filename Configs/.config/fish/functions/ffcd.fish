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

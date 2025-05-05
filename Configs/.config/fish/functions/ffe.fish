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

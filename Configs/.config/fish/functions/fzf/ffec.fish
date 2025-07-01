function ffec -d "Fuzzy search by file content and open in Editor"
    set grep_pattern ""
    if set -q argv[1]
        set grep_pattern $argv[1]
    end

    set fzf_options '--height' '80%' \
                    '--layout' 'reverse' \
                    '--preview-window' 'right:60%' \
                    '--cycle' \
                    '--preview' 'bat cat {}' \
                    '--preview-window' 'right:60%'

    set selected_file (grep -irl -- "$grep_pattern" ./ 2>/dev/null | fzf $fzf_options)

    if test -n "$selected_file"
        cd (dirname $selected_file)
        nvim (basename $selected_file)
    else
        echo "No file selected or search returned no results."
    end
end

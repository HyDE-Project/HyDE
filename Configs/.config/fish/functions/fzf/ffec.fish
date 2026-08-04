function ffec -d "Fuzzy search by file content and open in Editor"
    set grep_pattern ""
    if set -q argv[1]
        set grep_pattern $argv[1]
    end

    set preview_cmd ""
    if type -q bat
        set preview_cmd "'bat --color always --style=plain --paging=never {}'"
    else
        set preview_cmd "'cat {}'"
    end

    set fzf_options '--height' '80%' \
                    '--layout' 'reverse' \
                    '--cycle' \
                    '--preview-window' 'right:60%' \
                    "--preview $preview_cmd"

    set selected_file (grep -irl -- "$grep_pattern" ./ 2>/dev/null | fzf $fzf_options)

    if test -n "$selected_file"
        set editor (_hyde_editor)
        if test -z "$editor"
            echo "No editor found. Install one, or set EDITOR in ~/.config/fish/user.fish."
            return 1
        end
        cd (dirname $selected_file)
        $editor (basename $selected_file)
    else
        echo "No file selected or search returned no results."
    end
end

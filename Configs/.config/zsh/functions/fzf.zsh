
# best fzf aliases ever
_fuzzy_change_directory() {
    local initial_query="$1"
    local selected_dir
    local fzf_options=('--preview=ls -p {}' '--preview-window=right:60%')
    fzf_options+=(--height "80%" --layout=reverse --preview-window right:60% --cycle)
    local max_depth=7

    if [[ -n "$initial_query" ]]; then
        fzf_options+=("--query=$initial_query")
    fi

    #type -d
    selected_dir=$(find . -maxdepth $max_depth \( -name .git -o -name node_modules -o -name .venv -o -name target -o -name .cache \) -prune -o -type d -print 2>/dev/null | fzf "${fzf_options[@]}")

    if [[ -n "$selected_dir" && -d "$selected_dir" ]]; then
        cd "$selected_dir" || return 1
    else
        return 1
    fi
}

_fuzzy_edit_search_file_content() {
    # [f]uzzy [e]dit  [s]earch [f]ile [c]ontent
    local selected_file
    local fzf_options=()
    local preview_cmd
    if command -v "bat" &>/dev/null; then
        preview_cmd="'bat --color always --style=plain --paging=never {}'"
    else
        preview_cmd="'cat {}'"
    fi
    fzf_options+=(--height "80%" --layout=reverse --cycle --preview-window right:60% --preview $preview_cmd)
    selected_file=$(grep -irl "${1:-}" ./ | fzf "${fzf_options[@]}")

    if [[ -n "$selected_file" ]]; then
        if command -v "$EDITOR" &>/dev/null; then
            "$EDITOR" "$selected_file"
        else
            echo "EDITOR is not specified. using vim.  (you can export EDITOR in ~/.zshrc)"
            vim "$selected_file"
        fi

    else
        echo "No file selected or search returned no results."
    fi
}

_fuzzy_edit_search_file() {
    local initial_query="$1"
    local selected_file
    local fzf_options=()
    fzf_options+=(--height "80%" --layout=reverse --preview-window right:60% --cycle)
    local max_depth=5

    if [[ -n "$initial_query" ]]; then
        fzf_options+=("--query=$initial_query")
    fi

    # -type f: only find files
    selected_file=$(find . -maxdepth $max_depth -type f 2>/dev/null | fzf "${fzf_options[@]}")

    if [[ -n "$selected_file" && -f "$selected_file" ]]; then
        if command -v "$EDITOR" &>/dev/null; then
            "$EDITOR" "$selected_file"
        else
            echo "EDITOR is not specified. using vim.  (you can export EDITOR in ~/.zshrc)"
            vim "$selected_file"
        fi
    else
        return 1
    fi
}

alias ffec='_fuzzy_edit_search_file_content' \
ffcd='_fuzzy_change_directory' \
ffe='_fuzzy_edit_search_file'

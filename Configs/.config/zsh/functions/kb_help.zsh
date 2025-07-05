# TODO: I am describing every step as shell syntaxes are worst.
# Define a Zsh widget to append '--help' to the current command and execute it, but allow natural use of `?` when the buffer is insignificant
function append_help_and_run() {
    if [[ -n $BUFFER ]]; then
        # Check if the buffer contains only spaces
        if [[ -z "${BUFFER// }" ]]; then
            zle self-insert
            return
        fi

        # Check if the cursor is inside quotes
        local before_cursor="${BUFFER:0:$CURSOR}"
        local after_cursor="${BUFFER:$CURSOR}"
        local single_quotes="${BUFFER//[^']}"
        local double_quotes="${BUFFER//[^\"]}"

        # If the cursor is inside quotes (balanced or unbalanced), allow natural use of `?`
        if [[ $before_cursor == *\"* && $after_cursor == *\"* ]] || [[ $before_cursor == *\'* && $after_cursor == *\'* ]]; then
            zle self-insert
            return
        fi

        # If quotes are unbalanced, allow natural use of `?`
        if (( ${#single_quotes} % 2 != 0 || ${#double_quotes} % 2 != 0 )); then
            zle self-insert
            return
        fi

        # If the cursor is surrounded by non-space characters, allow natural use of `?`
        local char_before="${BUFFER:$CURSOR-1:1}"
        local char_after="${BUFFER:$CURSOR:1}"
        if [[ $char_before != " " && -n $char_before ]] || [[ $char_after != " " && -n $char_after ]]; then
            zle self-insert
            return
        fi

        # Append '--help' if not already present
        if [[ $BUFFER != *"--help"* ]]; then
            BUFFER="$BUFFER --help"
        fi
        zle end-of-line
        zle accept-line
    else
        # If the buffer is empty, allow natural use of `?`
        zle self-insert
    fi
}

# Register the widget with Zsh
zle -N append_help_and_run

# Bind `Shift + /` (question mark) to the widget
bindkey '?' append_help_and_run
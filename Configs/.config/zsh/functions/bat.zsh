if command -v "bat" &>/dev/null; then
    alias -g -- -h='-h 2>&1 | bat --language=help --style=plain --paging=never --color always'
    alias -g -- --help='--help 2>&1 | bat --language=help --style=plain --paging=never --color always'
    alias cat='bat --style=plain --paging=never --color auto'
fi

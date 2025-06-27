_df() {
    if [[ $# -ge 1 && -e "${@: -1}" ]]; then
        duf "${@: -1}"
    else
        duf
    fi
}

if command -v "duf" &>/dev/null; then
    alias df='_df'
fi

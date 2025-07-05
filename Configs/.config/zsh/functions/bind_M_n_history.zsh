_insert_history_n_ago() {
  local command

  command=$(fc -ln "-$1" "-$1" 2>/dev/null)
  command=${command##[[:space:]]}

  if [[ -n "$command" ]]; then
    LBUFFER=$command
    zle redisplay
  else
    zle push-input
    echo "No history found for number: $1" >&2
    zle reset-prompt
  fi
}

for i in {1..9}; do
  eval "
    _insert-history-${i}-ago() {
      _insert_history_n_ago $i
    }
  "
  zle -N "_insert-history-${i}-ago"
  bindkey -M emacs "^[${i}" "_insert-history-${i}-ago"
done

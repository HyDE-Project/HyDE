function ffch -d "Fuzzy search through command history"
    set -l -- prompt_query $argv[1]

    set -l -- command_line (commandline)
    set -l -- current_line (commandline -L)
    set -l -- total_lines (count $command_line)
    set -l -- fzf_query (string escape -- $command_line[$current_line])

    if test -n "$prompt_query"
        set fzf_query (string escape -- "$prompt_query")
    end

    set -lx FZF_DEFAULT_OPTS (__fzf_defaults '' \
      '--nth=2..,.. --scheme=history --multi --wrap-sign="\t↳ "' \
      '--bind=\'shift-delete:execute-silent(eval history delete --exact --case-sensitive -- {+})+reload(eval $FZF_DEFAULT_COMMAND)\'' \
      "--bind=ctrl-r:toggle-sort --highlight-line $FZF_CTRL_R_OPTS" \
      '--accept-nth=2.. --read0 --print0 --with-shell='(status fish-path)\\ -c)

    set -lx FZF_DEFAULT_OPTS_FILE
    set -lx FZF_DEFAULT_COMMAND

    if type -q perl
      set -a FZF_DEFAULT_OPTS '--tac'

      # WARN: if you changed the function name from 'ffch' to anything else, make sure you change it in the following line as well
      # "^ffch" -> "YOURNAME"
      # what it does is it excludes the init command form the history results
      set FZF_DEFAULT_COMMAND 'builtin history -z --reverse | command grep -zv "^ffch" | command perl -0 -pe \'s/^/$.\t/g; s/\n/\n\t/gm\''
      
      # NOTE: if you want the initiator command included in the fzf results, uncomment the following line
      # set FZF_DEFAULT_COMMAND 'builtin history -z --reverse | command perl -0 -pe \'s/^/$.\t/g; s/\n/\n\t/gm\''


    else
      set FZF_DEFAULT_COMMAND \
        'set -l h (builtin history -z --reverse | string split0);' \
        'for i in (seq (count $h) -1 1);' \
        'if test "$h[$i]" != "widget";' \
        'string join0 -- $i\t(string replace -a -- \n \n\t $h[$i] | string collect);' \
        'end;' \
        'end'
    end

    test -z "$fish_private_mode"; and builtin history merge

    if set -l result (eval $FZF_DEFAULT_COMMAND \| (__fzfcmd) --query=$fzf_query | string split0)
      if test "$total_lines" -eq 1
        commandline -- (string replace -a -- \n\t \n $result)
      else
        set -l a (math $current_line - 1)
        set -l b (math $current_line + 1)
        commandline -- $command_line[1..$a] (string replace -a -- \n\t \n $result)
        commandline -a -- '' $command_line[$b..-1]
      end
    end

    commandline -f repaint
end


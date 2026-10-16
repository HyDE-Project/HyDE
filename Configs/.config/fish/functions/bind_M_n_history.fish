function bind_M_n_history
    for i in (seq 9)
        set -l command "set -q history[$i] && commandline -r \$history[$i] || echo \"No history found for number $i\""

        if contains fish_vi_key_bindings $fish_key_bindings
            bind -M default \e$i "$command"
            bind -M insert \e$i "$command"
        else
            bind \e$i "$command"
        end
    end
end

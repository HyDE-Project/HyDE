function df
    if test $argv
        set last_arg $argv[-1]
        if test -e "$last_arg"
            duf "$last_arg"
            return
        end
    end

    duf
end

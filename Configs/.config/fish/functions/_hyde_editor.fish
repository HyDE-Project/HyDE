# The editor a selection opens in, discovered rather than chosen. Mirrors
# Configs/.config/zsh/functions/fzf.zsh: the user's own answer first, then an
# order of discovery over what this machine already has. HyDE installs none of
# them.
function _hyde_editor -d "Print the first usable editor on this machine"
    for candidate in $EDITOR $VISUAL nvim vim helix hx nano micro emacs
        if test -n "$candidate"; and type -q -- $candidate
            echo $candidate
            return 0
        end
    end
    return 1
end

set PM "pm.sh"

if not type -q pm.sh
    for path in /usr/lib/hyde /usr/local/lib/hyde $HOME/.local/lib/hyde $HOME/.local/bin
        if test -x "$path/pm.sh"
            set PM "$path/pm.sh"
            break
        end
    end
end

# New function to handle AUR alternatives
function in
    set -l inPkg $argv
    set -l arch
    set -l aur

    for pkg in $inPkg
        if pacman -Si $pkg > /dev/null
            set arch $arch $pkg
        else
            set aur $aur $pkg
        end
    end

    if test (count $arch) -gt 0
        echo "Installing Arch repositories packages: $arch"
        sudo pacman -S $arch
    end

    if test (count $aur) -gt 0
        echo "Installing AUR packages: $aur"
        eval $PM -S $aur
    end
end

# Other existing configurations
set -g fish_greeting

source ~/.config/fish/hyde_config.fish

if status is-interactive
    if command -v starship > /dev/null
        starship init fish | source
    else
        echo "starship is not installed."
    end
end

source ~/.config/fish/alias.fish

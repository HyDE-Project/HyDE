#!/usr/bin/env bash
#|---/ /+---------------------------+---/ /|#
#|--/ /-| Script to configure shell |--/ /-|#
#|-/ /--| Prasanth Rangan           |-/ /--|#
#|/ /---+---------------------------+/ /---|#

scrDir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

flg_DryRun=${flg_DryRun:-0}

# shellcheck disable=SC2154
if chk_list "myShell" "${shlList[@]}"; then
    print_log -sec "SHELL" -stat "detected" "${myShell}"
else
    print_log -sec "SHELL" -err "error" "no shell found..."
    exit 1
fi

# add zsh plugins
if pkg_installed zsh; then

    if ! pkg_installed oh-my-zsh-git; then
        if [[ ! -e "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
            print_log -sec "SHELL" -stat "cloning" "oh-my-zsh"
            [ ${flg_DryRun} -eq 1 ] || if ! sh -c "$(curl -fsSL https://install.ohmyz.sh/)" "" --unattended --keep-zshrc; then
                print_log -err "oh-my-zsh update failed..." "Please resolve this issue manually LATER ..."
                print_log -warn "Continuing" "with existing oh-my-zsh..."
                exit 0
            fi

        else
            print_log -sec "SHELL" -stat "updating" "oh-my-zsh"
            zsh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/upgrade.sh)"
        fi
    fi

    #? Optional: oh-my-zsh
    if (pkg_installed oh-my-zsh-git || [[ -f "${HOME}/.oh-my-zsh/oh-my-zsh.sh" ]]) && [ ${flg_DryRun} -ne 1 ]; then
        zsh_paths=(
            "$HOME/.oh-my-zsh"
            "/usr/local/share/oh-my-zsh"
            "/usr/share/oh-my-zsh"
        )
        for zsh_path in "${zsh_paths[@]}"; do [[ -d $zsh_path ]] && Zsh_Path=$zsh_path && break; done

        # set variables
        Zsh_rc="${ZDOTDIR:-$HOME}/.zshenv"
        Zsh_Path="${Zsh_Path:-$HOME/.oh-my-zsh}"
        Zsh_Plugins="$Zsh_Path/custom/plugins"
        Fix_Completion=""

        # generate plugins from list
        while read -r r_plugin; do
            z_plugin=$(awk -F '/' '{print $NF}' <<<"${r_plugin}")
            if [ "${r_plugin:0:4}" == "http" ] && [ ! -d "${Zsh_Plugins}/${z_plugin}" ]; then
                if [ -w "${Zsh_Plugins}" ]; then
                    git clone "${r_plugin}" "${Zsh_Plugins}/${z_plugin}"
                else
                    sudo git clone "${r_plugin}" "${Zsh_Plugins}/${z_plugin}"
                fi
            fi
            if [ "${z_plugin}" == "zsh-completions" ] && [ "$(grep -c 'fpath+=.*plugins/zsh-completions/src' "${Zsh_rc}")" -eq 0 ]; then
                Fix_Completion='\nfpath+=${ZSH_CUSTOM:-${ZSH:-/usr/share/oh-my-zsh}/custom}/plugins/zsh-completions/src'
            else
                [ -z "${z_plugin}" ] || w_plugin+=" ${z_plugin}"
            fi
        done < <(cut -d '#' -f 1 "${scrDir}/restore_zsh.lst" | sed 's/ //g')

        # update plugin array in zshrc
        print_log -sec "SHELL" -stat "installing" "plugins (${w_plugin} )"
        sed -i "/^hyde_plugins=/c\hyde_plugins=(${w_plugin} )${Fix_Completion}" "${Zsh_rc}"
    else
        if [ "${flg_DryRun}" -eq "1" ]; then
            while read -r r_plugin; do
                z_plugin=$(awk -F '/' '{print $NF}' <<<"${r_plugin}")
                [ -z "${z_plugin}" ] || w_plugin+=" ${z_plugin}"
            done < <(cut -d '#' -f 1 "${scrDir}/restore_zsh.lst" | sed 's/ //g')
            print_log -sec "SHELL" -stat "installing" "plugins (${w_plugin} )"
        else
            print_log -sec "SHELL" -err "error" "oh-my-zsh not installed, skipping plugin installation..."
        fi
    fi
fi

# set shell
if [[ "$(grep "/${USER}:" /etc/passwd | awk -F '/' '{print $NF}')" != "${myShell}" ]]; then
    print_log -sec "SHELL" -stat "change" "shell to ${myShell}..."
    [ ${flg_DryRun} -eq 1 ] || chsh -s "$(which "${myShell}")"
else
    print_log -sec "SHELL" -stat "exist" "${myShell} is already set as shell..."
fi

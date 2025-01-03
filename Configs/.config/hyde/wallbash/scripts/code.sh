#!/usr/bin/env bash

# shellcheck source=$HOME/.local/bin/hyde-shell
# shellcheck disable=SC1091
if ! source "$(which hyde-shell)"; then
    echo "[wallbash] code :: Error: hyde-shell not found."
    echo "[wallbash] code :: Is HyDE installed?"
    exit 1
fi

cacheDir="${cacheDir:-$XDG_CACHE_HOME/hyde}"
# confDir="${confDir:-$XDG_CONFIG_HOME}"
readarray -t codeConf < <(find "$confDir" -mindepth 1 -maxdepth 1 -type d -name "Code*" -o -name "VSCodium*" -o -name "Cursor*" | sort)
readarray -t codeVsix < <(find "$HOME" -mindepth 1 -maxdepth 1 -type d -name ".vscode*" -o -name ".cursor" | sort)
# tmpFile="/tmp/$(id -u)$(basename ${0}).tmp"

#// install  ext
for i in "${!codeVsix[@]}"; do
    [[ -z "${codeVsix[i]}" ]] && continue
    file=$(find "${codeVsix[i]}" -type f -path "*extensions/thehydeproject*" -name "wallbash.json")
    if [ -z "${file}" ]; then
        [ -f "${cacheDir}/landing/Code_Wallbash.vsix" ] || curl -L -o "${cacheDir}/landing/Code_Wallbash.vsix" https://github.com/HyDE-Project/code-wallbash/raw/refs/heads/master/release/Code_Wallbash.vsix
        case ${codeVsix[i]} in
        *".cursor"*)
            echo "[wallbashcode] Cursor IDE: Manual intervention required for extension installation."
            echo "[wallbashcode] Read the instructions here: https://www.cursor.com/how-to-install-extension "
            ;;
        *)
            pkg_installed code-insiders && code-insiders --install-extension "${cacheDir}/landing/Code_Wallbash.vsix"
            pkg_installed code && code --install-extension "${cacheDir}/landing/Code_Wallbash.vsix"
            pkg_installed vscodium && vscodium --install-extension "${cacheDir}/landing/Code_Wallbash.vsix"
            echo "[wallbashcode] Installed: in ${codeVsix[i]}"
            ;;
        esac
    fi
done

#// apply theme

cat <<NOTICE
[wallbashcode] To apply the Wallbash theme, open the command palette (Ctrl+Shift+P)
[wallbashcode]  and type "Preferences: Color Theme" and select "Wallbash".
NOTICE

set_theme="${1:-"Wallbash"}"
for i in "${!codeConf[@]}"; do
    [ -d "${codeConf[i]}/User" ] || continue
    [ -f "${codeConf[i]}/User/settings.json" ] || echo -e "{\n \"workbench.colorTheme\":\"Wallbash\" \n}" >"${codeConf[i]}/User/settings.json"
    extTheme="$(
        "$LIB_DIR/hyde/parse.json.py" -CRQ '.["workbench.colorTheme"]' "${codeConf[i]}/User/settings.json"
    )"
    if [ "${extTheme}" != "${set_theme}" ]; then
        "$LIB_DIR/hyde/parse.json.py" -CU '.["workbench.colorTheme"]' "${set_theme}" "${codeConf[i]}/User/settings.json"
        echo "[wallbashcode] Theme set to: ${set_theme} in ${codeConf[i]}"
    #! jq '.["workbench.colorTheme"] = "Wallbash"' "${codeConf[i]}/User/settings.json" >"${tmpFile}" && mv "${tmpFile}" "${codeConf[i]}/User/settings.json" # DEPRECATED
    fi
done

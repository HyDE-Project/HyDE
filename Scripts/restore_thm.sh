#!/usr/bin/env bash

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

THEME_IMPORT_ASYNC=${THEME_IMPORT_ASYNC:-0}
THEME_IMPORT_FILE="${1:-${scrDir}/themepatcher.lst}"
confDir=${confDir:-"$HOME/.config"}
flg_ThemeInstall=${flg_ThemeInstall:-1}
flg_DryRun=${flg_DryRun:-0}
cloneDir=${cloneDir:-"$(dirname "${scrDir}")"}
export PRINT_LOG=false

if [ ! -f "$THEME_IMPORT_FILE" ] || [ -z "$THEME_IMPORT_FILE" ]; then
    print_log -crit "error" "'$THEME_IMPORT_FILE'  No such file or directory"
    exit 1
fi

if [ "$flg_ThemeInstall" -eq 1 ]; then
    print_log -g "[THEME] " -warn "imports" "from List $THEME_IMPORT_FILE"
    while IFS='"' read -r _ themeName _ themeRepo; do
        themeNameQ+=("${themeName//\"/}")
        themeRepoQ+=("${themeRepo//\"/}")
        themePath="${confDir}/hyde/themes/${themeName}"
        [ -d "${themePath}" ] || mkdir -p "${themePath}"
        [ -f "${themePath}/.sort" ] || echo "${#themeNameQ[@]}" >"${themePath}/.sort"

        if [ "${THEME_IMPORT_ASYNC}" -ne 1 ] && [ "${flg_DryRun}" -ne 1 ]; then
            if ! "${cloneDir}/Configs/.local/lib/hyde/theme.patch.sh" "${themeName}" "${themeRepo}" "--skipcaching" "false"; then
                print_log -r "[THEME] " -crit "error" "importing" "${themeName}"
            else
                print_log -g "[THEME] " -stat "added" "${themeName}"
            fi
        else
            print_log -g "[THEME] " -stat "added" "${themeName}"
        fi

    done <"$THEME_IMPORT_FILE"

    if [ "${THEME_IMPORT_ASYNC}" -eq 1 ]; then
        set +e
        parallel --bar --link "\"${cloneDir}/Configs/.local/lib/hyde/theme.patch.sh\"" "{1}" "{2}" "{3}" "{4}" ::: "${themeNameQ[@]}" ::: "${themeRepoQ[@]}" ::: "--skipcaching" ::: "false"
        set -e
    fi
    print_log -y "Run \'hyde-shell reload\' if themes look broken"
fi

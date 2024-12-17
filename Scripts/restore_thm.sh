#!/bin/env bash

scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

THEME_IMPORT_FILE="${1:-${scrDir}/themepatcher.lst}"
confDir=${confDir:-"$HOME/.config"}
flg_ThemeInstall=${flg_ThemeInstall:-1}
flg_DryRun=${flg_DryRun:-0}

if [ ! -f "$THEME_IMPORT_FILE" ] || [ -z "$THEME_IMPORT_FILE" ]; then
    print_log -crit "error" "'$THEME_IMPORT_FILE'  No such file or directory"
    exit 1
fi

if [ "$flg_ThemeInstall" -eq 1 ]; then
    print_log -g "[THEME] " -warn "imports" "from List"
    while IFS='"' read -r _ themeName _ themeRepo; do
        themeNameQ+=("${themeName//\"/}")
        themeRepoQ+=("${themeRepo//\"/}")
        themePath="${confDir}/hyde/themes/${themeName}"
        [ -d "${themePath}" ] || mkdir -p "${themePath}"
        [ -f "${themePath}/.sort" ] || echo "${#themeNameQ[@]}" >"${themePath}/.sort"
        print_log -g "[THEME] " -stat "added" "${themeName}"
    done <"$THEME_IMPORT_FILE"
    set +e
    parallel --bar --link "\"${scrDir}/themepatcher.sh\"" "{1}" "{2}" "{3}" "{4}" ::: "${themeNameQ[@]}" ::: "${themeRepoQ[@]}" ::: "--skipcaching" ::: "false"
    set -e
    print_log -g "[generate] " "cache ::" "Wallpapers..."
fi

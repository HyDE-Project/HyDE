#! /bin/env bash

scrDir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
source "$scrDir/globalcontrol.sh"

PREVIEW=${1}
MESSAGE=${2}

img_preview() {
    if [[ $(tput colors) -lt "256" ]]; then return; fi
    local image_url="${1}"
    [ -z "${image_url}" ] && return 1
    if [ xterm-kitty == "$TERM" ]; then
        kitty icat --clear --transfer-mode=memory --stdin=no --place=100x200@20x2 "$image_url" ||
            kitty icat --clear --transfer-mode=memory --stdin=no "$image_url"
    else
        if command -v jp2a &>/dev/null; then
            find "${image_url}" -name "*" -exec jp2a --colors --color-depth=24 --chars=' .:-=+*#%@' --fill --term-fit --background=dark {} \; 2>/dev/null
        else
            cat <<EOF
          ░▒▒▒░░░░░▓▓          ___________
        ░░▒▒▒░░░░░▓▓        //___________/
       ░░▒▒▒░░░░░▓▓     _   _ _    _ _____
       ░░▒▒░░░░░▓▓▓▓▓▓ | | | | |  | |  __/
        ░▒▒░░░░▓▓   ▓▓ | |_| | |_/ /| |___
         ░▒▒░░▓▓   ▓▓   \__  |____/ |____/
           ░▒▓▓   ▓▓  //____/

EOF
            print_log -y "Install 'jp2a' to preview in ASCII format"
        fi
    fi
}

eval "$(declare -F | sed -e 's/-f /-fx /')"

if [ -n "${MESSAGE}" ]; then
    printf "%b\n" "${MESSAGE}"
fi

if [ -e "${PREVIEW}" ]; then
    img_preview "$PREVIEW"
elif [ ! -e "${PREVIEW}" ]; then
    # echo "${PREVIEW}"
    img_preview "$XDG_CACHE_HOME/hyde/gallery-database/preview.png"
fi

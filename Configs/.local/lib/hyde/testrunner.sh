#!/usr/bin/env bash

scrDir=$(dirname "$(realpath "$0")")
source $scrDir/globalcontrol.sh
rofDir="${confDir}/rofi"

if [ "${1}" == "--verbose" ] || [ "${1}" == "-v" ]; then

    case ${enableWallDcol} in
    0) wallbashStatus="disabled" ;;
    1) wallbashStatus="enabled // auto change based on wallpaper brightness" ;;
    2) wallbashStatus="enabled // dark mode --forced" ;;
    3) wallbashStatus="enabled // light mode --forced" ;;
    esac

    echo -e "\n\ncurrent theme :: \"${HYDE_THEME}\" :: \"$(readlink "${HYDE_THEME_DIR}/wall.set")\""
    echo -e "wallbash status :: ${enableWallDcol} :: ${wallbashStatus}\n"
    get_themes

    for x in "${!thmList[@]}"; do
        echo -e "\nTheme $((x + 1)) :: \${thmList[${x}]}=\"${thmList[x]}\" :: \${thmWall[${x}]}=\"${thmWall[x]}\"\n"
        get_hashmap "$(dirname "${HYDE_THEME_DIR}")/${thmList[x]}" --verbose
        echo -e "\n"
    done

    exit 0
fi

#!/usr/bin/env bash

#// Set variables

scrDir=$(dirname "$(realpath "$0")")
source "${scrDir}/globalcontrol.sh"
scrName="$(basename "$0")"
kmenuPath="$HOME/.local/share/kio/servicemenus"
kmenuDesk="${kmenuPath}/hydewallpaper.desktop"
tgtPath="$(dirname "${HYDE_THEME_DIR}")"
get_themes

#// Evaluate options

while getopts "t:w:" option; do
    case $option in

    t) # Set theme
        for x in "${!thmList[@]}"; do
            if [ "${thmList[x]}" == "$OPTARG" ]; then
                setTheme="${thmList[x]}"
                break
            fi
        done
        [ -z "${setTheme}" ] && echo "Error: '$OPTARG' theme not available..." && exit 1
        ;;

    w) # Set wallpaper
        if [ -f "$OPTARG" ] && file --mime-type "$OPTARG" | grep -q 'image/'; then
            setWall="$OPTARG"
        else
            echo "Error: '$OPTARG' is not an image file..."
            exit 1
        fi
        ;;

    *) # Refresh menu
        unset setTheme
        unset setWall
        ;;

    esac
done

#// Regenerate desktop

if [ ! -z "${setTheme}" ] && [ ! -z "${setWall}" ]; then

    inwallHash="$(set_hash "${setWall}")"
    get_hashmap "${tgtPath}/${setTheme}"
    if [[ "${wallHash[@]}" == *"${inwallHash}"* ]]; then
        notify-send -a "HyDE Notify" -i "${thmbDir}/${inwallHash}.sqre" "Error" "Hash matched in ${setTheme}"
        exit 0
    fi

    cp "${setWall}" "${tgtPath}/${setTheme}/wallpapers"
    ln -fs "${tgtPath}/${setTheme}/wallpapers/$(basename "${setWall}")" "${tgtPath}/${setTheme}/wall.set"

    "${scrDir}/themeswitch.sh" -s "${setTheme}"
    notify-send -a "HyDE Alert" -i "${thmbDir}/${inwallHash}.sqre" "Wallpaper set in ${setTheme}"

else

    echo -e "[Desktop Entry]\nType=Service\nMimeType=image/png;image/jpeg;image/jpg;image/gif\nActions=Menu-Refresh$(printf ";%s" "${thmList[@]}")\nX-KDE-Submenu=Set As Wallpaper...\n\n[Desktop Action Menu-Refresh]\nName=.: Refresh List :.\nExec=${scrName}" >"${kmenuDesk}"
    for i in "${!thmList[@]}"; do
        echo -e "\n[Desktop Action ${thmList[i]}]\nName=${thmList[i]}\nExec=${scrName} -t \"${thmList[i]}\" -w %u" >>"${kmenuDesk}"
    done

fi

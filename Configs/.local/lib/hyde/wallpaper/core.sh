#!/usr/bin/env bash

Wall_Change() {
    curWall="$(set_hash "$wallSet")"
    for i in "${!wallHash[@]}"; do
        if [ "$curWall" == "${wallHash[i]}" ]; then
            if [ "$1" == "n" ]; then
                setIndex=$(((i + 1) % ${#wallList[@]}))
            elif [ "$1" == "p" ]; then
                setIndex=$((i - 1))
            fi
            break
        fi
    done
    Wall_Cache "${wallList[setIndex]}"
}
Wall_Json() {
    setIndex=0
    [ ! -d "$HYDE_THEME_DIR" ] && echo "ERROR: \"$HYDE_THEME_DIR\" does not exist" && exit 0
    if [ -d "$HYDE_THEME_DIR/wallpapers" ]; then
        wallPathArray=("$HYDE_THEME_DIR/wallpapers")
    else
        wallPathArray=("$HYDE_THEME_DIR")
    fi
    wallPathArray+=("${WALLPAPER_CUSTOM_PATHS[@]}")
    [ -d "${XDG_PICTURES_DIR%/}/Wallpapers/${HYDE_THEME}" ] && wallPathArray+=("${XDG_PICTURES_DIR%/}/Wallpapers/${HYDE_THEME}")
    get_hashmap "${wallPathArray[@]}"
    wallListJson=$(printf '%s\n' "${wallList[@]}" | jq -R . | jq -s .)
    wallHashJson=$(printf '%s\n' "${wallHash[@]}" | jq -R . | jq -s .)
    jq -n --argjson wallList "$wallListJson" --argjson wallHash "$wallHashJson" --arg cacheHome "${HYDE_CACHE_HOME:-$HOME/.cache/hyde}" '
        [range(0; $wallList | length) as $i |
            {
                path: $wallList[$i],
                hash: $wallHash[$i],
                basename: ($wallList[$i] | split("/") | last),
                thmb: "\($cacheHome)/thumbs/\($wallHash[$i]).thmb",
                sqre: "\($cacheHome)/thumbs/\($wallHash[$i]).sqre",
                blur: "\($cacheHome)/thumbs/\($wallHash[$i]).blur",
                quad: "\($cacheHome)/thumbs/\($wallHash[$i]).quad",
                dcol: "\($cacheHome)/dcols/\($wallHash[$i]).dcol",
                rofi_sqre: "\($wallList[$i] | split("/") | last):::\($wallList[$i]):::\($cacheHome)/thumbs/\($wallHash[$i]).sqre\u0000icon\u001f\($cacheHome)/thumbs/\($wallHash[$i]).sqre",
                rofi_thmb: "\($wallList[$i] | split("/") | last):::\($wallList[$i]):::\($cacheHome)/thumbs/\($wallHash[$i]).thmb\u0000icon\u001f\($cacheHome)/thumbs/\($wallHash[$i]).thmb",
                rofi_blur: "\($wallList[$i] | split("/") | last):::\($wallList[$i]):::\($cacheHome)/thumbs/\($wallHash[$i]).blur\u0000icon\u001f\($cacheHome)/thumbs/\($wallHash[$i]).blur",
                rofi_quad: "\($wallList[$i] | split("/") | last):::\($wallList[$i]):::\($cacheHome)/thumbs/\($wallHash[$i]).quad\u0000icon\u001f\($cacheHome)/thumbs/\($wallHash[$i]).quad",

            }
        ]
    '
}

Wall_Hash() {
    setIndex=0
    [ ! -d "$HYDE_THEME_DIR" ] && echo "ERROR: \"$HYDE_THEME_DIR\" does not exist" && exit 0
    wallPathArray=("$HYDE_THEME_DIR/wallpapers")
    wallPathArray+=("${WALLPAPER_CUSTOM_PATHS[@]}")
    get_hashmap "${wallPathArray[@]}"
    [ ! -e "$(readlink -f "$wallSet")" ] && echo "Fixing link :: $wallSet" && ln -fs "${wallList[setIndex]}" "$wallSet"
}

Wall_Cache() {
    if [[ ${WALLPAPER_RELOAD_ALL:-1} -eq 1 ]] && [[ $wallpaper_setter_flag != "link" ]]; then
        print_log -sec "wallpaper" "Reloading themes and wallpapers"
        export reload_flag=1
    fi
    ln -fs "${wallList[setIndex]}" "$wallSet"
    ln -fs "${wallList[setIndex]}" "$wallCur"
    if [ "$set_as_global" == "true" ]; then
        print_log -sec "wallpaper" "Setting Wallpaper as global"
        "$LIB_DIR/hyde/wallpaper/cache.sh" commence -w "${wallList[setIndex]}" &> /dev/null
        "$LIB_DIR/hyde/color.set.sh" "${wallList[setIndex]}" &
        ln -fs "$thmbDir/${wallHash[setIndex]}.sqre" "$wallSqr"
        ln -fs "$thmbDir/${wallHash[setIndex]}.thmb" "$wallTmb"
        ln -fs "$thmbDir/${wallHash[setIndex]}.blur" "$wallBlr"
        ln -fs "$thmbDir/${wallHash[setIndex]}.quad" "$wallQad"
        ln -fs "$dcolDir/${wallHash[setIndex]}.dcol" "$wallDcl"
    fi
}

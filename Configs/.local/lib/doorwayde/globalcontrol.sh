#!/usr/bin/env bash
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DOORWAYDE_CONFIG_HOME="$XDG_CONFIG_HOME/doorwayde"
export DOORWAYDE_DATA_HOME="$XDG_DATA_HOME/doorwayde"
export DOORWAYDE_CACHE_HOME="$XDG_CACHE_HOME/doorwayde"
export DOORWAYDE_STATE_HOME="$XDG_STATE_HOME/doorwayde"
export DOORWAYDE_RUNTIME_DIR="$XDG_RUNTIME_DIR/doorwayde"
export ICONS_DIR="$XDG_DATA_HOME/icons"
export FONTS_DIR="$XDG_DATA_HOME/fonts"
export THEMES_DIR="$XDG_DATA_HOME/themes"
export scrDir="${LIB_DIR:-$HOME/.local/lib}/doorwayde"
export confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
export doorwaydeConfDir="$DOORWAYDE_CONFIG_HOME"
export cacheDir="$DOORWAYDE_CACHE_HOME"
export thmbDir="$DOORWAYDE_CACHE_HOME/thumbs"
export dcolDir="$DOORWAYDE_CACHE_HOME/dcols"
export iconsDir="$ICONS_DIR"
export themesDir="$THEMES_DIR"
export fontsDir="$FONTS_DIR"
export hashMech="sha1sum"

send_notifs() {
    local args=("$@")
    notify-send "${args[@]}" &
}
print_log() {
    [[ "${PRINT_LOG}" == "false" ]] && return 0
    while (("$#")); do
        case "$1" in
        -r | +r)
            echo -ne "\e[31m$2\e[0m" >&2
            shift 2
            ;;
        -g | +g)
            echo -ne "\e[32m$2\e[0m" >&2
            shift 2
            ;;
        -y | +y)
            echo -ne "\e[33m$2\e[0m" >&2
            shift 2
            ;;
        -b | +b)
            echo -ne "\e[34m$2\e[0m" >&2
            shift 2
            ;;
        -m | +m)
            echo -ne "\e[35m$2\e[0m" >&2
            shift 2
            ;;
        -c | +c)
            echo -ne "\e[36m$2\e[0m" >&2
            shift 2
            ;;
        -wt | +w)
            echo -ne "\e[37m$2\e[0m" >&2
            shift 2
            ;;
        -n | +n)
            echo -ne "\e[96m$2\e[0m" >&2
            shift 2
            ;;
        -stat)
            echo -ne "\e[4;30;46m $2 \e[0m :: " >&2
            shift 2
            ;;
        -crit)
            echo -ne "\e[30;41m $2 \e[0m :: " >&2
            shift 2
            ;;
        -warn)
            echo -ne "WARNING :: \e[30;43m $2 \e[0m :: " >&2
            shift 2
            ;;
        +)
            echo -ne "\e[38;5;$2m$3\e[0m" >&2
            shift 3
            ;;
        -sec)
            echo -ne "\e[32m[$2] \e[0m" >&2
            shift 2
            ;;
        -err)
            echo -ne "ERROR :: \e[4;31m$2 \e[0m" >&2
            shift 2
            ;;
        *)
            echo -ne "$1" >&2
            shift
            ;;
        esac
    done
    echo "" >&2
}


get_hashmap() {
    unset wallHash
    unset wallList
    unset skipStrays
    unset filetypes
    list_extensions() {
        supported_files=(
            "gif"
            "jpg"
            "jpeg"
            "png"
            "${WALLPAPER_FILETYPES[@]}")
        if [ -n "$WALLPAPER_OVERRIDE_FILETYPES" ]; then
            supported_files=("${WALLPAPER_OVERRIDE_FILETYPES[@]}")
        fi
        printf -- '-iname "*.%s" -o ' "${supported_files[@]}" | sed 's/ -o $//'
    }
    list_skipped_path() {
        local skip_path=(
            "*/logo/*")
        printf -- '! -path "%s" ' "${skip_path[@]}" | sed 's/ $//'
    }
    find_wallpapers() {
        local wallSource="$1"
        if [ -z "$wallSource" ]; then
            print_log -err "ERROR: wallSource is empty"
            return 1
        fi
        local find_command
        find_command="find -H \"$wallSource\" -type f \\( $(list_extensions) \\) $(list_skipped_path) -exec \"$hashMech\" {} +"
        [ "$LOG_LEVEL" == "debug" ] && print_log -g "DEBUG:" -b "Running command:" "$find_command"
        tmpfile=$(mktemp)
        eval "$find_command" 2>"$tmpfile" | sort -k2
        error_output=$(<"$tmpfile") && rm -f "$tmpfile"
        [ -n "$error_output" ] && print_log -err "ERROR:" -b "found an error: " -r "$error_output" -y " skipping..."
    }
    for wallSource in "$@"; do
        [ "$LOG_LEVEL" == "debug" ] && print_log -g "DEBUG:" -b "wallpaper source path:" "$wallSource"
        [ -z "$wallSource" ] && continue
        [ "$wallSource" == "--no-notify" ] && no_notify=1 && continue
        [ "$wallSource" == "--skipstrays" ] && skipStrays=1 && continue
        [ "$wallSource" == "--verbose" ] && verboseMap=1 && continue
        wallSource="$(realpath "$wallSource")"
        [ -e "$wallSource" ] || {
            print_log -err "ERROR:" -b "wallpaper source does not exist:" "$wallSource" -y " skipping..."
            continue
        }
        [ "$LOG_LEVEL" == "debug" ] && print_log -g "DEBUG:" -b "wallSource path:" "$wallSource"
        hashMap=$(find_wallpapers "$wallSource")
        if [ -z "$hashMap" ]; then
            no_wallpapers+=("$wallSource")
            print_log -warn "No compatible wallpapers found in: " "$wallSource"
            continue
        fi
        while read -r hash image; do
            wallHash+=("$hash")
            wallList+=("$image")
        done <<<"$hashMap"
    done
    if [ "${#no_wallpapers[@]}" -gt 0 ]; then
        print_log -warn "No compatible wallpapers found in:" "${no_wallpapers[*]}"
    fi
    if [ -z "${#wallList[@]}" ] || [[ ${#wallList[@]} -eq 0 ]]; then
        if [[ $skipStrays -eq 1 ]]; then
            return 1
        else
            echo "ERROR: No image found in any source"
            [ -n "$no_notify" ] && notify-send -a "DOORwayDE Alert" "WARNING: No compatible wallpapers found in: ${no_wallpapers[*]}"
            exit 1
        fi
    fi
    if [[ $verboseMap -eq 1 ]]; then
        echo "// Hash Map //"
        for indx in "${!wallHash[@]}"; do
            echo ":: \${wallHash[$indx]}=\"${wallHash[indx]}\" :: \${wallList[$indx]}=\"${wallList[indx]}\""
        done
    fi
}
get_themes() {
    unset thmSortS
    unset thmListS
    unset thmWallS
    unset thmSort
    unset thmList
    unset thmWall
    while read -r thmDir; do
        local realWallPath
        realWallPath="$(readlink "$thmDir/wall.set")"
        if [ ! -e "$realWallPath" ]; then
            get_hashmap "$thmDir" --skipstrays || continue
            echo "fixing link :: $thmDir/wall.set"
            ln -fs "${wallList[0]}" "$thmDir/wall.set"
        fi
        [ -f "$thmDir/.sort" ] && thmSortS+=("$(head -1 "$thmDir/.sort")") || thmSortS+=("0")
        thmWallS+=("$realWallPath")
        thmListS+=("${thmDir##*/}")
    done < <(find -H "$DOORWAYDE_CONFIG_HOME/themes" -mindepth 1 -maxdepth 1 -type d)
    while IFS='|' read -r sort theme wall; do
        thmSort+=("$sort")
        thmList+=("$theme")
        thmWall+=("$wall")
    done < <(paste -d '|' <(printf "%s\n" "${thmSortS[@]}") <(printf "%s\n" "${thmListS[@]}") <(printf "%s\n" "${thmWallS[@]}") | sort -n -k 1 -k 2)
    if [ "$1" == "--verbose" ]; then
        echo "// Theme Control //"
        for indx in "${!thmList[@]}"; do
            echo -e ":: \${thmSort[$indx]}=\"${thmSort[indx]}\" :: \${thmList[$indx]}=\"${thmList[indx]}\" :: \${thmWall[$indx]}=\"${thmWall[indx]}\""
        done
    fi
}
export_doorwayde_config() {
    local user_conf_state="$XDG_STATE_HOME/doorwayde/staterc"
    local user_conf="$XDG_STATE_HOME/doorwayde/config"
    [ -f "$user_conf_state" ] && source "$user_conf_state"
    [ -f "$user_conf" ] && source "$user_conf"
}
export_doorwayde_config
case "$enableWallDcol" in
0 | 1 | 2 | 3) ;;
*) enableWallDcol=0 ;;
esac
if [ -z "$DOORWAYDE_THEME" ] || [ ! -d "$DOORWAYDE_CONFIG_HOME/themes/$DOORWAYDE_THEME" ]; then
    get_themes
    DOORWAYDE_THEME="${thmList[0]}"
fi
DOORWAYDE_THEME_DIR="$DOORWAYDE_CONFIG_HOME/themes/$DOORWAYDE_THEME"
WALLBASH_DIRS=(
    "$XDG_CONFIG_HOME/wallbash"
    "$XDG_CONFIG_HOME/doorwayde/wallbash"
    "$XDG_DATA_HOME/wallbash"
    "$XDG_DATA_HOME/doorwayde/wallbash"
    "/usr/local/share/doorwayde/wallbash"
    "/usr/share/doorwayde/wallbash")
wallbashDirs=("${WALLBASH_DIRS[@]}")
export DOORWAYDE_THEME DOORWAYDE_THEME_DIR WALLBASH_DIRS wallbashDirs enableWallDcol
# Rofi's default theme search path includes $XDG_DATA_HOME/rofi/themes/ but
# not $XDG_DATA_HOME/doorwayde/rofi/themes/, so `-theme style_1` fails to
# resolve until the upstream wallpaper-cache run mirrors the symlinks. Bridge
# them on every shell init so rofi works from a clean install.
if command -v rofi &>/dev/null; then
    if [[ ! $XDG_DATA_DIRS =~ share/doorwayde ]]; then
        mkdir -p "$XDG_DATA_HOME/rofi/themes"
        ln -snf "$XDG_DATA_HOME/doorwayde/rofi/themes"/* "$XDG_DATA_HOME/rofi/themes/"
    fi
fi
if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    hypr_border="$(hyprctl -j getoption decoration:rounding | jq '.int')"
    hypr_width="$(hyprctl -j getoption general:border_size | jq '.int')"
fi
export hypr_border=${hypr_border:-${DOORWAYDE_BORDER_RADIUS:-2}}
export hypr_width=${hypr_width:-${DOORWAYDE_BORDER_WIDTH:-2}}
pkg_installed() {
    local pkgIn=$1
    if command -v "$pkgIn" &>/dev/null; then
        return 0
    elif command -v "flatpak" &>/dev/null && flatpak info "$pkgIn" &>/dev/null; then
        return 0
    elif doorwayde-shell pm.sh pq "$pkgIn" &>/dev/null; then
        return 0
    else
        return 1
    fi
}
get_aurhlpr() {
    if pkg_installed yay; then
        aurhlpr="yay"
    elif pkg_installed paru; then
        aurhlpr="paru"
    fi
}
set_conf() {
    local varName="$1"
    local varData="$2"
    touch "$XDG_STATE_HOME/doorwayde/staterc"
    if [ "$(grep -c "^$varName=" "$XDG_STATE_HOME/doorwayde/staterc")" -eq 1 ]; then
        sed -i "/^$varName=/c$varName=\"$varData\"" "$XDG_STATE_HOME/doorwayde/staterc"
    else
        echo "$varName=\"$varData\"" >>"$XDG_STATE_HOME/doorwayde/staterc"
    fi
}
set_hash() {
    local hashImage="$1"
    "$hashMech" "$hashImage" | awk '{print $1}'
}
check_package() {
    local lock_file="${XDG_RUNTIME_DIR:-/tmp}/doorwayde/__package.lock"
    mkdir -p "${XDG_RUNTIME_DIR:-/tmp}/doorwayde"
    if [ -f "$lock_file" ]; then
        return 0
    fi
    for pkg in "$@"; do
        if ! pkg_installed "$pkg"; then
            print_log -err "Package is not installed" "'$pkg'"
            rm -f "$lock_file"
            exit 1
        fi
    done
    touch "$lock_file"
}
get_hyprConf() {
    local hyArg="$1"
    local file="${2:-"$DOORWAYDE_THEME_DIR/hypr.theme"}"
    local hyVar="$hyArg"
    local hyType=""

    #? Allow optional type hint: e.g., FONT_SIZE[int]
    if [[ "$hyArg" =~ ^([^[]+)\[([a-zA-Z0-9_]+)\]$ ]]; then
        hyVar="${BASH_REMATCH[1]}"
        hyType="${BASH_REMATCH[2]}"
    fi

    #? hyq first (sanitized, then raw), with optional type
    #? hyq cannot handle $FOO and $FOO_BAR so we will impose hints to make it work
    if command -v hyq &>/dev/null; then
        local query="\$$hyVar"
        [ -n "$hyType" ] && query="${query}[${hyType}]"
        local hyq_result
        hyq_result=$(hyq -s --query "$query" "$file" 2>/dev/null)
        if [ -z "$hyq_result" ]; then
            hyq_result=$(hyq --query "$query" "$file" 2>/dev/null)
        fi
        [ -n "$hyq_result" ] && echo "$hyq_result" && return 0
    fi

    local gsVal
    gsVal="$(grep "^[[:space:]]*\$$hyVar\s*=" "$file" | cut -d '=' -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -n "$gsVal" ] && [[ $gsVal != \$* ]] && echo "$gsVal" && return 0
    declare -A gsMap=(
        [GTK_THEME]="gtk-theme"
        [ICON_THEME]="icon-theme"
        [COLOR_SCHEME]="color-scheme"
        [CURSOR_THEME]="cursor-theme"
        [CURSOR_SIZE]="cursor-size"
        [FONT]="font-name"
        [DOCUMENT_FONT]="document-font-name"
        [MONOSPACE_FONT]="monospace-font-name"
        [FONT_SIZE]="font-size"
        [DOCUMENT_FONT_SIZE]="document-font-size"
        [MONOSPACE_FONT_SIZE]="monospace-font-size")
    if [[ -n ${gsMap[$hyVar]} ]]; then
        gsVal="$(awk -F"[\"']" '/^[[:space:]]*exec[[:space:]]*=[[:space:]]*gsettings[[:space:]]*set[[:space:]]*org.gnome.desktop.interface[[:space:]]*'"${gsMap[$hyVar]}"'[[:space:]]*/ {last=$2} END {print last}' "$file")"
    fi
    if [ -z "$gsVal" ] || [[ $gsVal == \$* ]]; then
        case "$hyVar" in
        "CODE_THEME") echo "Wallbash" ;;
        "SDDM_THEME") echo "" ;;
        *) grep "^[[:space:]]*\$default.$hyVar\s*=" \
            "XDG_DATA_HOME/doorwayde/doorwayde.conf" \
            "$XDG_DATA_HOME/doorwayde/hyprland.conf" \
            "/usr/local/share/doorwayde/doorwayde.conf" \
            "/usr/local/share/doorwayde/hyprland.conf" \
            "/usr/share/doorwayde/doorwayde.conf" \
            "/usr/share/doorwayde/hyprland.conf" 2>/dev/null | cut -d '=' -f2 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | head -n 1 ;;
        esac
    else
        echo "$gsVal"
    fi
}
get_rofi_pos() {
    [[ -n $HYPRLAND_INSTANCE_SIGNATURE ]] || return 1
    readarray -t curPos < <(hyprctl cursorpos -j | jq -r '.x,.y')
    eval "$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) |
        "monRes=(\(.width) \(.height) \(.scale) \(.x) \(.y)) offRes=(\(.reserved | join(" ")))"')"
    monRes[2]="${monRes[2]//./}"
    monRes[0]=$((monRes[0] * 100 / monRes[2]))
    monRes[1]=$((monRes[1] * 100 / monRes[2]))
    curPos[0]=$((curPos[0] - monRes[3]))
    curPos[1]=$((curPos[1] - monRes[4]))
    offRes=("${offRes// / }")
    if [ "${curPos[0]}" -ge "$((monRes[0] / 2))" ]; then
        local x_pos="east"
        local x_off="-$((monRes[0] - curPos[0] - offRes[2]))"
    else
        local x_pos="west"
        local x_off="$((curPos[0] - offRes[0]))"
    fi
    if [ "${curPos[1]}" -ge "$((monRes[1] / 2))" ]; then
        local y_pos="south"
        local y_off="-$((monRes[1] - curPos[1] - offRes[3]))"
    else
        local y_pos="north"
        local y_off="$((curPos[1] - offRes[1]))"
    fi
    local coordinates="window{location:$x_pos $y_pos;anchor:$x_pos $y_pos;x-offset:${x_off}px;y-offset:${y_off}px;}"
    echo "$coordinates"

}
paste_string() {
    if ! command -v wtype >/dev/null; then exit 0; fi
    if [ -t 1 ]; then return 0; fi
    ignore_paste_file="$DOORWAYDE_STATE_HOME/ignore.paste"
    if [[ ! -e $ignore_paste_file ]]; then
        cat <<EOF >"$ignore_paste_file"
kitty
org.kde.konsole
terminator
XTerm
Alacritty
xterm-256color
EOF
    fi
    ignore_class=$(echo "$@" | awk -F'--ignore=' '{print $2}')
    [ -n "$ignore_class" ] && echo "$ignore_class" >>"$ignore_paste_file" && print_log -y "[ignore]" "'$ignore_class'" && exit 0
    class=$(hyprctl -j activewindow | jq -r '.initialClass')
    if ! grep -q "$class" "$ignore_paste_file"; then
        hyprctl -q dispatch exec 'wtype -M ctrl V -m ctrl'
    fi
}
is_hovered() {
    data=$(hyprctl --batch -j "cursorpos;activewindow" | jq -s '.[0] * .[1]')
    eval "$(echo "$data" | jq -r '@sh "cursor_x=\(.x) cursor_y=\(.y) window_x=\(.at[0]) window_y=\(.at[1]) window_size_x=\(.size[0]) window_size_y=\(.size[1])"')"
    cursor_x=${cursor_x:-$(jq -r '.x // 0' <<<"$data")}
    cursor_y=${cursor_y:-$(jq -r '.y // 0' <<<"$data")}
    window_x=${window_x:-$(jq -r '.at[0] // 0' <<<"$data")}
    window_y=${window_y:-$(jq -r '.at[1] // 0' <<<"$data")}
    window_size_x=${window_size_x:-$(jq -r '.size[0] // 0' <<<"$data")}
    window_size_y=${window_size_y:-$(jq -r '.size[1] // 0' <<<"$data")}
    if ((cursor_x >= window_x && cursor_x <= window_x + window_size_x && cursor_y >= window_y && cursor_y <= window_y + window_size_y)); then
        return 0
    fi
    return 1
}
toml_write() {
    local config_file=$1
    local group=$2
    local key=$3
    local value=$4
    if ! kwriteconfig6 --file "$config_file" --group "$group" --key "$key" "$value" 2>/dev/null; then
        if ! grep -q "^\[$group\]" "$config_file"; then
            echo -e "\n[$group]\n$key=$value" >>"$config_file"
        elif ! grep -q "^$key=" "$config_file"; then
            sed -i "/^\[$group\]/a $key=$value" "$config_file"
        fi
    fi
}
extract_thumbnail() {
    local x_wall="$1"
    x_wall=$(realpath "$x_wall")
    local temp_image="$2"
    ffmpeg -y -i "$x_wall" -vf "thumbnail,scale=1000:-1" -frames:v 1 -update 1 "$temp_image" &>/dev/null
}
accepted_mime_types() {
    local mime_types_array=$1
    local file=$2
    for mime_type in "${mime_types_array[@]}"; do
        if file --mime-type -b "$file" | grep -q "^$mime_type"; then
            return 0
        else
            print_log -err "File type not supported for this wallpaper backend."
            notify-send -u critical -a "DOORwayDE-Alert" "File type not supported for this wallpaper backend."
        fi
    done
}
dconf_write() {
    local key="$1"
    local value="$2"
    if dconf write "$key" "'$value'"; then
        print_log -sec "dconf" -stat "set" "$key to $value"
    else
        print_log -sec "dconf" -warn "failed to set" "$key"
    fi
}
export -f get_hyprConf get_rofi_pos is_hovered toml_write get_hashmap get_aurhlpr set_conf set_hash check_package get_themes print_log pkg_installed paste_string extract_thumbnail accepted_mime_types dconf_write send_notifs export_doorwayde_config

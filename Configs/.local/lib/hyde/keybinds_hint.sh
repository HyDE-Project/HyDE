#!/usr/bin/env bash
pkill -x rofi && exit
[[ $HYDE_SHELL_INIT -ne 1 ]] && eval "$(hyde-shell init)"
# shellcheck source=/dev/null
source "${LIB_DIR}/hyde/shutils/l10n.sh"
confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
keyconfDir="$confDir/hypr"
kb_hint_conf=("$keyconfDir/hyprland.conf" "$keyconfDir/keybindings.conf" "$keyconfDir/userprefs.conf")
kb_hint_conf+=("${ROFI_KEYBIND_HINT_CONFIG[@]}")
kb_cache="$XDG_RUNTIME_DIR/hyde/keybinds_hint.rofi"

update_keybind_cache() {
    "${LIB_DIR}/hyde/keybinds/hint-hyprland.py" --format rofi > "$kb_cache" && {
        hyde_gettext "Keybind cache updated"
        printf '\n'
    }
}

[ -f "$kb_cache" ] && {
    trap update_keybind_cache EXIT
}
output="$(if
    ! cat "$kb_cache" 2> /dev/null
then
    "${LIB_DIR}/hyde/keybinds/hint-hyprland.py" --format rofi | tee "$kb_cache"
fi)"
wait
if [ -z "$output" ]; then
    notify-send "$(hyde_gettext "Keybind Hint")" "$(hyde_gettext "Initialization failed.")"
    exit 0
fi
if ! command -v rofi &> /dev/null; then
    echo "$output"
    hyde_gettext "rofi not detected. Displaying on terminal instead"
    printf '\n'
    exit 0
fi
hypr_border=${hypr_border:-$(hyprctl -j getoption decoration:rounding | jq '.int')}
hypr_width=${hypr_width:-$(hyprctl -j getoption general:border_size | jq '.int')}
wind_border=$((hypr_border * 3 / 2))
elem_border=$([ "$hypr_border" -eq 0 ] && echo "5" || echo "$hypr_border")
kb_hint_width="$ROFI_KEYBIND_HINT_WIDTH"
kb_hint_height="$ROFI_KEYBIND_HINT_HEIGHT"
kb_hint_line="$ROFI_KEYBIND_HINT_LINE"
r_width="width: ${kb_hint_width:-35em};"
r_height="height: ${kb_hint_height:-35em};"
r_listview="listview { lines: ${kb_hint_line:-13}; }"
r_override="window {$r_height $r_width border: ${hypr_width}px; border-radius: ${wind_border}px;} entry {border-radius: ${elem_border}px;} element {border-radius: ${elem_border}px;} $r_listview "
font_scale="${ROFI_KEYBIND_HINT_SCALE:-$(gsettings get org.gnome.desktop.interface font-name | awk '{gsub(/'\''/,""); print $NF}')}"
[[ $font_scale =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}
font_name=${ROFI_KEYBIND_HINT_FONT:-$ROFI_FONT}
font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
font_name=${font_name:-$(get_hyprConf "FONT")}
font_override="* {font: \"${font_name:-"JetBrainsMono Nerd Font"} $font_scale\";}"
icon_override=$(gsettings get org.gnome.desktop.interface icon-theme | sed "s/'//g")
icon_override="configuration {icon-theme: \"$icon_override\";}"
keybindings_label="$(hyde_gettext "Keybindings")"
keybinds_label="$(hyde_gettext "Keybinds")"
description_label="$(hyde_gettext "Description")"
selected=$(echo -e "$output" | rofi -dmenu -p \
    -theme-str "entry { placeholder: \"\t⌨️ ${keybindings_label} \";}" \
    " ${keybinds_label} \t\tﴕ ${description_label}" \
    -p -i \
    -display-columns 1 \
    -display-column-separator ":::" \
    -theme-str "$font_override" \
    -theme-str "$r_override" \
    -theme-str "$icon_override" \
    -theme "${ROFI_KEYBIND_HINT_STYLE:-clipboard}" | sed 's/.*\s*//')
if [ -z "$selected" ]; then exit 0; fi
dispatch=$(awk -F ':::' '{print $2}' <<< "$selected" | xargs)
arg=$(awk -F ':::' '{print $3}' <<< "$selected" | xargs)
repeat=$(awk -F ':::' '{print $4}' <<< "$selected" | xargs)
RUN() {
    case "$(eval "hyprctl dispatch '$dispatch' '$arg'")" in *"Not enough arguments"*) exec $0 ;; esac
}
if [ -n "$dispatch" ] && [ "$(echo "$dispatch" | wc -l)" -eq 1 ]; then
    if [ "$repeat" = repeat ]; then
        while true; do
            repeat_label="$(hyde_gettext "Repeat")"
            repeat_command=$(echo -e "$repeat_label" | rofi -dmenu -no-custom -p - "$(hyde_gettext "[Enter] repeat; [ESC] exit")" -theme "notification")
            if [ "$repeat_command" = "$repeat_label" ]; then
                RUN
            else
                exit 0
            fi
        done
    else
        RUN
    fi
else
    exec $0
fi

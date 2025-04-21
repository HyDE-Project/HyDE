#!/usr/bin/env bash

#// set variables

scrDir="$(dirname "$(realpath "$0")")"
confDir="${confDir}/config"
# shellcheck source=/dev/null
. "${scrDir}/globalcontrol.sh"
rofiStyle="${rofiStyle:-1}"

if [[ "${rofiStyle}" =~ ^[0-9]+$ ]]; then
    rofi_config="style_${rofiStyle:-1}"
else
    rofi_config="${rofiStyle:-"style_1"}"
fi

rofi_config="${ROFI_LAUNCH_STYLE:-$rofi_config}"

font_scale="${ROFI_LAUNCH_SCALE}"
[[ "${font_scale}" =~ ^[0-9]+$ ]] || font_scale=${ROFI_SCALE:-10}

rofi_args=(
    -show-icons
)

#// rofi action

case "${1}" in
d | --drun)
    r_mode="drun"
    rofi_config="${ROFI_LAUNCH_DRUN_STYLE:-$rofi_config}"
    rofi_args+=("--run-command" "sh -c 'uwsm app -- {cmd} || {cmd}'")
    ;;
w | --window)
    r_mode="window"
    rofi_config="${ROFI_LAUNCH_WINDOW_STYLE:-$rofi_config}"
    ;;
f | --filebrowser)
    r_mode="filebrowser"
    rofi_config="${ROFI_LAUNCH_FILEBROWSER_STYLE:-$rofi_config}"
    ;;
r | --run)
    r_mode="run"
    rofi_config="${ROFI_LAUNCH_RUN_STYLE:-$rofi_config}"
    rofi_args+=("--run-command" "sh -c 'uwsm app -- {cmd} || {cmd}'")
    ;;
h | --help)
    echo -e "$(basename "${0}") [action]"
    echo "d :  drun mode"
    echo "w :  window mode"
    echo "f :  filebrowser mode,"
    echo "r :  run mode"
    exit 0
    ;;
*)
    r_mode="drun"
    ROFI_LAUNCH_DRUN_STYLE="${ROFI_LAUNCH_DRUN_STYLE:-$ROFI_LAUNCH_STYLE}"
    rofi_config="${ROFI_LAUNCH_DRUN_STYLE:-$rofi_config}"
    ;;
esac

#// set overrides
hypr_border="${hypr_border:-10}"
hypr_width="${hypr_width:-2}"
wind_border=$((hypr_border * 3))

if [[ -f "${HYDE_STATE_HOME}/fullscreen_${r_mode}" ]]; then
    hypr_width="0"
    wind_border="0"
fi

[ "${hypr_border}" -eq 0 ] && elem_border="10" || elem_border=$((hypr_border * 2))

mon_data=$(hyprctl -j monitors)
is_vertical=$(jq -e '.[] | select(.focused==true) | if (.transform % 2 == 0) then .width / .height else .height / .width end < 1' <<<"${mon_data}")

if [[ "$is_vertical" == "true" ]]; then
    echo "Monitor is vertical"
fi

r_override="window {border: ${hypr_width}px; border-radius: ${wind_border}px;} element {border-radius: ${elem_border}px;}"

# set font name
font_name=${ROFI_LAUNCH_FONT:-$ROFI_FONT}
font_name=${font_name:-$(get_hyprConf "MENU_FONT")}
font_name=${font_name:-$(get_hyprConf "FONT")}

# set rofi font override
font_override="* {font: \"${font_name:-"JetBrainsMono Nerd Font"} ${font_scale}\";}"

i_override="$(get_hyprConf "ICON_THEME")"
i_override="configuration {icon-theme: \"${i_override}\";}"

rofi_args+=(
    -theme-str "${font_override}"
    -theme-str "${i_override}"
    -theme-str "${r_override}"
    -theme "${rofi_config}"
)

#// launch rofi
rofi -show "${r_mode}" "${rofi_args[@]}" &
disown

#// Set full screen state
#TODO Contributor notes:
#? - Workaround to set the full screen state of rofi dynamically and efficiently.
#? - Avoids invoking rofi twice before rendering.
#? - Checks if the theme has fullscreen set to true after rendering.
#? - Sets the variable accordingly for use on the next launch.

rofi -show "${r_mode}" \
    -show-icons \
    -config "${rofi_config}" \
    -theme-str "${font_override}" \
    -theme-str "${i_override}" \
    -theme-str "${r_override}" \
    -theme "${rofi_config}" \
    -dump-theme |
    { grep -q "fullscreen.*true" && touch "${HYDE_STATE_HOME}/fullscreen_${r_mode}"; } || rm -f "${HYDE_STATE_HOME}/fullscreen_${r_mode}"

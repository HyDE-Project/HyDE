#!/usr/bin/env bash

#// set variables

scrDir="$(dirname "$(realpath "$0")")"
confDir="${confDir}/config"
# shellcheck source=/dev/null
. "${scrDir}/globalcontrol.sh"
rofiStyle="${rofiStyle:-$ROFI_LAUNCHER_STYLE}"
rofi_config="${confDir}/rofi/styles/style_${rofiStyle:-1}.rasi"

rofiScale="${ROFI_LAUNCHER_SCALE}"
rofiScale="${ROFI_SCALE:-ROFI_LAUNCHER_SCALE}"
[[ "${rofiScale}" =~ ^[0-9]+$ ]] || rofiScale=${ROFI_SCALE:-10}

if [ ! -f "${rofi_config}" ]; then
    rofi_config="$(find "${confDir}/rofi/styles" -type f -name "style_*.rasi" | sort -t '_' -k 2 -n | head -1)"
fi

#// rofi action

case "${1}" in
d | --drun) r_mode="drun" ;;
w | --window) r_mode="window" ;;
f | --filebrowser) r_mode="filebrowser" ;;
r | --run) r_mode="run" ;;
h | --help)
    echo -e "$(basename "${0}") [action]"
    echo "d :  drun mode"
    echo "w :  window mode"
    echo "f :  filebrowser mode,"
    exit 0
    ;;
*) r_mode="drun" ;;
esac

#// set overrides
hypr_border="${hypr_border:-10}"
hypr_width="${hypr_width:-2}"
wind_border=$((hypr_border * 3))
[ "${hypr_border}" -eq 0 ] && elem_border="10" || elem_border=$((hypr_border * 2))
r_override="window {border: ${hypr_width}px; border-radius: ${wind_border}px;} element {border-radius: ${elem_border}px;}"
r_scale="configuration {font: \"JetBrainsMono Nerd Font ${rofiScale}\";}"
i_override="$(get_hyprConf "ICON_THEME")"
i_override="configuration {icon-theme: \"${i_override}\";}"

#// launch rofi
rofi -show "${r_mode}" -theme-str "${r_scale}" -theme-str "${r_override}" -theme-str "${i_override}" -config "${rofi_config}"

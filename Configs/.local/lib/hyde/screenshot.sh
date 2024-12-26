#!/usr/bin/env bash

SCREENSHOT_POST_COMMAND+=(
)

SCREENSHOT_PRE_COMMAND+=(
)

pre_cmd() {
	for cmd in "${SCREENSHOT_PRE_COMMAND[@]}"; do
		eval "$cmd"
	done
	hwCursor="$(hyprctl -q -j "getoption cursor:no_hardware_cursors" | jq .int)"
	hyprctl -q keyword cursor:no_hardware_cursors false
	sleep 0.1
	hyprctl -q -j "getoption cursor:no_hardware_cursors" | jq .int
}

post_cmd() {
	for cmd in "${SCREENSHOT_POST_COMMAND[@]}"; do
		eval "$cmd"
	done
	hyprctl -q keyword cursor:no_hardware_cursors "$hwCursor"
}

pre_cmd

if [ -z "$XDG_PICTURES_DIR" ]; then
	XDG_PICTURES_DIR="$HOME/Pictures"
fi

scrDir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
source "$scrDir/globalcontrol.sh"
confDir="${confDir:-$XDG_CONFIG_HOME}"
save_dir="${2:-$XDG_PICTURES_DIR/Screenshots}"
save_file=$(date +'%y%m%d_%Hh%Mm%Ss_screenshot.png')
temp_screenshot="/tmp/screenshot.png"
annotation_tool=${SCREENSHOT_ANNOTATION_TOOL:-swappy}

annotation_args=${SCREENSHOT_ANNOTATION_ARGS:-"-o" "${save_dir}/${save_file}" "-f" "${temp_screenshot}"}
annotation_args=$(eval echo "$annotation_args")

mkdir -p "$save_dir"

function print_error {
	cat <<"EOF"
    ./screenshot.sh <action>
    ...valid actions are...
        p  : print all screens
        s  : snip current screen
        sf : snip current screen (frozen)
        m  : print focused monitor
EOF
}

case $1 in
p) # print all outputs
	grimblast copysave screen $temp_screenshot && pre_cmd && "${annotation_tool}" ${annotation_args} ;;
s) # drag to manually snip an area / click on a window to print it
	grimblast copysave area $temp_screenshot && pre_cmd && "${annotation_tool}" ${annotation_args} ;;
sf) # frozen screen, drag to manually snip an area / click on a window to print it
	grimblast --freeze copysave area $temp_screenshot && pre_cmd && "${annotation_tool}" ${annotation_args} ;;
m) # print focused monitor
	grimblast copysave output $temp_screenshot && pre_cmd && "${annotation_tool}" ${annotation_args} ;;
*) # invalid option
	print_error ;;
esac

[ -f "$temp_screenshot" ] && rm "$temp_screenshot"

if [ -f "${save_dir}/${save_file}" ]; then
	notify-send -a "HyDE Alert" -i "${save_dir}/${save_file}" "saved in ${save_dir}"
fi

#!/usr/bin/env bash

SCREENSHOT_POST_COMMAND+=(
)

SCREENSHOT_PRE_COMMAND+=(
)

pre_cmd() {
	for cmd in "${SCREENSHOT_PRE_COMMAND[@]}"; do
		eval "$cmd"
	done
	trap 'post_cmd' EXIT
}

post_cmd() {
	for cmd in "${SCREENSHOT_POST_COMMAND[@]}"; do
		eval "$cmd"
	done
}

if [ -z "$XDG_PICTURES_DIR" ]; then
	XDG_PICTURES_DIR="$HOME/Pictures"
fi

# shellcheck source=$HOME/.local/bin/hyde-shell
# shellcheck disable=SC1091
if ! source "$(which hyde-shell)"; then
	echo "[wallbash] code :: Error: hyde-shell not found."
	echo "[wallbash] code :: Is HyDE installed?"
	exit 1
fi

confDir="${confDir:-$XDG_CONFIG_HOME}"
save_dir="${2:-$XDG_PICTURES_DIR/Screenshots}"
save_file=$(date +'%y%m%d_%Hh%Mm%Ss_screenshot.png')
temp_screenshot="/tmp/screenshot.png"
annotation_tool=${SCREENSHOT_ANNOTATION_TOOL:-satty}
if [[ -z "$annotation_tool" ]]; then
	pkg_installed "swappy" && annotation_tool="swappy"
	pkg_installed "satty" && annotation_tool="satty"
fi

annotation_args=${SCREENSHOT_ANNOTATION_ARGS:-"-o" "${save_dir}/${save_file}" "-f" "${temp_screenshot}"}
annotation_args=$(eval echo "$annotation_args")

mkdir -p "$save_dir"

# Fixes the issue where the annotation tool doesn't save the file in the correct directory
if [[ "$annotation_tool" == "swappy" ]]; then
	swpy_dir="${confDir}/swappy"
	mkdir -p "$swpy_dir"
	echo -e "[Default]\nsave_dir=$save_dir\nsave_filename_format=$save_file" >"${swpy_dir}"/config
fi

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

pre_cmd

case $1 in
p)                 # print all outputs
	timeout 0.2 slurp # capture animation lol
	"$LIB_DIR/hyde/grimblast" copysave screen $temp_screenshot && "${annotation_tool}" ${annotation_args}
	;;
s) # drag to manually snip an area / click on a window to print it
	"$LIB_DIR/hyde/grimblast" copysave area $temp_screenshot && "${annotation_tool}" ${annotation_args} ;;
sf) # frozen screen, drag to manually snip an area / click on a window to print it
	"$LIB_DIR/hyde/grimblast" --freeze --cursor copysave area $temp_screenshot && "${annotation_tool}" ${annotation_args} ;;
m)                 # print focused monitor
	timeout 0.2 slurp # capture animation lol
	"$LIB_DIR/hyde/grimblast" copysave output $temp_screenshot && "${annotation_tool}" ${annotation_args}
	;;
*) # invalid option
	print_error ;;
esac

[ -f "$temp_screenshot" ] && rm "$temp_screenshot"

if [ -f "${save_dir}/${save_file}" ]; then
	notify-send -a "HyDE Alert" -i "${save_dir}/${save_file}" "saved in ${save_dir}"
fi

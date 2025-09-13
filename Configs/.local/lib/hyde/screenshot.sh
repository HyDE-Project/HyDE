#!/usr/bin/env bash

if [[ "${HYDE_SHELL_INIT}" -ne 1 ]]; then
    eval "$(hyde-shell init)"
else
    export_hyde_config
fi

USAGE() {
	cat <<"USAGE"

	Usage: $(basename "$0") [option]
	Options:
		p     Print all outputs
		s     Select area or window to screenshot
		sf    Select area or window with frozen screen
		m     Screenshot focused monitor
		sc    Use tesseract to scan image, then add to clipboard

USAGE
}

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

# Create secure temporary file
temp_screenshot=$(mktemp -t screenshot_XXXXXX.png)

if [ -z "$XDG_PICTURES_DIR" ]; then
	XDG_PICTURES_DIR="$HOME/Pictures"
fi

confDir="${confDir:-$XDG_CONFIG_HOME}"
save_dir="${2:-$XDG_PICTURES_DIR/Screenshots}"
save_file=$(date +'%y%m%d_%Hh%Mm%Ss_screenshot.png')
annotation_tool=${SCREENSHOT_ANNOTATION_TOOL}
annotation_args=("-o" "${save_dir}/${save_file}" "-f" "${temp_screenshot}")
tesseract_default_language=("eng")
tesseract_languages=("${SCREENSHOT_OCR_TESSERACT_LANGUAGES[@]:-${tesseract_default_language[@]}}")
tesseract_languages+=("osd")

if [[ -z "$annotation_tool" ]]; then
	pkg_installed "swappy" && annotation_tool="swappy"
	pkg_installed "satty" && annotation_tool="satty"
fi
mkdir -p "$save_dir"

# Fixes the issue where the annotation tool doesn't save the file in the correct directory
if [[ "$annotation_tool" == "swappy" ]]; then
	swpy_dir="${confDir}/swappy"
	mkdir -p "$swpy_dir"
	echo -e "[Default]\nsave_dir=$save_dir\nsave_filename_format=$save_file" >"${swpy_dir}"/config
fi

if [[ "$annotation_tool" == "satty" ]]; then
	annotation_args+=("--copy-command" "wl-copy")
fi

# Add any additional annotation arguments
[[ -n "${SCREENSHOT_ANNOTATION_ARGS[*]}" ]] && annotation_args+=("${SCREENSHOT_ANNOTATION_ARGS[@]}")

# screenshot function, globbing was difficult to read and maintain
take_screenshot() {
	local mode=$1
	shift
	local extra_args=("$@")

	# execute grimblast with given args
	if "$LIB_DIR/hyde/grimblast" "${extra_args[@]}" copysave "$mode" "$temp_screenshot"; then
		if ! "${annotation_tool}" "${annotation_args[@]}"; then
			notify-send -a "HyDE Alert" "Screenshot Error" "Failed to open annotation tool"
			return 1
		fi
	else
		notify-send -a "HyDE Alert" "Screenshot Error" "Failed to take screenshot"
		return 1
	fi
}

ocr_screenshot() {
	local mode=$1
	shift
	local extra_args=("$@")

	# execute grimblast with given args
	if "$LIB_DIR/hyde/grimblast" "${extra_args[@]}" copysave "$mode" "$temp_screenshot"; then
		if pkg_installed imagemagick; then
			magick "${temp_screenshot}" \
				-colorspace gray \
				-contrast-stretch 0 \
				-level 15%,85% \
				-resize 400% \
				-sharpen 0x1 \
				-auto-threshold triangle \
				-morphology close diamond:1 \
				-deskew 40% \
				"${temp_screenshot}"
		else
			notify-send -a "HyDE Alert" "OCR: imagemagick is not installed, recognition accuracy is reduced" -e -i "dialog-warning"
		fi
		tesseract_package_prefix="tesseract-data-"
		tesseract_packages=("${tesseract_languages[@]/#/$tesseract_package_prefix}")
		tesseract_packages+=("tesseract")
		for pkg in "${tesseract_packages[@]}"; do
			if ! pkg_installed "${pkg}"; then
				notify-send -a "HyDE Alert" "$(echo -e "OCR: required package is not installed\n ${pkg}")" -e -i "dialog-error"
				return 1
			fi
		done
		tesseract_languages_prepared=$(IFS=+; echo "${tesseract_languages[*]}")
		tesseract_output=$(tesseract \
			--psm 6 \
			--oem 3 \
			-l ${tesseract_languages_prepared} \
			"${temp_screenshot}" \
			stdout
			2>/dev/null
		)
		printf "%s" "$tesseract_output" | wl-copy
		notify-send -a "HyDE Alert" "$(echo -e "OCR: ${#tesseract_output} symbols recognized\n\nLanguages used ${tesseract_languages[@]/#/'\n '}")" -i "${temp_screenshot}" -e
		rm -f "${temp_screenshot}"
	else
		notify-send -a "HyDE Alert" "OCR: screenshot error" -e -i "dialog-error"
		return 1
	fi
}

pre_cmd

case $1 in
p) # print all outputs
	take_screenshot "screen"
	;;
s) # drag to manually snip an area / click on a window to print it
	take_screenshot "area"
	;;
sf) # frozen screen, drag to manually snip an area / click on a window to print it
	take_screenshot "area" "--freeze"
	;;
m) # print focused monitor
	take_screenshot "output"
	;;
sc) #? 󱉶 Use 'tesseract' to scan image then add to clipboard
	ocr_screenshot "area" "--freeze"
	;;
*) # invalid option
	USAGE
	;;
esac

[ -f "${temp_screenshot}" ] && rm "${temp_screenshot}"

if [ -f "${save_dir}/${save_file}" ]; then
	notify-send -a "HyDE Alert" -i "${save_dir}/${save_file}" "saved in ${save_dir}"
fi

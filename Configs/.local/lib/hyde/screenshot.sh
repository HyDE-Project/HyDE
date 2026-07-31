#!/usr/bin/env bash
if [[ $HYDE_SHELL_INIT -ne 1 ]]; then
    eval "$(hyde-shell init)"
else
    export_hyde_config
fi

# shellcheck disable=SC1091
[[ -f "${LIB_DIR}/hyde/shutils/l10n.sh" ]] && source "${LIB_DIR}/hyde/shutils/l10n.sh"

USAGE() {
    cat <<"USAGE"

	Usage: $(basename "$0") [option]
	Options:
		p             Print all outputs
		s             Select area or window to screenshot
		sf            Select area or window with frozen screen
		m             Screenshot focused monitor
		sc            Use tesseract to scan image, then add to clipboard

    Flags:
	    --no-notify  Disable the save notification
        --help       Show this help message

USAGE
}
SCREENSHOT_POST_COMMAND+=()
SCREENSHOT_PRE_COMMAND+=()
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

SCREENSHOT_NOTIFY=${SCREENSHOT_NOTIFY:-true}
SCREENSHOT_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
    --no-notify)
        SCREENSHOT_NOTIFY=false
        shift
        ;;
    -h | --help)
        USAGE
        exit 0
        ;;
    *)
        SCREENSHOT_ARGS+=("$1")
        shift
        ;;
    esac
done

set -- "${SCREENSHOT_ARGS[@]}"

temp_screenshot=${XDG_RUNTIME_DIR:-/tmp}/hyde_screenshot.png
if [ -z "$XDG_PICTURES_DIR" ]; then
    XDG_PICTURES_DIR="$HOME/Pictures"
fi
confDir="${confDir:-$XDG_CONFIG_HOME}"
save_dir="${2:-$XDG_PICTURES_DIR/Screenshots}"
save_file=$(date +'%y%m%d_%Hh%Mm%Ss_screenshot.png')
annotation_tool="${SCREENSHOT_ANNOTATION_TOOL}"
annotation_args=("-o" "$save_dir/$save_file" "-f" "$temp_screenshot")
GRIMBLAST_EDITOR=${GRIMBLAST_EDITOR:-$annotation_tool}
tesseract_default_language=("eng")
tesseract_languages=("${SCREENSHOT_OCR_TESSERACT_LANGUAGES[@]:-${tesseract_default_language[@]}}")
tesseract_languages+=("osd")
if [[ -z $annotation_tool ]]; then
    pkg_installed "swappy" && annotation_tool="swappy"
    pkg_installed "satty" && annotation_tool="satty"
fi
mkdir -p "$save_dir"
if [[ $annotation_tool == "swappy" ]]; then
    swpy_dir="$confDir/swappy"
    mkdir -p "$swpy_dir"
    echo -e "[Default]\nsave_dir=$save_dir\nsave_filename_format=$save_file" >"$swpy_dir"/config
fi
if [[ $annotation_tool == "satty" ]]; then
    annotation_args+=("--copy-command" "wl-copy")
fi

[[ -n ${SCREENSHOT_ANNOTATION_ARGS[*]} ]] && annotation_args+=("${SCREENSHOT_ANNOTATION_ARGS[@]}")

run_annotation_tool() {
    if [[ $annotation_tool == "satty" ]]; then
        GSK_RENDERER="${GSK_RENDERER:-gl}" "$annotation_tool" "${annotation_args[@]}"
    else
        "$annotation_tool" "${annotation_args[@]}"
    fi
}

take_screenshot() {
    local mode=$1
    shift
    local extra_args=("$@")
    local target_file="$temp_screenshot"

    [[ ${SCREENSHOT_ANNOTATION_ENABLED} == false ]] && target_file="$save_dir/$save_file"

    command=("$LIB_DIR/hyde/screenshot/grimblast" "${extra_args[@]}" "copysave" "${mode}" "${target_file}")
    print_log -g "Executing screenshot command: ${command[*]}"
    if eval "${command[*]}"; then
        [[ ${SCREENSHOT_ANNOTATION_ENABLED} == false ]] && return 0
        if ! run_annotation_tool; then
            send_notifs -r 9 -a "HyDE Alert" "Screenshot Error" "Failed to open annotation tool"
            return 1
        fi
    else
        send_notifs -a "HyDE Alert" "Screenshot Error" "Failed to take screenshot"
        return 1
    fi
}
ocr_screenshot() {
    local mode=$1
    shift
    local extra_args=("$@")
    if "$LIB_DIR/hyde/screenshot/grimblast" "${extra_args[@]}" copysave "$mode" "$temp_screenshot"; then
        source "${LIB_DIR}/hyde/shutils/ocr.sh"
        source ${XDG_STATE_HOME}/hyde/config
        print_log -g "Performing OCR on $temp_screenshot"
        send_notifs "OCR" "Performing OCR on screenshot..." -i "document-scan" -r 9
        if ! ocr_extract "$temp_screenshot"; then
            send_notifs -r 9 -a "HyDE Alert" "OCR: extraction error" -e -i "dialog-error"
            return 1
        fi
    else
        send_notifs -a "HyDE Alert" "OCR: screenshot error" -e -i "dialog-error"
        return 1
    fi
    exit 0
}
qr_screenshot() {
    local mode=$1
    shift
    local extra_args=("$@")
    if "$LIB_DIR/hyde/screenshot/grimblast" "${extra_args[@]}" copysave "$mode" "$temp_screenshot"; then
        source "${LIB_DIR}/hyde/shutils/qr.sh"
        print_log -g "Performing QR scan on $temp_screenshot"
        send_notifs "QR Scan" "Performing QR scan on screenshot..." -i "document-scan" -r 9
        if ! qr_extract "$temp_screenshot"; then
            send_notifs -r 9 -a "HyDE Alert" "QR: extraction error" -e -i "dialog-error"
            return 1
        fi
    else
        send_notifs -a "HyDE Alert" "QR: screenshot error" -e -i "dialog-error"
        return 1
    fi
}

pre_cmd

case $1 in
p | printscreen) take_screenshot "screen" ;;
s | snip) take_screenshot "area" ;;
sf | snapfreeze) take_screenshot "area" "--freeze" ;;
m | monitor) take_screenshot "output" ;;
sc | scan) ocr_screenshot "area" "--freeze" ;;
sq | qr) qr_screenshot "area" "--freeze" ;;
*) USAGE ;;
esac

[ -f "$temp_screenshot" ] && rm "$temp_screenshot"
if [ -f "$save_dir/$save_file" ] && [[ "${SCREENSHOT_NOTIFY}" != false ]]; then
    send_notifs -r 9 -a "HyDE Alert" -i "$save_dir/$save_file" "saved in $save_dir"
    exit 0
fi

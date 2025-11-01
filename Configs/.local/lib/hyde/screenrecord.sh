#!/usr/bin/env bash
set -eo pipefail
[[ $HYDE_SHELL_INIT -ne 1 ]] && eval "$(hyde-shell init)"
RECORDER="wl-screenrec"
command -v "$RECORDER" &>/dev/null || RECORDER="wf-recorder"
if ! command -v "$RECORDER" &>/dev/null; then
    notify-send -a "HyDE Alert" "No screen recorder found. Try installing wl-screenrec or wf-recorder."
    echo "No screen recorder found. Try installing wl-screenrec or wf-recorder."
    exit 1
fi
USAGE() {
    cat <<USAGE

Usage: 'hyde-shell screenrecord' [option]
    
    Using $RECORDER to record the screen.

Options:

    --start    Screen record
    --backend       Use 'wl-screenrec' or 'wf-recorder' as the backend 
    --file          Specify the output file
    --quit     Stop the recording
    --help          Show this help message
    --              Pass additional arguments to '$RECORDER'

Note: 

    Click and drag on the screen to select a region to record.
    To record the whole screen, simply click without dragging.

    Additional arguments are passed to '$RECORDER'.

Example:
        'hyde-shell screenrecord' --start -- --audio --codec libx264


    To see all available options for '$RECORDER', run:
        $RECORDER --help    

USAGE
}
handle_recording() {
    save_dir="${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings"
    save_file=$(date +'%y%m%d_%Hh%Mm%Ss_recording.mp4')
    save_file_path="${FILE_PATH:-"$save_dir/$save_file"}"
    mkdir -p "$save_dir"
    parameters=()
    while [[ $# -gt 0 ]]; do
        if [[ $1 == "--" ]]; then
            shift
            while [[ $# -gt 0 ]]; do
                parameters+=("$1")
                shift
            done
            break
        fi
        shift
    done
    OUTPUT="$(hyprctl -j monitors | jq -r '.[] | select(.focused==true) | .name')"
    GEOM="$(slurp -w 0 -b "#00000000" -c "#FFFFFF" -s "#00000055" -B "#00000000" -o | awk '{
        # slurp outputs format: x,y WxH
        split($1, pos, ",");  # Split x,y
        x = pos[1];
        y = pos[2];
        split($2, size, "x");  # Split WxH
        width = size[1];
        height = size[2];
        
        # Check if selection meets minimum size
        if (width >= 16 && height >= 16) {
            print x","y" "width"x"height;  # Output in the same format
        }
    }')"
    if [[ -n $GEOM ]]; then
        parameters+=("--geometry" "$GEOM")
    else
        echo "Using whole screen for recording"
        [[ -n $OUTPUT ]] && parameters+=(--output "$OUTPUT")
    fi
    tmp_thumbnail=$(mktemp -t thumbnail_XXXXXX.png)
    if [[ -z $GEOM ]]; then
        "$LIB_DIR/hyde/grimblast" save active "$tmp_thumbnail"
    else
        grim -g "$GEOM" "$tmp_thumbnail"
    fi
    "$RECORDER" "${parameters[@]}" -f "$save_file_path"
    notify-send -a "HyDE Alert" "$RECORDER: Recording saved at $save_file_path" -i "$tmp_thumbnail"
}
while [[ $# -gt 0 ]]; do
    case "$1" in
    --file)
        shift
        FILE_PATH="$1"
        ;;
    --backend)
        shift
        RECORDER="$1"
        ;;
    --start)
        handle_recording "$@"
        exit 0
        ;;
    --quit)
        killall "$RECORDER"
        notify-send -a "HyDE Alert" "Recording stopped"
        exit 0
        ;;
    --help)
        USAGE
        exit 0
        ;;
    *)
        USAGE
        exit 1
        ;;
    esac
    shift
done
if [[ $# -eq 0 ]]; then
    USAGE
fi

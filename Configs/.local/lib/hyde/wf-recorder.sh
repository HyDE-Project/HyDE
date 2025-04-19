#!/bin/bash

get_encoder() {
    local preferred_encoders=(
        "h264_nvenc"
        "h264_vaapi"
        "h264_qsv"
        "h264_v4l2m2m"
        "h264_amf"
        "h264_vulkan"
    )
    local encoders
    encoders=$(ffmpeg -hide_banner -encoders)

    for encoder in "${preferred_encoders[@]}"; do
        if echo "$encoders" | grep -q "$encoder"; then
            echo "$encoder"
            return
        fi
    done

    echo "h264"  # fallback to software encoding
}

# Parse arguments
WITH_AUDIO=false
for arg in "$@"; do
    if [[ "$arg" == "--audio" ]]; then
        WITH_AUDIO=true
    fi
done


ENCODER=$(get_encoder)
# Get region to record
REGION=$(slurp)

# Setup save path
VIDEOS_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}"
OUTPUT_DIR="$VIDEOS_DIR/ScreenRecordings"
mkdir -p "$OUTPUT_DIR"

# Generate filename
FILENAME="$OUTPUT_DIR/recording_$(date +"%Y-%m-%d_%H:%M:%S").mp4"

# Build command
CMD="wf-recorder"
[[ "$WITH_AUDIO" == true ]] && CMD+=" --audio"
CMD+=" -g \"$REGION\" -c $ENCODER -f \"$FILENAME\""

# Run it
eval "$CMD"

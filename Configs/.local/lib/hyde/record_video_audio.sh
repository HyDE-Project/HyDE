#!/bin/bash
scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
# Get encoder
ENCODER=$(${scrDir}/get_encoder.sh)

# Get region to record
REGION=$(slurp)

# Get video save path
VIDEOS_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}"
mkdir -p "$VIDEOS_DIR"

# Timestamped filename
FILENAME="$VIDEOS_DIR/recording_$(date +"%Y-%m-%d_%H:%M:%S").mp4"

# Start recording with audio (default source is auto-selected by wf-recorder)
wf-recorder --audio -g "$REGION" -c "$ENCODER" -f "$FILENAME"

#!/bin/bash

# List of preferred encoders in priority order
preferred_encoders=(
    "h264_nvenc"
    "h264_vaapi"
    "h264_qsv"
    "h264_v4l2m2m"
    "h264_amf"
    "h264_vulkan"
)

# Get the list of available encoders
encoders=$(ffmpeg -hide_banner -encoders)

# Find the first available preferred encoder
for encoder in "${preferred_encoders[@]}"; do
    if echo "$encoders" | grep -q "$encoder"; then
        echo "$encoder"
        exit 0
    fi
done

# Fallback to software encoding if no hardware encoder found
echo "h264"

# 00-gpu.sh - GPU detection
# This env script will detect the presence of various GPUs on the system
# and set environment variables accordingly.
# This is OVERRIDABLE by the user, so it can be customized as needed.
# create you own file that is alphabetically after this one

# Usage:
#
# The 'key' variable is a 4-digit string representing GPU presence:
#   1st digit: AMD GPU present (1) or not (0)
#   2nd digit: Intel GPU present (1) or not (0)
#   3rd digit: Nouveau GPU present (1) or not (0)
#   4th digit: NVIDIA GPU present (1) or not (0)
#
# Example:
#   key="0101" means AMD=0, Intel=1, Nouveau=0, NVIDIA=1 (hybrid Intel-NVIDIA setup)
#   key="1000" means AMD=1, Intel=0, Nouveau=0, NVIDIA=0 (AMD only)
#   key="0010" means AMD=0, Intel=0, Nouveau=1, NVIDIA=0 (Nouveau only)
#

cmd_exists() {
  command -v "$1" >/dev/null 2>&1
}

detect_nvidia() {
  # Check if nvidia-smi exists and works (proper drivers installed)
  if cmd_exists nvidia-smi && nvidia-smi >/dev/null 2>&1; then
    echo 1
  # Alternative check: nvidia kernel module loaded
  elif lsmod | grep -q 'nvidia'; then
    echo 1
  else
    echo 0
  fi
}

detect_amd() {
  if cmd_exists lspci && lspci -nn | grep -E "(VGA|3D)" | grep -iq "1002" 2>&1; then
    echo 1
  else
    echo 0
  fi
}

detect_intel() {
  if cmd_exists lspci && lspci -nn | grep -E "(VGA|3D)" | grep -iq "8086"; then
    echo 1
  else
    echo 0
  fi
}

detect_nouveau() {
  if lsmod | grep -q 'nouveau'; then
    echo 1
  else
    echo 0
  fi
}

detect_nvidia_vaapi() {
  # Check if libva-nvidia-driver is installed by looking for the VA-API driver
  if [ -f "/usr/lib/dri/nvidia_drv_video.so" ] || [ -f "/usr/lib64/dri/nvidia_drv_video.so" ]; then
    echo 1
  else
    echo 0
  fi
}

NVIDIA=$(detect_nvidia)
AMD=$(detect_amd)
INTEL=$(detect_intel)
NOUVEAU=$(detect_nouveau)
NVIDIA_VAAPI=$(detect_nvidia_vaapi)

key="${AMD}${INTEL}${NOUVEAU}${NVIDIA}"

case "$key" in
0101)
  GPU_SETUP="hybrid-intel-nvidia"
  export __GLX_VENDOR_LIBRARY_NAME=nvidia
  export VK_LAYER_NV_optimus=1
  # Let VA-API auto-detect between Intel iHD/i965
  # GBM_BACKEND=nvidia-drm removed - optional and can cause Firefox crashes
  if [ "$NVIDIA_VAAPI" = "1" ]; then
    export NVD_BACKEND=direct # Requires 'libva-nvidia-driver' package
    # Let applications auto-detect VA-API driver (nvidia vs iHD)
  fi
  ;;

1100)
  GPU_SETUP="hybrid-amd-intel"
  # AMD usually has better driver support, so only set if needed
  # export LIBVA_DRIVER_NAME=radeonsi
  # export VDPAU_DRIVER=radeonsi
  ;;

0110)
  GPU_SETUP="hybrid-intel-nouveau"
  # Let system auto-detect best drivers - don't force specific drivers
  ;;

0001)
  GPU_SETUP="nvidia-only"
  # NVIDIA requires these for proper Wayland/Hyprland support
  export LIBVA_DRIVER_NAME=nvidia
  export __GLX_VENDOR_LIBRARY_NAME=nvidia
  export __GL_VRR_ALLOWED=1
  if [ "$NVIDIA_VAAPI" = "1" ]; then
    export NVD_BACKEND=direct # Requires 'libva-nvidia-driver' package
  fi
  ;;

1000)
  GPU_SETUP="amd-only"
  # AMD drivers usually auto-detect correctly
  # export LIBVA_DRIVER_NAME=radeonsi
  # export VDPAU_DRIVER=radeonsi
  ;;

0010)
  GPU_SETUP="nouveau-only"
  # Let system auto-detect best Nouveau drivers
  ;;

0100)
  GPU_SETUP="intel-only"
  # Let system auto-detect Intel VA-API driver (iHD vs i965)
  ;;

*)
  GPU_SETUP="unknown or we don't need to do anything"
  ;;
esac

export GPU_SETUP
echo "GPU setup detected: $GPU_SETUP"

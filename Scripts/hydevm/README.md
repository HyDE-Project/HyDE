# HydeVM - Simplified VM Tool for HyDE Contributors

HydeVM is a streamlined development tool that automatically sets up HyDE in a virtual machine for testing different branches and commits.

- [HydeVM - Simplified VM Tool for HyDE Contributors](#hydevm---simplified-vm-tool-for-hyde-contributors)
  - [Hardware Requirements](#hardware-requirements)
  - [Features](#features)
  - [Quick Start](#quick-start)
    - [Arch Linux](#arch-linux)
    - [NixOS](#nixos)
  - [First-Time Setup](#first-time-setup)
  - [Usage](#usage)
    - [Basic Commands](#basic-commands)
    - [Environment Variables](#environment-variables)
  - [VM Details](#vm-details)
  - [Troubleshooting](#troubleshooting)
    - [KVM Not Available](#kvm-not-available)
    - [Missing Dependencies](#missing-dependencies)
    - [Clean Start](#clean-start)
    - [Killing http server](#killing-http-server)
  - [VM Host Guide](#vm-host-guide)
    - [Hardware Requirements (Detailed)](#hardware-requirements-detailed)
    - [Non-NixOS Hosts using Nix](#non-nixos-hosts-using-nix)
    - [AMD GPU + Any CPU ✅](#amd-gpu--any-cpu-)
    - [Intel CPU with iGPU ✅](#intel-cpu-with-igpu-)
    - [NVIDIA GPU + Any CPU ⚠️](#nvidia-gpu--any-cpu-️)
    - [Custom QEMU Configuration](#custom-qemu-configuration)
    - [Verification Steps](#verification-steps)
    - [Troubleshooting Hyprland in VM](#troubleshooting-hyprland-in-vm)

**Supported Host Operating Systems:** Arch Linux, NixOS

## Hardware Requirements

**CPU:** x86_64 with virtualization support (Intel VT-x or AMD-V, enabled in BIOS)
**Memory:** 4GB+ RAM (VM uses 4GB by default)
**GPU Compatibility:**

- ✅ **AMD GPU** - Excellent (HD 7000+ series, Mesa drivers)
- ✅ **Intel iGPU** - Excellent (HD 4000+ Ivy Bridge, Mesa drivers)
- ⚠️ **NVIDIA GPU** - May need tweaking (GTX 600+ series, proprietary drivers can cause issues)

**OpenGL:** 3.3+ support required for Hyprland
**Note:** Tested on AMD GPU + Intel CPU. Hyprland VM support is experimental.

## Features

- **Zero Configuration**: Automatically downloads Arch Linux base image and sets up HyDE
- **Branch Testing**: Easily test any HyDE branch or commit hash
- **Smart Caching**: Creates cached snapshots for faster subsequent runs (uses XDG cache directory)
- **Optional Persistence**: Choose whether changes should be saved or discarded
- **OS Detection**: Automatically detects your OS and handles dependencies appropriately

## Quick Start

### Arch Linux

```bash
# Download and run (will auto-detect missing packages)
curl -L https://raw.githubusercontent.com/HyDE-Project/HyDE/main/Scripts/hydevm/hydevm.sh -o hydevm
chmod +x hydevm
./hydevm
```

### NixOS

```bash
# Using flakes from HyDE repository
nix run github:HyDE-Project/HyDE

# Or if you have the repository cloned locally
nix run
```

## First-Time Setup

When you run a new branch/commit for the first time, hydevm will:

1. **OS Detection**: Automatically detects your OS and checks dependencies
2. **Dependency Installation**: (Arch only) Prompts to install missing packages
3. **VM Setup**: Shows a VM window with setup instructions
4. **HyDE Installation**: You'll need to:
   - Login as `arch` / `arch`
   - Run the provided curl command to download and execute the setup script
   - Wait for HyDE installation to complete
     - Hit enter for defaults
     - It will prompt for a password at the end, use `arch`
     - If you end up missing the password check, you can rerun the install script `./setup.sh`
   - Run `sudo poweroff` to shutdown and create the snapshot

**Subsequent runs are instant** - uses cached snapshot!


## Usage

### Basic Commands

```bash
# Run master branch
hydevm

# Run specific branch or commit
hydevm feature-branch
hydevm abc123def

# Run with persistence (changes will be saved)
hydevm --persist
hydevm --persist dev-branch

# List cached snapshots
hydevm --list

# Clean all cached data
hydevm --clean

# Check dependencies
hydevm --check-deps

# Install dependencies (Arch only)
hydevm --install-deps
```

### Environment Variables

```bash
# Customize VM resources
VM_MEMORY=8G VM_CPUS=4 hydevm

# Set extra QEMU arguments
VM_EXTRA_ARGS="-display vnc=:1" hydevm

# Override QEMU command entirely, provided $VM_DISK will be substituted with the actual disk image
VM_QEMU_OVERRIDE="qemu-system-x86_64 -m 4G -smp 2 -enable-kvm -drive file=\$VM_DISK,format=qcow2,if=virtio -device virtio-vga -display gtk" hydevm
```

## VM Details

- **Login**: `arch` / `arch`
- **SSH Access**: `ssh arch@localhost -p 2222`
- **Persistence**: Optional flag determines if changes are saved
- **Cache Directory**: Uses XDG Base Directory specification (`$XDG_CACHE_HOME/hydevm/`)
- **Snapshots**: Stored in `$XDG_CACHE_HOME/hydevm/snapshots/` (typically `~/.cache/hydevm/snapshots/`)
- **Base Image**: Cached in `$XDG_CACHE_HOME/hydevm/archbase.qcow2` (typically `~/.cache/hydevm/archbase.qcow2`)

## Troubleshooting

### KVM Not Available

```bash
# Arch Linux
sudo usermod -a -G kvm $USER

# NixOS - add to configuration.nix
virtualisation.libvirtd.enable = true;
```

### Missing Dependencies

- **Arch**: Script will prompt to install missing packages
- **NixOS**: Nix will automatically install missing packages

### Clean Start

```bash
hydevm --clean  # Remove all cached data from $XDG_CACHE_HOME/hydevm/
```

### Killing http server

If you are running into issues with the http server, you can kill it with:

```bash
pkill -f "python3 -m http.server"
```

## VM Host Guide

HyDE uses Hyprland, which has specific requirements for VM environments. Hyprland VM support is limited - see [Hyprland - Running in a VM](https://wiki.hyprland.org/Getting-Started/Installation/#running-in-a-vm) for official guidance.

> [!NOTE]
> I'm trying here to make HyDE easier to work with VM's. If you have any suggestions based on your hardware and experience, or find this documentation inaccurate, please let me know.

**Key Requirements:**

- VirtIO GPU support
- OpenGL 3.3+ acceleration
- VT-x/AMD-V virtualization support

### Hardware Requirements (Detailed)

**CPU:**

- Intel CPU with VT-x or AMD CPU with AMD-V
- Virtualization enabled in BIOS/UEFI

**GPU & OpenGL Support:**

- ✅ **AMD**: HD 7000+ series (Mesa drivers recommended)
- ✅ **Intel**: HD 4000+ (Ivy Bridge) or newer
- ⚠️ **NVIDIA**: GTX 600+ series (proprietary drivers may cause issues)
- **OpenGL 3.3+ support required**

### Non-NixOS Hosts using Nix

For non-NixOS hosts, use [nixGL](https://github.com/nix-community/nixGL) for better graphics support:

```bash
# Install nixGL first, then run HydeVM
nixGL nix run github:HyDE-Project/HyDE
```

### AMD GPU + Any CPU ✅

**Packages (Arch):** `qemu-desktop mesa`
**Packages (NixOS):** `qemu mesa`

**NixOS Configuration:**

```nix
{
  hardware.graphics.enable = true;
  hardware.graphics.extraPackages = with pkgs; [ amdvlk ];
  boot.kernelModules = [ "kvm-intel" ]; # or "kvm-amd" for AMD CPUs
  virtualisation.libvirtd.enable = true;
}
```

```bash
# Test OpenGL
glxinfo | grep "OpenGL renderer"

# Verify VirtIO support
modprobe virtio_gpu
lsmod | grep virtio

# Default QEMU args should work perfectly
hydevm
```

### Intel CPU with iGPU ✅

**Packages (Arch):** `qemu-desktop mesa intel-media-driver`
**Packages (NixOS):** `qemu mesa intel-media-driver`

**NixOS Configuration:**

```nix
{
  hardware.graphics.enable = true;
  hardware.graphics.extraPackages = with pkgs; [ intel-media-driver ];
  boot.kernelModules = [ "kvm-intel" ];
  virtualisation.libvirtd.enable = true;
}
```

```bash
# Test OpenGL
glxinfo | grep "OpenGL renderer"

# Verify VirtIO support
modprobe virtio_gpu
lsmod | grep virtio

# Default QEMU args should work perfectly
hydevm
```

### NVIDIA GPU + Any CPU ⚠️

Option 1: Proprietary Drivers (May have issues)

```bash
# Packages (Arch)
sudo pacman -S qemu-desktop nvidia nvidia-utils

# Packages (NixOS) - add to configuration.nix:
{
  hardware.graphics.enable = true;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
  hardware.nvidia.modesetting.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  boot.kernelModules = [ "kvm-intel" ]; # or "kvm-amd"
  virtualisation.libvirtd.enable = true;
}

# Test OpenGL
glxinfo | grep "OpenGL renderer"

# If graphics issues occur, disable GL acceleration
VM_EXTRA_ARGS="-device virtio-vga -display gtk,gl=off" hydevm
```

Option 2: Nouveau Drivers

```bash
# Packages (Arch)
sudo pacman -S qemu-desktop mesa xf86-video-nouveau

# Packages (NixOS) - add to configuration.nix:
{
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nouveau" ];
  boot.kernelModules = [ "kvm-intel" ]; # or "kvm-amd"
  virtualisation.libvirtd.enable = true;
}

# Test OpenGL
glxinfo | grep "OpenGL renderer"

# Should work with default args
hydevm
```

Option 3: Software Rendering (Fallback)

```bash
# Force software rendering
VM_EXTRA_ARGS="-device VGA -display gtk,gl=off" hydevm
```

### Custom QEMU Configuration

The default configuration uses these optimized arguments for Hyprland:

```bash
# Current default (automatically applied)
-device virtio-vga-gl
-display gtk,gl=on,grab-on-hover=on
-enable-kvm
-cpu host
```

For complete control over QEMU arguments:

```bash
# Override entire QEMU command
VM_QEMU_OVERRIDE="qemu-system-x86_64 -m 4G -smp 2 -enable-kvm -cpu host -machine q35 -device intel-iommu -drive file=\$VM_DISK,format=qcow2,if=virtio -device virtio-vga-gl -display gtk,gl=on,grab-on-hover=on -usb -device usb-tablet -device ich9-intel-hda -device hda-output -vga none" hydevm

# The script will substitute $VM_DISK with the appropriate disk image
```

### Verification Steps

```bash
# 1. Check CPU virtualization support
egrep -c '(vmx|svm)' /proc/cpuinfo    # Should return > 0

# 2. Check KVM modules
lsmod | grep kvm                       # Should show kvm and kvm_intel/kvm_amd

# 3. Check OpenGL support
glxinfo | grep "OpenGL"               # Should show your GPU and OpenGL 3.3+

# 4. Check dependencies and system info
hydevm --check-deps

# 5. If issues occur, try software rendering
VM_EXTRA_ARGS="-device VGA -display gtk,gl=off" hydevm
```

### Troubleshooting Hyprland in VM

If you encounter issues with Hyprland in the VM:

1. **Graphics Issues**: Try disabling GL acceleration

   ```bash
   VM_EXTRA_ARGS="-device virtio-vga -display gtk,gl=off" hydevm
   ```

2. **Input Issues**: Ensure USB tablet is enabled (included in enhanced config)

3. **Audio Issues**: The enhanced config includes Intel HDA audio support

4. **Performance Issues**: Ensure KVM is enabled and working:

   ```bash
   # Check KVM access
   ls -la /dev/kvm
   # Should show your user has access (via kvm group)
   ```

**Note:** Hyprland VM support is experimental. For the best experience, consider using a bare metal installation for development.

# Ubuntu 24.04 Adaptation Guide for HyDE

## Overview

This directory contains scripts and documentation to adapt the HyDE project (Hyprland Desktop Environment) from Arch Linux to Ubuntu 24.04 LTS.

**Key Principles:**
- ✅ Only essential Hyprland packages
- ❌ No optional applications (browsers, IDEs, etc.)
- 🔧 Manual updates only (no automatic updates)
- 📋 Clear package equivalency mapping

## Quick Start

### Step 1: Install Essential Packages from Ubuntu Repositories

```bash
cd Scripts/ubuntu
./install_ubuntu_essentials.sh
```

This installs all packages available via `apt` (audio, networking, display manager, etc.)

### Step 2: Compile Hyprland Ecosystem

```bash
cd Scripts/ubuntu
./compile_hyprland_ecosystem.sh
```

Choose option 2 (Recommended set) or follow the interactive menu.

This compiles:
- Hyprland compositor
- uwsm (session manager)
- xdg-desktop-portal-hyprland
- swww, hyprlock, wlogout, hypridle

### Step 3: Manual Updates (When Needed)

```bash
cd Scripts/ubuntu
./manual_update.sh
```

This script provides manual update options. It will **never** run automatically.

## Files in This Directory

| File | Purpose |
|------|---------|
| `UBUNTU_PACKAGE_MAPPING.md` | Detailed Arch↔Ubuntu package equivalency mapping |
| `pkg_ubuntu_core.lst` | Ubuntu package list (essential packages only) |
| `install_ubuntu_essentials.sh` | Install apt packages |
| `compile_hyprland_ecosystem.sh` | Compile Hyprland components from source |
| `manual_update.sh` | Manual update script (no auto-updates) |
| `README.md` | This file |

## Package Categories

### ✅ Available via apt (Installed by `install_ubuntu_essentials.sh`)

- Audio system (PipeWire, Wireplumber)
- Network & Bluetooth (NetworkManager, Bluez)
- Display manager (SDDM)
- System utilities (brightnessctl, playerctl, etc.)
- Desktop integration (polkit, xdg-desktop-portal-gtk)
- Theming (Qt5/Qt6 support, Kvantum)
- Basic WM components (dunst, rofi, waybar, grim, slurp)

### ❌ Requires Compilation (Built by `compile_hyprland_ecosystem.sh`)

**Critical:**
- hyprland - The compositor
- uwsm - Wayland session manager
- xdg-desktop-portal-hyprland - Desktop integration

**Recommended:**
- swww - Wallpaper daemon
- hyprlock - Lock screen
- wlogout - Logout menu
- hypridle - Idle daemon

**Optional:**
- hyprpicker, satty, cliphist, wl-clip-persist, hyprsunset, nwg-look

## System Requirements

### Build Dependencies

The compilation script will install these automatically:

```bash
# Build tools
git cmake ninja-build gcc g++ pkg-config meson python3-pip

# Hyprland dependencies
libwayland-dev libxkbcommon-dev libpixman-1-dev libdrm-dev libgbm-dev
libinput-dev libxcb-composite0-dev libtomlplusplus-dev libzip-dev
... (see script for full list)

# Rust (for swww, satty, wl-clip-persist)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Go (for cliphist, nwg-look)
golang-go
```

### Minimum Hardware

- CPU: 2+ cores (compilation will take 30-60 minutes on older CPUs)
- RAM: 4GB minimum, 8GB recommended (compilation is memory-intensive)
- Disk: ~2GB for compiled binaries and build cache

## Differences from Arch HyDE

| Feature | Arch | Ubuntu |
|---------|------|--------|
| Package manager | pacman/yay | apt (no AUR) |
| Hyprland | pacman | Must compile |
| Most WM tools | AUR packages | Must compile |
| Package updates | Automatic (install_pre.sh) | Manual only |
| Update script | Built-in | `manual_update.sh` |

## Manual Update Workflow

Updates are **manual only** as requested. To update:

```bash
# Interactive menu
./manual_update.sh

# Update everything
./manual_update.sh --all

# Update only system packages
./manual_update.sh --system

# Update only Hyprland ecosystem
./manual_update.sh --hyprland
```

The script will:
1. Create a backup of your configs
2. Show you what will be updated
3. Ask for confirmation before proceeding
4. Build and install updates
5. Log everything for troubleshooting

## Important Notes

### 🔴 No Automatic Updates

Unlike the Arch version which runs `pacman -Syyu` during installation, this Ubuntu adaptation:
- Does **NOT** update packages automatically
- Does **NOT** include update mechanisms in install scripts
- Requires running `manual_update.sh` when you want to update

### 🐧 NVIDIA Support

If you have an NVIDIA GPU:

```bash
# Install kernel headers
sudo apt install linux-headers-$(uname -r)

# Install NVIDIA drivers (replace 555 with latest version)
sudo apt install nvidia-driver-555
```

The Arch auto-detection for NVIDIA is not included in this Ubuntu adaptation.

### 📁 Configuration Files

Hyprland configs work the same on Ubuntu:
- `~/.config/hypr/` - Hyprland configuration
- `~/.config/hyde/` - HyDE theming and scripts
- `~/.local/lib/hyde/` - HyDE library scripts

### 🔄 Updating Compiled Components

When you want to update Hyprland or other compiled components:

```bash
./manual_update.sh --hyprland
```

This will:
- Pull latest source from GitHub
- Show current vs new version
- Ask for confirmation
- Rebuild and install

### ⚙️ Service Management

Services work the same as on Arch:

```bash
# Enable SDDM (done automatically by install script)
sudo systemctl enable sddm

# Restart display manager after updates
sudo systemctl restart sddm

# Or just reboot
sudo reboot
```

## Troubleshooting

### Build Failures

Check the log file:
```bash
cat ~/.cache/hyde/compile_*.log
```

Common issues:
- Missing dependencies → Run install script again
- Out of memory → Close other applications, use swap
- Git clone failures → Check internet connection

### Hyprland Not Starting

1. Check if compiled correctly:
   ```bash
   which hyprland
   hyprctl version
   ```

2. Check SDDM:
   ```bash
   sudo systemctl status sddm
   ```

3. Check logs:
   ```bash
   journalctl -u sddm -b
   ```

### Update Script Issues

If `manual_update.sh` fails:
- Check the log: `~/.cache/hyde/manual_update_*.log`
- Ensure you have sudo privileges
- Verify internet connection for git clones

## Getting Help

1. Check logs in `~/.cache/hyde/`
2. Review `UBUNTU_PACKAGE_MAPPING.md` for package details
3. Check original HyDE documentation for config help
4. Report Ubuntu-specific issues to this fork

## Testing Your Installation

After installation:

```bash
# Test if Hyprland is installed
which hyprland
hyprctl version

# Test other components
which uwsm
which swww
which hyprlock
which waybar

# Log out and select Hyprland from SDDM
```

## Cleanup

To remove build artifacts:

```bash
# Build directories are in /tmp and auto-cleaned
# But if needed:
rm -rf /tmp/hyprland-build-*
rm -rf /tmp/hyprland-updates-*

# Old logs
rm ~/.cache/hyde/*.log
```

## What's NOT Included

Following the requirement to exclude optional applications:

**Excluded from adaptation:**
- Firefox, Chrome (browsers)
- VS Code, Codium (IDEs)
- Dolphin, Ark (file managers)
- Steam, gaming tools
- Spotify, music players
- Pokemon colorscripts, oh-my-zsh themes

These are user choice and not essential for Hyprland functionality.

## License

Same as parent HyDE project (see LICENSE in root directory).

## Credits

- Original HyDE project: [HyDE-Project/HyDE](https://github.com/HyDE-Project/HyDE)
- Ubuntu adaptation: This fork
- Hyprland: [hyprwm/Hyprland](https://github.com/hyprwm/Hyprland)

---

**Last Updated:** 2026-02-12  
**Target System:** Ubuntu 24.04.3 LTS (Noble)  
**Adaptation Version:** 1.0

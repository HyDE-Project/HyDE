# Ubuntu 24.04 Package Mapping for HyDE (Essential Hyprland Only)

## About This Document

This document maps Arch Linux packages from the original HyDE project to their Ubuntu 24.04 LTS equivalents, **focusing only on essential packages required for Hyprland to function**.

**Target System:**
- Ubuntu 24.04.3 LTS (Noble)
- Architecture: amd64
- Package Manager: apt
- Init System: systemd

**Key Principles:**
- ✅ Only essential Hyprland packages included
- ❌ Optional applications (browsers, IDEs) excluded
- 🔧 Manual updates only (see `manual_update.sh`)
- 📋 Clear status indicators for each package

**Status Legend:**
- ✅ **Direct**: Available in Ubuntu main/universe repos
- ⚠️ **Minor Adjustment**: Available but requires PPA or different package name
- ❌ **Compilation Required**: Must be built from source
- 🔴 **No Equivalent**: Arch-specific, alternatives suggested

---

## 1. System Core Packages

### Wayland Session Manager

| Arch Package | Ubuntu Package | Status | Installation | Notes |
|--------------|----------------|--------|--------------|-------|
| `uwsm` | N/A | ❌ | Compile from source | Required since HyDE v25.8.2. See compilation section. |

**Installation for uwsm:**
```bash
# Install dependencies
sudo apt install -y git meson ninja-build python3-pip
pip3 install --user flit-core

# Clone and build
git clone https://github.com/Vladimir-csp/uwsm.git /tmp/uwsm
cd /tmp/uwsm
meson setup build
ninja -C build
sudo ninja -C build install
```

### Audio System

| Arch Package | Ubuntu Package | Status | Installation | Notes |
|--------------|----------------|--------|--------------|-------|
| `pipewire` | `pipewire` | ✅ | `sudo apt install pipewire` | Already in Ubuntu 24.04 |
| `pipewire-alsa` | `pipewire-alsa` | ✅ | `sudo apt install pipewire-alsa` | ALSA compatibility |
| `pipewire-audio` | `pipewire-audio-client-libraries` | ⚠️ | `sudo apt install pipewire-audio-client-libraries` | Different package name |
| `pipewire-jack` | `pipewire-jack` | ✅ | `sudo apt install pipewire-jack` | JACK compatibility |
| `pipewire-pulse` | `pipewire-pulse` | ✅ | `sudo apt install pipewire-pulse` | PulseAudio compatibility |
| `gst-plugin-pipewire` | `gstreamer1.0-pipewire` | ⚠️ | `sudo apt install gstreamer1.0-pipewire` | Different package name |
| `wireplumber` | `wireplumber` | ✅ | `sudo apt install wireplumber` | Session manager |
| `pavucontrol` | `pavucontrol` | ✅ | `sudo apt install pavucontrol` | Volume control GUI |
| `pamixer` | `pamixer` | ✅ | `sudo apt install pamixer` | CLI mixer |

**Single command for audio:**
```bash
sudo apt install -y pipewire pipewire-alsa pipewire-audio-client-libraries \
  pipewire-jack pipewire-pulse gstreamer1.0-pipewire wireplumber \
  pavucontrol pamixer
```

### Network & Bluetooth

| Arch Package | Ubuntu Package | Status | Installation | Notes |
|--------------|----------------|--------|--------------|-------|
| `networkmanager` | `network-manager` | ⚠️ | `sudo apt install network-manager` | Different package name |
| `network-manager-applet` | `network-manager-gnome` | ⚠️ | `sudo apt install network-manager-gnome` | Includes nm-applet |
| `bluez` | `bluez` | ✅ | `sudo apt install bluez` | Bluetooth stack |
| `bluez-utils` | `bluez-tools` | ⚠️ | `sudo apt install bluez-tools` | Different package name |
| `blueman` | `blueman` | ✅ | `sudo apt install blueman` | Bluetooth manager GUI |

**Single command for networking:**
```bash
sudo apt install -y network-manager network-manager-gnome bluez bluez-tools blueman
```

### System Utilities

| Arch Package | Ubuntu Package | Status | Installation | Notes |
|--------------|----------------|--------|--------------|-------|
| `brightnessctl` | `brightnessctl` | ✅ | `sudo apt install brightnessctl` | Screen brightness control |
| `playerctl` | `playerctl` | ✅ | `sudo apt install playerctl` | Media control |
| `udiskie` | `udiskie` | ✅ | `sudo apt install udiskie` | Auto-mount removable media |

**Single command for utilities:**
```bash
sudo apt install -y brightnessctl playerctl udiskie
```

---

## 2. Display Manager (SDDM)

| Arch Package | Ubuntu Package | Status | Installation | Notes |
|--------------|----------------|--------|--------------|-------|
| `sddm` | `sddm` | ✅ | `sudo apt install sddm` | Display manager |
| `qt5-quickcontrols` | `qml-module-qtquick-controls` | ⚠️ | `sudo apt install qml-module-qtquick-controls` | Different package name |
| `qt5-quickcontrols2` | `qml-module-qtquick-controls2` | ⚠️ | `sudo apt install qml-module-qtquick-controls2` | Different package name |
| `qt5-graphicaleffects` | `qml-module-qtgraphicaleffects` | ⚠️ | `sudo apt install qml-module-qtgraphicaleffects` | Different package name |

**Single command for SDDM:**
```bash
sudo apt install -y sddm qml-module-qtquick-controls \
  qml-module-qtquick-controls2 qml-module-qtgraphicaleffects
```

**Enable SDDM:**
```bash
sudo systemctl enable sddm
sudo systemctl set-default graphical.target
```

---

## 3. Window Manager & Compositor

### Hyprland

| Arch Package | Ubuntu Package | Status | Installation | Notes |
|--------------|----------------|--------|--------------|-------|
| `hyprland` | N/A | ❌ | Compile from source | Not in Ubuntu repos. See compilation section. |

**Hyprland Compilation:**
```bash
# Install build dependencies
sudo apt install -y git cmake ninja-build gcc g++ pkg-config \
  libwayland-dev libxkbcommon-dev libpixman-1-dev \
  libdrm-dev libgbm-dev libinput-dev libxcb-composite0-dev \
  libxcb-dri3-dev libxcb-present-dev libxcb-render-util0-dev \
  libxcb-res0-dev libxcb-ewmh-dev libxcb-icccm4-dev \
  libxcb-xinput-dev libxcb1-dev libx11-dev libx11-xcb-dev \
  libtomlplusplus-dev libzip-dev librsvg2-dev libmagic-dev \
  libseat-dev libudev-dev hwdata glslang-tools libdisplay-info-dev \
  libliftoff-dev libhyprlang-dev libhyprutils-dev libaquamarine-dev

# Clone and build Hyprland (latest stable)
git clone --recursive https://github.com/hyprwm/Hyprland /tmp/Hyprland
cd /tmp/Hyprland
make all
sudo make install
```

**Alternative: Use Hyprland PPA (if available):**
```bash
# Check for community PPA (not official, use at your own risk)
# As of 2026, check: https://launchpad.net/~hyprland-community
```

### Window Manager UI Components

| Arch Package | Ubuntu Package | Status | Installation | Notes |
|--------------|----------------|--------|--------------|-------|
| `dunst` | `dunst` | ✅ | `sudo apt install dunst` | Notification daemon |
| `rofi` | `rofi` | ✅ | `sudo apt install rofi` | Application launcher |
| `waybar` | `waybar` | ✅ | `sudo apt install waybar` | Wayland status bar |
| `swww` | N/A | ❌ | Compile from source | Wallpaper daemon. See compilation section. |
| `hyprlock` | N/A | ❌ | Compile from source | Lock screen. See compilation section. |
| `wlogout` | N/A | ❌ | Compile from source | Logout menu. See compilation section. |
| `hypridle` | N/A | ❌ | Compile from source | Idle daemon. See compilation section. |

**Single command for available packages:**
```bash
sudo apt install -y dunst rofi waybar
```

**swww Compilation:**
```bash
# Install Rust (if not installed)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Build swww
git clone https://github.com/LGFae/swww /tmp/swww
cd /tmp/swww
cargo build --release
sudo cp target/release/swww* /usr/local/bin/
```

**hyprlock Compilation:**
```bash
# Dependencies
sudo apt install -y libpam0g-dev

# Build hyprlock
git clone --recursive https://github.com/hyprwm/hyprlock /tmp/hyprlock
cd /tmp/hyprlock
cmake -B build
cmake --build build
sudo cmake --install build
```

**wlogout Compilation:**
```bash
# Dependencies
sudo apt install -y libgtk-layer-shell-dev libgtk-3-dev

# Build wlogout
git clone https://github.com/ArtsyMacaw/wlogout /tmp/wlogout
cd /tmp/wlogout
meson build
ninja -C build
sudo ninja -C build install
```

**hypridle Compilation:**
```bash
# Build hypridle
git clone --recursive https://github.com/hyprwm/hypridle /tmp/hypridle
cd /tmp/hypridle
cmake -B build
cmake --build build
sudo cmake --install build
```

### Screenshot & Screen Tools

| Arch Package | Ubuntu Package | Status | Installation | Notes |
|--------------|----------------|--------|--------------|-------|
| `grim` | `grim` | ✅ | `sudo apt install grim` | Screenshot tool |
| `hyprpicker` | N/A | ❌ | Compile from source | Color picker. See compilation section. |
| `slurp` | `slurp` | ✅ | `sudo apt install slurp` | Region selector |
| `satty` | N/A | ❌ | Compile from source | Screenshot annotation. See compilation section. |
| `cliphist` | N/A | ❌ | Compile from Go source | Clipboard manager |
| `wl-clip-persist` | N/A | ❌ | Compile from source | Clipboard persistence |
| `hyprsunset` | N/A | ❌ | Compile from source | Blue light filter |

**Single command for available packages:**
```bash
sudo apt install -y grim slurp
```

**hyprpicker Compilation:**
```bash
git clone --recursive https://github.com/hyprwm/hyprpicker /tmp/hyprpicker
cd /tmp/hyprpicker
cmake -B build
cmake --build build
sudo cmake --install build
```

**satty Compilation:**
```bash
# Install Rust if needed
git clone https://github.com/gabm/satty /tmp/satty
cd /tmp/satty
cargo build --release
sudo cp target/release/satty /usr/local/bin/
```

**cliphist Compilation:**
```bash
# Install Go if needed
sudo apt install -y golang-go
git clone https://github.com/sentriz/cliphist /tmp/cliphist
cd /tmp/cliphist
go build
sudo cp cliphist /usr/local/bin/
```

**wl-clip-persist Compilation:**
```bash
# Install Rust if needed
git clone https://github.com/Linus789/wl-clip-persist /tmp/wl-clip-persist
cd /tmp/wl-clip-persist
cargo build --release
sudo cp target/release/wl-clip-persist /usr/local/bin/
```

**hyprsunset Compilation:**
```bash
git clone --recursive https://github.com/hyprwm/hyprsunset /tmp/hyprsunset
cd /tmp/hyprsunset
cmake -B build
cmake --build build
sudo cmake --install build
```

---

## 4. Desktop Integration & Dependencies

### XDG Desktop Portals

| Arch Package | Ubuntu Package | Status | Installation | Notes |
|--------------|----------------|--------|--------------|-------|
| `polkit-gnome` | `polkit-gnome` | ✅ | `sudo apt install polkit-gnome` | Authentication agent |
| `xdg-desktop-portal-hyprland` | N/A | ❌ | Compile from source | Hyprland portal. See compilation section. |
| `xdg-desktop-portal-gtk` | `xdg-desktop-portal-gtk` | ✅ | `sudo apt install xdg-desktop-portal-gtk` | GTK portal (file picker) |
| `xdg-user-dirs` | `xdg-user-dirs` | ✅ | `sudo apt install xdg-user-dirs` | User directories |

**Single command for available packages:**
```bash
sudo apt install -y polkit-gnome xdg-desktop-portal-gtk xdg-user-dirs
```

**xdg-desktop-portal-hyprland Compilation:**
```bash
# Dependencies
sudo apt install -y libpipewire-0.3-dev libwayland-dev \
  libinih-dev libsdbus-c++-dev libhyprlang-dev libhyprutils-dev

# Build
git clone --recursive https://github.com/hyprwm/xdg-desktop-portal-hyprland /tmp/xdph
cd /tmp/xdph
cmake -B build
cmake --build build
sudo cmake --install build
```

### System Utilities

| Arch Package | Ubuntu Package | Status | Installation | Notes |
|--------------|----------------|--------|--------------|-------|
| `pacman-contrib` | N/A | 🔴 | N/A | Arch-specific. Use `apt-check` or custom script. |
| `parallel` | `parallel` | ✅ | `sudo apt install parallel` | Parallel processing |
| `jq` | `jq` | ✅ | `sudo apt install jq` | JSON processing |
| `imagemagick` | `imagemagick` | ✅ | `sudo apt install imagemagick` | Image processing |
| `libnotify` | `libnotify-bin` | ⚠️ | `sudo apt install libnotify-bin` | Different package name |

**Single command for utilities:**
```bash
sudo apt install -y parallel jq imagemagick libnotify-bin
```

**Alternative for pacman-contrib (update checks):**
```bash
# Ubuntu uses apt instead
# For update checking, use:
apt list --upgradable
# Or install update-notifier
sudo apt install -y update-notifier-common
```

### Fonts

| Arch Package | Ubuntu Package | Status | Installation | Notes |
|--------------|----------------|--------|--------------|-------|
| `noto-fonts-emoji` | `fonts-noto-color-emoji` | ⚠️ | `sudo apt install fonts-noto-color-emoji` | Different package name |

```bash
sudo apt install -y fonts-noto-color-emoji
```

### Qt/KDE Dependencies (for Dolphin, etc.)

| Arch Package | Ubuntu Package | Status | Installation | Notes |
|--------------|----------------|--------|--------------|-------|
| `qt5-imageformats` | `qt5-image-formats-plugins` | ⚠️ | `sudo apt install qt5-image-formats-plugins` | Image thumbnails |
| `ffmpegthumbs` | `ffmpegthumbs` | ✅ | `sudo apt install ffmpegthumbs` | Video thumbnails |
| `kde-cli-tools` | `kde-cli-tools` | ✅ | `sudo apt install kde-cli-tools` | KDE CLI tools |

**Note:** These are only needed if you choose to use KDE apps like Dolphin file manager.

---

## 5. Theming & Qt/GTK Support

| Arch Package | Ubuntu Package | Status | Installation | Notes |
|--------------|----------------|--------|--------------|-------|
| `nwg-look` | N/A | ❌ | Compile from Go source | GTK theme tool |
| `qt5ct` | `qt5ct` | ✅ | `sudo apt install qt5ct` | Qt5 config tool |
| `qt6ct` | `qt6ct` | ✅ | `sudo apt install qt6ct` | Qt6 config tool |
| `kvantum` | `qt6-style-kvantum` | ⚠️ | `sudo apt install qt6-style-kvantum` | Qt6 theme engine |
| `kvantum-qt5` | `qt5-style-kvantum` | ⚠️ | `sudo apt install qt5-style-kvantum` | Qt5 theme engine |
| `qt5-wayland` | `qt5-wayland` | ✅ | `sudo apt install qt5-wayland` | Qt5 Wayland support |
| `qt6-wayland` | `qt6-wayland` | ✅ | `sudo apt install qt6-wayland` | Qt6 Wayland support |

**Single command for theming:**
```bash
sudo apt install -y qt5ct qt6ct qt6-style-kvantum qt5-style-kvantum \
  qt5-wayland qt6-wayland
```

**nwg-look Compilation:**
```bash
# Install Go if needed
sudo apt install -y golang-go
git clone https://github.com/nwg-piotr/nwg-look /tmp/nwg-look
cd /tmp/nwg-look
make build
sudo make install
```

---

## 6. Summary: Essential Package Installation

### Quick Installation Script (Available Packages Only)

```bash
#!/bin/bash
# Ubuntu 24.04 - Essential Hyprland Packages (from repos)

# Enable universe repository
sudo add-apt-repository universe -y
sudo apt update

# Audio system
sudo apt install -y pipewire pipewire-alsa pipewire-audio-client-libraries \
  pipewire-jack pipewire-pulse gstreamer1.0-pipewire wireplumber \
  pavucontrol pamixer

# Network & Bluetooth
sudo apt install -y network-manager network-manager-gnome \
  bluez bluez-tools blueman

# System utilities
sudo apt install -y brightnessctl playerctl udiskie

# Display manager
sudo apt install -y sddm qml-module-qtquick-controls \
  qml-module-qtquick-controls2 qml-module-qtgraphicaleffects

# Window manager components (available in repos)
sudo apt install -y dunst rofi waybar grim slurp

# Desktop integration
sudo apt install -y polkit-gnome xdg-desktop-portal-gtk xdg-user-dirs

# Utilities
sudo apt install -y parallel jq imagemagick libnotify-bin

# Fonts
sudo apt install -y fonts-noto-color-emoji

# Theming
sudo apt install -y qt5ct qt6ct qt6-style-kvantum qt5-style-kvantum \
  qt5-wayland qt6-wayland

# Enable SDDM
sudo systemctl enable sddm
sudo systemctl set-default graphical.target

echo "✅ Available packages installed!"
echo "⚠️  Still need to compile: Hyprland, uwsm, swww, hyprlock, wlogout, etc."
echo "📖 See compilation instructions in UBUNTU_PACKAGE_MAPPING.md"
```

### Packages Requiring Compilation

**Critical (must compile):**
1. `hyprland` - The compositor itself
2. `uwsm` - Wayland session manager (required since v25.8.2)
3. `xdg-desktop-portal-hyprland` - Desktop integration

**Important (recommended):**
4. `swww` - Wallpaper daemon
5. `hyprlock` - Lock screen
6. `wlogout` - Logout menu
7. `hypridle` - Idle daemon

**Optional but useful:**
8. `hyprpicker` - Color picker
9. `satty` - Screenshot annotation
10. `cliphist` - Clipboard manager
11. `wl-clip-persist` - Clipboard persistence
12. `hyprsunset` - Blue light filter
13. `nwg-look` - GTK theme configuration

---

## 7. System Differences: Arch vs Ubuntu

### Service Management

| Feature | Arch | Ubuntu | Notes |
|---------|------|--------|-------|
| Service location | `/usr/lib/systemd/system/` | `/lib/systemd/system/` | Use `systemctl` for both |
| User services | `~/.config/systemd/user/` | Same | No difference |
| Enable services | `systemctl enable` | Same | No difference |

### Package Manager

| Feature | Arch | Ubuntu |
|---------|------|--------|
| Update DB | `pacman -Sy` | `apt update` |
| Upgrade | `pacman -Syu` | `apt upgrade` |
| Install | `pacman -S` | `apt install` |
| Search | `pacman -Ss` | `apt search` |
| Info | `pacman -Si` | `apt show` |

### Path Differences

| Resource | Arch | Ubuntu |
|----------|------|--------|
| Hyprland config | `~/.config/hypr/` | Same |
| Systemd user | `~/.config/systemd/user/` | Same |
| Local bin | `~/.local/bin` | Same |
| System bin | `/usr/bin` | `/usr/bin` or `/usr/local/bin` (compiled) |

---

## 8. Next Steps

1. **Install available packages** using the quick installation script above
2. **Compile required packages** following the compilation instructions
3. **Use manual update script** (`Scripts/ubuntu/manual_update.sh`) when you want to update
4. **Configure system** after installation:
   - Set up SDDM theme
   - Configure Hyprland settings
   - Set up GTK/Qt themes

---

## 9. Important Notes

### ⚠️ Differences from Arch HyDE

1. **AUR Helpers**: Not available on Ubuntu (yay, paru). Must compile AUR packages manually.
2. **Package names**: Many packages have different names (see mapping tables).
3. **Updates**: Ubuntu uses `apt`, not `pacman`. Update script adapted accordingly.
4. **Compilation**: Many Hyprland-ecosystem packages must be compiled from source.

### 🔒 No Automatic Updates

As requested, there are **NO automatic update mechanisms**. All updates must be done manually using:
- `sudo apt update && sudo apt upgrade` for system packages
- `Scripts/ubuntu/manual_update.sh` for Hyprland and compiled packages (see separate script)

### 📦 Universe Repository

Many packages require the Ubuntu Universe repository. Enable it:
```bash
sudo add-apt-repository universe
sudo apt update
```

### 🐧 Kernel Headers

If you have NVIDIA GPU and need drivers:
```bash
sudo apt install -y linux-headers-$(uname -r)
sudo apt install -y nvidia-driver-555  # or latest version
```

---

**Last Updated:** 2026-02-12  
**Target System:** Ubuntu 24.04.3 LTS (Noble)  
**HyDE Version:** Based on v25.9.x

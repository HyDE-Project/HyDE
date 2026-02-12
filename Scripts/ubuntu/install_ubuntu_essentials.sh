#!/usr/bin/env bash
#|---/ /+--------------------------------------------------+---/ /|#
#|--/ /-| Install Essential Ubuntu Packages for Hyprland  |--/ /-|#
#|-/ /--| Installs only packages available via apt        |-/ /--|#
#|/ /---+--------------------------------------------------+/ /---|#
#
# This script installs ONLY the packages available in Ubuntu repositories.
# Packages requiring compilation are listed separately.
#
# Usage: ./install_ubuntu_essentials.sh
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[✓]${NC} $*"
}

log_info() {
    echo -e "${BLUE}[i]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $*"
}

log_error() {
    echo -e "${RED}[✗]${NC} $*"
}

# Check if running on Ubuntu
if [ ! -f /etc/os-release ]; then
    log_error "Cannot detect OS"
    exit 1
fi

source /etc/os-release
if [[ "$ID" != "ubuntu" ]]; then
    log_error "This script is for Ubuntu only. Detected: $ID"
    exit 1
fi

log_info "Detected: $PRETTY_NAME"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    log_error "Please do NOT run this script as root or with sudo"
    log_info "The script will ask for sudo password when needed"
    exit 1
fi

cat << "EOF"
╔══════════════════════════════════════════════════════╗
║   Ubuntu 24.04 Essential Packages for Hyprland      ║
║                                                      ║
║   This installs packages available via apt.         ║
║   Compiled packages need separate installation.     ║
╚══════════════════════════════════════════════════════╝

EOF

log_info "This script will install essential packages for Hyprland"
log_warn "This does NOT install Hyprland itself (requires compilation)"
echo ""
read -p "Continue with installation? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warn "Installation cancelled"
    exit 0
fi

echo ""
log_info "Updating package database..."
sudo apt update

echo ""
log_info "Enabling universe repository..."
sudo add-apt-repository universe -y
sudo apt update

echo ""
log "Installing packages..."
echo ""

# Audio System
log_info "Installing audio system (PipeWire)..."
sudo apt install -y \
    pipewire \
    pipewire-alsa \
    pipewire-audio-client-libraries \
    pipewire-jack \
    pipewire-pulse \
    gstreamer1.0-pipewire \
    wireplumber \
    pavucontrol \
    pamixer
log "Audio system packages installed"

echo ""

# Network & Bluetooth
log_info "Installing network and bluetooth..."
sudo apt install -y \
    network-manager \
    network-manager-gnome \
    bluez \
    bluez-tools \
    blueman
log "Network and bluetooth packages installed"

echo ""

# System Utilities
log_info "Installing system utilities..."
sudo apt install -y \
    brightnessctl \
    playerctl \
    udiskie
log "System utilities installed"

echo ""

# Display Manager
log_info "Installing SDDM display manager..."
sudo apt install -y \
    sddm \
    qml-module-qtquick-controls \
    qml-module-qtquick-controls2 \
    qml-module-qtgraphicaleffects
log "SDDM packages installed"

echo ""

# Window Manager Components (available via apt)
log_info "Installing window manager components..."
sudo apt install -y \
    dunst \
    rofi \
    waybar \
    grim \
    slurp
log "Window manager components installed"

echo ""

# Desktop Integration
log_info "Installing desktop integration..."
sudo apt install -y \
    polkit-gnome \
    xdg-desktop-portal-gtk \
    xdg-user-dirs
log "Desktop integration packages installed"

echo ""

# Utilities
log_info "Installing utilities..."
sudo apt install -y \
    parallel \
    jq \
    imagemagick \
    libnotify-bin
log "Utilities installed"

echo ""

# Fonts
log_info "Installing fonts..."
sudo apt install -y \
    fonts-noto-color-emoji
log "Fonts installed"

echo ""

# Theming
log_info "Installing theming packages..."
sudo apt install -y \
    qt5ct \
    qt6ct \
    qt6-style-kvantum \
    qt5-style-kvantum \
    qt5-wayland \
    qt6-wayland
log "Theming packages installed"

echo ""
echo ""
log "✅ All available packages installed successfully!"
echo ""

# Enable SDDM
log_info "Enabling SDDM display manager..."
sudo systemctl enable sddm
sudo systemctl set-default graphical.target
log "SDDM enabled"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_warn "IMPORTANT: The following components still need to be compiled:"
echo ""
echo "  Critical (must compile):"
echo "    • hyprland - The compositor itself"
echo "    • uwsm - Wayland session manager"
echo "    • xdg-desktop-portal-hyprland - Desktop integration"
echo ""
echo "  Important (recommended):"
echo "    • swww - Wallpaper daemon"
echo "    • hyprlock - Lock screen"
echo "    • wlogout - Logout menu"
echo "    • hypridle - Idle daemon"
echo ""
echo "  Optional:"
echo "    • hyprpicker - Color picker"
echo "    • satty - Screenshot annotation"
echo "    • cliphist - Clipboard manager"
echo "    • wl-clip-persist - Clipboard persistence"
echo "    • hyprsunset - Blue light filter"
echo "    • nwg-look - GTK theme tool"
echo ""
log_info "See UBUNTU_PACKAGE_MAPPING.md for compilation instructions"
log_info "Or run: Scripts/ubuntu/compile_hyprland_ecosystem.sh"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Ask about compilation
read -p "Do you want to see compilation instructions now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    less Scripts/UBUNTU_PACKAGE_MAPPING.md
fi

log "Installation complete!"
log_info "Log out and log back in to use the new session manager"

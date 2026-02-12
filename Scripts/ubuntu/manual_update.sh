#!/usr/bin/env bash
#|---/ /+------------------------------------------+---/ /|#
#|--/ /-| Manual Update Script for Ubuntu HyDE    |--/ /-|#
#|-/ /--| Update Hyprland and compiled components |-/ /--|#
#|/ /---+------------------------------------------+/ /---|#
#
# This script provides MANUAL updates for Hyprland ecosystem on Ubuntu.
# It does NOT run automatically - you must execute it when you want to update.
#
# Usage:
#   ./manual_update.sh              # Interactive menu
#   ./manual_update.sh --all        # Update everything
#   ./manual_update.sh --system     # Update system packages only
#   ./manual_update.sh --hyprland   # Update Hyprland ecosystem only
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories
COMPILE_DIR="/tmp/hyprland-updates-$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$HOME/.local/share/hyde-backups/$(date +%Y%m%d-%H%M%S)"

# Logging
LOG_FILE="$HOME/.cache/hyde/manual_update_$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING:${NC} $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ERROR:${NC} $*" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO:${NC} $*" | tee -a "$LOG_FILE"
}

# Check if running on Ubuntu
check_system() {
    if [ ! -f /etc/os-release ]; then
        log_error "Cannot detect OS. /etc/os-release not found."
        exit 1
    fi
    
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        log_error "This script is designed for Ubuntu. Detected: $ID"
        exit 1
    fi
    
    log_info "Detected: $PRETTY_NAME"
}

# Create backup
create_backup() {
    log "Creating backup..."
    mkdir -p "$BACKUP_DIR"
    
    # Backup Hyprland config
    if [ -d "$HOME/.config/hypr" ]; then
        cp -r "$HOME/.config/hypr" "$BACKUP_DIR/" 2>/dev/null || true
    fi
    
    # Backup HyDE config
    if [ -d "$HOME/.config/hyde" ]; then
        cp -r "$HOME/.config/hyde" "$BACKUP_DIR/" 2>/dev/null || true
    fi
    
    log "Backup created at: $BACKUP_DIR"
}

# Update system packages (apt)
update_system_packages() {
    log "Updating system packages via apt..."
    
    sudo apt update
    
    echo ""
    log_info "Checking for upgradable packages..."
    UPGRADABLE=$(apt list --upgradable 2>/dev/null | grep -v "Listing" | wc -l)
    
    if [ "$UPGRADABLE" -gt 0 ]; then
        log_info "Found $UPGRADABLE package(s) to upgrade"
        apt list --upgradable 2>/dev/null | grep -v "Listing"
        echo ""
        read -p "Do you want to upgrade these packages? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo apt upgrade -y
            log "System packages updated successfully"
        else
            log_warn "System package upgrade skipped"
        fi
    else
        log "All system packages are up to date"
    fi
}

# Update Hyprland from source
update_hyprland() {
    log "Updating Hyprland..."
    
    mkdir -p "$COMPILE_DIR"
    cd "$COMPILE_DIR"
    
    # Clone latest version
    log_info "Cloning Hyprland repository..."
    git clone --recursive --depth 1 https://github.com/hyprwm/Hyprland.git
    cd Hyprland
    
    # Show current vs new version
    CURRENT_VERSION=$(hyprctl version 2>/dev/null | head -n1 || echo "Not installed")
    NEW_VERSION=$(git describe --tags 2>/dev/null || echo "Unknown")
    
    echo ""
    log_info "Current version: $CURRENT_VERSION"
    log_info "New version: $NEW_VERSION"
    echo ""
    
    read -p "Continue with Hyprland update? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warn "Hyprland update cancelled"
        return
    fi
    
    # Build and install
    log_info "Building Hyprland (this may take several minutes)..."
    make all
    sudo make install
    
    log "Hyprland updated successfully to: $NEW_VERSION"
}

# Update uwsm (Wayland session manager)
update_uwsm() {
    log "Updating uwsm (Wayland session manager)..."
    
    mkdir -p "$COMPILE_DIR"
    cd "$COMPILE_DIR"
    
    log_info "Cloning uwsm repository..."
    git clone --depth 1 https://github.com/Vladimir-csp/uwsm.git
    cd uwsm
    
    NEW_VERSION=$(git describe --tags 2>/dev/null || git rev-parse --short HEAD)
    log_info "New version: $NEW_VERSION"
    
    read -p "Continue with uwsm update? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warn "uwsm update cancelled"
        return
    fi
    
    log_info "Building uwsm..."
    meson setup build
    ninja -C build
    sudo ninja -C build install
    
    log "uwsm updated successfully"
}

# Update xdg-desktop-portal-hyprland
update_xdph() {
    log "Updating xdg-desktop-portal-hyprland..."
    
    mkdir -p "$COMPILE_DIR"
    cd "$COMPILE_DIR"
    
    log_info "Cloning xdg-desktop-portal-hyprland repository..."
    git clone --recursive --depth 1 https://github.com/hyprwm/xdg-desktop-portal-hyprland.git
    cd xdg-desktop-portal-hyprland
    
    NEW_VERSION=$(git describe --tags 2>/dev/null || git rev-parse --short HEAD)
    log_info "New version: $NEW_VERSION"
    
    read -p "Continue with xdg-desktop-portal-hyprland update? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warn "xdg-desktop-portal-hyprland update cancelled"
        return
    fi
    
    log_info "Building xdg-desktop-portal-hyprland..."
    cmake -B build
    cmake --build build
    sudo cmake --install build
    
    log "xdg-desktop-portal-hyprland updated successfully"
}

# Update hyprlock
update_hyprlock() {
    log "Updating hyprlock..."
    
    mkdir -p "$COMPILE_DIR"
    cd "$COMPILE_DIR"
    
    log_info "Cloning hyprlock repository..."
    git clone --recursive --depth 1 https://github.com/hyprwm/hyprlock.git
    cd hyprlock
    
    NEW_VERSION=$(git describe --tags 2>/dev/null || git rev-parse --short HEAD)
    log_info "New version: $NEW_VERSION"
    
    read -p "Continue with hyprlock update? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warn "hyprlock update cancelled"
        return
    fi
    
    log_info "Building hyprlock..."
    cmake -B build
    cmake --build build
    sudo cmake --install build
    
    log "hyprlock updated successfully"
}

# Update hypridle
update_hypridle() {
    log "Updating hypridle..."
    
    mkdir -p "$COMPILE_DIR"
    cd "$COMPILE_DIR"
    
    log_info "Cloning hypridle repository..."
    git clone --recursive --depth 1 https://github.com/hyprwm/hypridle.git
    cd hypridle
    
    NEW_VERSION=$(git describe --tags 2>/dev/null || git rev-parse --short HEAD)
    log_info "New version: $NEW_VERSION"
    
    read -p "Continue with hypridle update? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warn "hypridle update cancelled"
        return
    fi
    
    log_info "Building hypridle..."
    cmake -B build
    cmake --build build
    sudo cmake --install build
    
    log "hypridle updated successfully"
}

# Update swww (wallpaper daemon)
update_swww() {
    log "Updating swww (wallpaper daemon)..."
    
    if ! command -v cargo &> /dev/null; then
        log_error "Rust/Cargo not found. Please install Rust first:"
        log_error "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        return 1
    fi
    
    mkdir -p "$COMPILE_DIR"
    cd "$COMPILE_DIR"
    
    log_info "Cloning swww repository..."
    git clone --depth 1 https://github.com/LGFae/swww.git
    cd swww
    
    NEW_VERSION=$(git describe --tags 2>/dev/null || git rev-parse --short HEAD)
    log_info "New version: $NEW_VERSION"
    
    read -p "Continue with swww update? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warn "swww update cancelled"
        return
    fi
    
    log_info "Building swww..."
    cargo build --release
    sudo cp target/release/swww* /usr/local/bin/
    
    log "swww updated successfully"
}

# Update wlogout
update_wlogout() {
    log "Updating wlogout..."
    
    mkdir -p "$COMPILE_DIR"
    cd "$COMPILE_DIR"
    
    log_info "Cloning wlogout repository..."
    git clone --depth 1 https://github.com/ArtsyMacaw/wlogout.git
    cd wlogout
    
    NEW_VERSION=$(git describe --tags 2>/dev/null || git rev-parse --short HEAD)
    log_info "New version: $NEW_VERSION"
    
    read -p "Continue with wlogout update? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warn "wlogout update cancelled"
        return
    fi
    
    log_info "Building wlogout..."
    meson build
    ninja -C build
    sudo ninja -C build install
    
    log "wlogout updated successfully"
}

# Update all components
update_all() {
    log "=== Starting full system update ==="
    create_backup
    update_system_packages
    update_hyprland
    update_uwsm
    update_xdph
    update_hyprlock
    update_hypridle
    update_swww
    update_wlogout
    log "=== Full update complete ==="
}

# Show interactive menu
show_menu() {
    clear
    cat << "EOF"
╔══════════════════════════════════════════════════════╗
║     HyDE Manual Update Script for Ubuntu 24.04       ║
║                                                      ║
║  This script provides MANUAL updates only.          ║
║  No automatic updates will occur.                   ║
╚══════════════════════════════════════════════════════╝
EOF
    echo ""
    echo "Select what to update:"
    echo ""
    echo "  1) Update system packages (apt)"
    echo "  2) Update Hyprland"
    echo "  3) Update uwsm (session manager)"
    echo "  4) Update xdg-desktop-portal-hyprland"
    echo "  5) Update hyprlock"
    echo "  6) Update hypridle"
    echo "  7) Update swww (wallpaper)"
    echo "  8) Update wlogout"
    echo ""
    echo "  9) Update ALL components"
    echo "  0) Exit"
    echo ""
    read -p "Enter your choice [0-9]: " choice
    
    case $choice in
        1) create_backup; update_system_packages ;;
        2) create_backup; update_hyprland ;;
        3) create_backup; update_uwsm ;;
        4) create_backup; update_xdph ;;
        5) create_backup; update_hyprlock ;;
        6) create_backup; update_hypridle ;;
        7) create_backup; update_swww ;;
        8) create_backup; update_wlogout ;;
        9) update_all ;;
        0) log "Exiting..."; exit 0 ;;
        *) log_error "Invalid choice"; exit 1 ;;
    esac
}

# Main script
main() {
    echo ""
    log "=== HyDE Manual Update Script ==="
    log "Started at: $(date)"
    log "Log file: $LOG_FILE"
    echo ""
    
    # Check system
    check_system
    
    # Parse arguments
    if [ $# -eq 0 ]; then
        # No arguments - show interactive menu
        show_menu
    else
        case "$1" in
            --all)
                update_all
                ;;
            --system)
                create_backup
                update_system_packages
                ;;
            --hyprland)
                create_backup
                update_hyprland
                update_uwsm
                update_xdph
                update_hyprlock
                update_hypridle
                update_swww
                update_wlogout
                ;;
            --help|-h)
                cat << EOF
Usage: $0 [OPTION]

Manual update script for HyDE on Ubuntu 24.04.

Options:
  (no option)     Interactive menu
  --all           Update everything (system + Hyprland ecosystem)
  --system        Update system packages only (apt)
  --hyprland      Update Hyprland ecosystem only
  --help, -h      Show this help message

Examples:
  $0                    # Interactive menu
  $0 --all              # Update everything
  $0 --system           # Only update apt packages
  $0 --hyprland         # Only update Hyprland components

EOF
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                log_error "Use --help for usage information"
                exit 1
                ;;
        esac
    fi
    
    echo ""
    log "Update process completed at: $(date)"
    log "Full log available at: $LOG_FILE"
    
    # Cleanup
    if [ -d "$COMPILE_DIR" ]; then
        log_info "Cleaning up temporary build directory..."
        rm -rf "$COMPILE_DIR"
    fi
    
    echo ""
    log_warn "IMPORTANT: Consider restarting Hyprland to apply updates"
    log_info "Press Super+Shift+M to open the power menu, then select 'Logout'"
}

# Run main function
main "$@"

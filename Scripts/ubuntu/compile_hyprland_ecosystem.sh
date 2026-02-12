#!/usr/bin/env bash
#|---/ /+--------------------------------------------------+---/ /|#
#|--/ /-| Compile Hyprland Ecosystem for Ubuntu          |--/ /-|#
#|-/ /--| Builds essential Hyprland components from source|-/ /--|#
#|/ /---+--------------------------------------------------+/ /---|#
#
# This script compiles Hyprland and its essential components
# that are not available in Ubuntu repositories.
#
# Usage: ./compile_hyprland_ecosystem.sh [options]
#   --all           Compile all components
#   --critical      Compile only critical components (hyprland, uwsm, xdph)
#   --recommended   Compile critical + recommended (swww, hyprlock, etc.)
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

# Build directory
BUILD_DIR="/tmp/hyprland-build-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$HOME/.cache/hyde/compile_$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$(dirname "$LOG_FILE")"

log_info "Build directory: $BUILD_DIR"
log_info "Log file: $LOG_FILE"

# Check system
if [ ! -f /etc/os-release ]; then
    log_error "Cannot detect OS"
    exit 1
fi

source /etc/os-release
if [[ "$ID" != "ubuntu" ]]; then
    log_error "This script is for Ubuntu only. Detected: $ID"
    exit 1
fi

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    log_error "Please do NOT run this script as root or with sudo"
    log_info "The script will ask for sudo password when needed"
    exit 1
fi

# Install build dependencies
install_dependencies() {
    log_info "Installing build dependencies..."
    
    # Common build tools
    sudo apt install -y \
        git cmake ninja-build gcc g++ pkg-config \
        meson python3-pip flit-core
    
    # Hyprland dependencies
    sudo apt install -y \
        libwayland-dev libxkbcommon-dev libpixman-1-dev \
        libdrm-dev libgbm-dev libinput-dev libxcb-composite0-dev \
        libxcb-dri3-dev libxcb-present-dev libxcb-render-util0-dev \
        libxcb-res0-dev libxcb-ewmh-dev libxcb-icccm4-dev \
        libxcb-xinput-dev libxcb1-dev libx11-dev libx11-xcb-dev \
        libtomlplusplus-dev libzip-dev librsvg2-dev libmagic-dev \
        libseat-dev libudev-dev hwdata glslang-tools \
        libdisplay-info-dev libliftoff-dev
    
    # Additional dependencies for various components
    sudo apt install -y \
        libpam0g-dev \
        libgtk-layer-shell-dev libgtk-3-dev \
        libpipewire-0.3-dev \
        libinih-dev libsdbus-c++-dev \
        golang-go
    
    # Try to install hyprlang, hyprutils, aquamarine if available
    # These may not be in repos, but we'll try
    sudo apt install -y libhyprlang-dev libhyprutils-dev libaquamarine-dev 2>/dev/null || true
    
    log "Build dependencies installed"
}

# Check for Rust
check_rust() {
    if ! command -v cargo &> /dev/null; then
        log_warn "Rust not found. Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        log "Rust installed"
    else
        log_info "Rust already installed: $(rustc --version)"
    fi
}

# Compile Hyprland
compile_hyprland() {
    log_info "Compiling Hyprland..."
    
    cd "$BUILD_DIR"
    git clone --recursive https://github.com/hyprwm/Hyprland.git
    cd Hyprland
    
    log_info "Building Hyprland (this may take 10-20 minutes)..."
    make all 2>&1 | tee -a "$LOG_FILE"
    sudo make install 2>&1 | tee -a "$LOG_FILE"
    
    log "Hyprland compiled and installed"
}

# Compile uwsm
compile_uwsm() {
    log_info "Compiling uwsm (Wayland session manager)..."
    
    cd "$BUILD_DIR"
    git clone https://github.com/Vladimir-csp/uwsm.git
    cd uwsm
    
    meson setup build 2>&1 | tee -a "$LOG_FILE"
    ninja -C build 2>&1 | tee -a "$LOG_FILE"
    sudo ninja -C build install 2>&1 | tee -a "$LOG_FILE"
    
    log "uwsm compiled and installed"
}

# Compile xdg-desktop-portal-hyprland
compile_xdph() {
    log_info "Compiling xdg-desktop-portal-hyprland..."
    
    cd "$BUILD_DIR"
    git clone --recursive https://github.com/hyprwm/xdg-desktop-portal-hyprland.git
    cd xdg-desktop-portal-hyprland
    
    cmake -B build 2>&1 | tee -a "$LOG_FILE"
    cmake --build build 2>&1 | tee -a "$LOG_FILE"
    sudo cmake --install build 2>&1 | tee -a "$LOG_FILE"
    
    log "xdg-desktop-portal-hyprland compiled and installed"
}

# Compile swww
compile_swww() {
    log_info "Compiling swww (wallpaper daemon)..."
    check_rust
    
    cd "$BUILD_DIR"
    git clone https://github.com/LGFae/swww.git
    cd swww
    
    cargo build --release 2>&1 | tee -a "$LOG_FILE"
    sudo cp target/release/swww* /usr/local/bin/
    
    log "swww compiled and installed"
}

# Compile hyprlock
compile_hyprlock() {
    log_info "Compiling hyprlock..."
    
    cd "$BUILD_DIR"
    git clone --recursive https://github.com/hyprwm/hyprlock.git
    cd hyprlock
    
    cmake -B build 2>&1 | tee -a "$LOG_FILE"
    cmake --build build 2>&1 | tee -a "$LOG_FILE"
    sudo cmake --install build 2>&1 | tee -a "$LOG_FILE"
    
    log "hyprlock compiled and installed"
}

# Compile wlogout
compile_wlogout() {
    log_info "Compiling wlogout..."
    
    cd "$BUILD_DIR"
    git clone https://github.com/ArtsyMacaw/wlogout.git
    cd wlogout
    
    meson build 2>&1 | tee -a "$LOG_FILE"
    ninja -C build 2>&1 | tee -a "$LOG_FILE"
    sudo ninja -C build install 2>&1 | tee -a "$LOG_FILE"
    
    log "wlogout compiled and installed"
}

# Compile hypridle
compile_hypridle() {
    log_info "Compiling hypridle..."
    
    cd "$BUILD_DIR"
    git clone --recursive https://github.com/hyprwm/hypridle.git
    cd hypridle
    
    cmake -B build 2>&1 | tee -a "$LOG_FILE"
    cmake --build build 2>&1 | tee -a "$LOG_FILE"
    sudo cmake --install build 2>&1 | tee -a "$LOG_FILE"
    
    log "hypridle compiled and installed"
}

# Compile hyprpicker
compile_hyprpicker() {
    log_info "Compiling hyprpicker..."
    
    cd "$BUILD_DIR"
    git clone --recursive https://github.com/hyprwm/hyprpicker.git
    cd hyprpicker
    
    cmake -B build 2>&1 | tee -a "$LOG_FILE"
    cmake --build build 2>&1 | tee -a "$LOG_FILE"
    sudo cmake --install build 2>&1 | tee -a "$LOG_FILE"
    
    log "hyprpicker compiled and installed"
}

# Compile satty
compile_satty() {
    log_info "Compiling satty..."
    check_rust
    
    cd "$BUILD_DIR"
    git clone https://github.com/gabm/satty.git
    cd satty
    
    cargo build --release 2>&1 | tee -a "$LOG_FILE"
    sudo cp target/release/satty /usr/local/bin/
    
    log "satty compiled and installed"
}

# Compile cliphist
compile_cliphist() {
    log_info "Compiling cliphist..."
    
    cd "$BUILD_DIR"
    git clone https://github.com/sentriz/cliphist.git
    cd cliphist
    
    go build 2>&1 | tee -a "$LOG_FILE"
    sudo cp cliphist /usr/local/bin/
    
    log "cliphist compiled and installed"
}

# Compile wl-clip-persist
compile_wl_clip_persist() {
    log_info "Compiling wl-clip-persist..."
    check_rust
    
    cd "$BUILD_DIR"
    git clone https://github.com/Linus789/wl-clip-persist.git
    cd wl-clip-persist
    
    cargo build --release 2>&1 | tee -a "$LOG_FILE"
    sudo cp target/release/wl-clip-persist /usr/local/bin/
    
    log "wl-clip-persist compiled and installed"
}

# Compile hyprsunset
compile_hyprsunset() {
    log_info "Compiling hyprsunset..."
    
    cd "$BUILD_DIR"
    git clone --recursive https://github.com/hyprwm/hyprsunset.git
    cd hyprsunset
    
    cmake -B build 2>&1 | tee -a "$LOG_FILE"
    cmake --build build 2>&1 | tee -a "$LOG_FILE"
    sudo cmake --install build 2>&1 | tee -a "$LOG_FILE"
    
    log "hyprsunset compiled and installed"
}

# Compile nwg-look
compile_nwg_look() {
    log_info "Compiling nwg-look..."
    
    cd "$BUILD_DIR"
    git clone https://github.com/nwg-piotr/nwg-look.git
    cd nwg-look
    
    make build 2>&1 | tee -a "$LOG_FILE"
    sudo make install 2>&1 | tee -a "$LOG_FILE"
    
    log "nwg-look compiled and installed"
}

# Main menu
show_menu() {
    cat << "EOF"
╔══════════════════════════════════════════════════════╗
║   Compile Hyprland Ecosystem for Ubuntu 24.04       ║
║                                                      ║
║   This will compile components from source.         ║
║   This may take 30+ minutes depending on your CPU.  ║
╚══════════════════════════════════════════════════════╝

EOF
    echo "Select what to compile:"
    echo ""
    echo "  1) Critical components only (hyprland, uwsm, xdph)"
    echo "  2) Recommended set (critical + swww, hyprlock, wlogout, hypridle)"
    echo "  3) All components (including optional tools)"
    echo "  4) Custom selection (choose individual components)"
    echo "  0) Exit"
    echo ""
    read -p "Enter your choice [0-4]: " choice
    
    mkdir -p "$BUILD_DIR"
    
    case $choice in
        1)
            install_dependencies
            compile_hyprland
            compile_uwsm
            compile_xdph
            ;;
        2)
            install_dependencies
            compile_hyprland
            compile_uwsm
            compile_xdph
            compile_swww
            compile_hyprlock
            compile_wlogout
            compile_hypridle
            ;;
        3)
            install_dependencies
            compile_hyprland
            compile_uwsm
            compile_xdph
            compile_swww
            compile_hyprlock
            compile_wlogout
            compile_hypridle
            compile_hyprpicker
            compile_satty
            compile_cliphist
            compile_wl_clip_persist
            compile_hyprsunset
            compile_nwg_look
            ;;
        4)
            custom_selection
            ;;
        0)
            log_info "Exiting..."
            exit 0
            ;;
        *)
            log_error "Invalid choice"
            exit 1
            ;;
    esac
}

# Custom selection
custom_selection() {
    install_dependencies
    
    echo ""
    echo "Select components to compile (separate with spaces):"
    echo "  1) hyprland          8) hyprpicker"
    echo "  2) uwsm              9) satty"
    echo "  3) xdph             10) cliphist"
    echo "  4) swww             11) wl-clip-persist"
    echo "  5) hyprlock         12) hyprsunset"
    echo "  6) wlogout          13) nwg-look"
    echo "  7) hypridle"
    echo ""
    read -p "Enter numbers (e.g., 1 2 3): " -a selections
    
    for sel in "${selections[@]}"; do
        case $sel in
            1) compile_hyprland ;;
            2) compile_uwsm ;;
            3) compile_xdph ;;
            4) compile_swww ;;
            5) compile_hyprlock ;;
            6) compile_wlogout ;;
            7) compile_hypridle ;;
            8) compile_hyprpicker ;;
            9) compile_satty ;;
            10) compile_cliphist ;;
            11) compile_wl_clip_persist ;;
            12) compile_hyprsunset ;;
            13) compile_nwg_look ;;
            *) log_warn "Invalid selection: $sel" ;;
        esac
    done
}

# Parse command line arguments
if [ $# -eq 0 ]; then
    show_menu
else
    case "$1" in
        --all)
            mkdir -p "$BUILD_DIR"
            install_dependencies
            compile_hyprland
            compile_uwsm
            compile_xdph
            compile_swww
            compile_hyprlock
            compile_wlogout
            compile_hypridle
            compile_hyprpicker
            compile_satty
            compile_cliphist
            compile_wl_clip_persist
            compile_hyprsunset
            compile_nwg_look
            ;;
        --critical)
            mkdir -p "$BUILD_DIR"
            install_dependencies
            compile_hyprland
            compile_uwsm
            compile_xdph
            ;;
        --recommended)
            mkdir -p "$BUILD_DIR"
            install_dependencies
            compile_hyprland
            compile_uwsm
            compile_xdph
            compile_swww
            compile_hyprlock
            compile_wlogout
            compile_hypridle
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Usage: $0 [--all|--critical|--recommended]"
            exit 1
            ;;
    esac
fi

# Cleanup
log_info "Cleaning up build directory..."
rm -rf "$BUILD_DIR"

echo ""
log "✅ Compilation complete!"
log_info "Full log available at: $LOG_FILE"
echo ""
log_warn "IMPORTANT: Reboot or restart your display manager to use Hyprland"
log_info "systemctl restart sddm  # Or reboot"

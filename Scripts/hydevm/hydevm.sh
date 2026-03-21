#!/usr/bin/env bash

# HydeVM - Simplified VM tool for HyDE contributors
# Works on Arch Linux, NixOS, and FreeBSD with automatic OS detection

set -e

# Configuration
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/hydevm"
BASE_IMAGE="$CACHE_DIR/archbase.qcow2"
SNAPSHOTS_DIR="$CACHE_DIR/snapshots"
HYDE_REPO="https://github.com/HyDE-Project/HyDE.git"

COMMON_PACKAGES=(
  "curl" "python" "git"
)

# Required packages for Arch Linux
ARCH_PACKAGES=(
    "qemu-desktop"
    "${COMMON_PACKAGES[@]}"
)

# Required packages for FreeBSD
FREEBSD_PACKAGES=(
    "qemu"
    "${COMMON_PACKAGES[@]}"
)

# Create cache directories
mkdir -p "$CACHE_DIR" "$SNAPSHOTS_DIR"

function detect_os() {
    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        if [[ "$ID" == "nixos" ]]; then
            echo "nixos"
        elif [[ "$ID" == "arch" ]]; then
            echo "arch"
        elif [[ "$ID" == "freebsd" ]]; then
            echo "freebsd"
        else
            echo "unknown"
        fi
    elif command -v nixos-version >/dev/null 2>&1; then
        echo "nixos"
    elif command -v pacman >/dev/null 2>&1; then
        echo "arch"
    elif [[ "$(uname -s)" == "FreeBSD" ]]; then
        echo "freebsd"
    elif [[ "$(uname -s)" == "Darwin" ]]; then
        echo "darwin"
    else
        echo "unknown"
    fi
}

function print_usage() {
    echo "HydeVM - Simplified VM tool for HyDE contributors"
    echo "Supports: Arch Linux, NixOS, FreeBSD, and Darwin"
    echo ""
    echo "Usage: hydevm [OPTIONS] [BRANCH/COMMIT]"
    echo ""
    echo "Arguments:"
    echo "  BRANCH/COMMIT            Git branch or commit hash (default: master)"
    echo ""
    echo "Options:"
    echo "  --persist               Make VM changes persistent"
    echo "  --list                  List available snapshots"
    echo "  --clean                 Clean all cached data"
    echo "  --install-deps          Install required dependencies (Arch, FreeBSD, Darwin)"
    echo "  --check-deps            Check if dependencies are installed"
    echo "  --help                  Show this help"
    echo ""
    echo "Environment Variables:"
    echo "  VM_MEMORY=8G            Set VM memory (default: 4G)"
    echo "  VM_CPUS=4               Set VM CPU count (default: 2)"
    echo "  VM_EXTRA_ARGS=\"args\"     Add extra QEMU arguments"
    echo "  VM_QEMU_OVERRIDE=\"cmd\"   Override entire QEMU command (\$VM_DISK substituted)"
    echo ""
    echo "Examples:"
    echo "  hydevm                  # Run master branch"
    echo "  hydevm --persist        # Run master branch (persistent)"
    echo "  hydevm feature-branch   # Run specific branch"
    echo "  hydevm abc123           # Run specific commit"
    echo "  hydevm --persist dev    # Run dev branch with persistence"
    echo ""
    echo "Auto-detected OS-specific install notes:"
    echo "  Arch Linux: Missing packages will be offered for installation via 'pacman'"
    echo "  NixOS:      Missing packages will be installed via 'nix shell'"
    echo "  FreeBSD:    Missing packages will be installed via 'pkg'"
    echo "  Darwin :    Missing packages can be installed via ''nix shell', 'brew', or direct download"
}

function check_root() {
    if [ "$EUID" -eq 0 ]; then
        echo "❌ Please don't run this script as root"
        local os
        os=$(detect_os)
        if [[ "$os" == "arch" ]]; then
            echo "   Use --install-deps to install dependencies with sudo"
        fi
        exit 1
    fi
}

function check_dependencies() {
    local os
    os=$(detect_os)

    case "$os" in
        "nixos")
            check_nixos_dependencies
            ;;
        "arch")
            check_arch_dependencies
            ;;
        "freebsd")
            check_freebsd_dependencies
            ;;
        "darwin")
            check_darwin_dependencies
            ;;
        *)
            echo "⚠️  Unsupported OS. This script supports Arch Linux, NixOS, and FreeBSD."
            echo "   Please ensure qemu, curl, python, and git are installed."
            return 0
            ;;
    esac
}

function check_nixos_dependencies() {
    local missing_commands=()

    # Check for required commands
    for cmd in qemu-system-x86_64 curl python git; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done

    if [ ${#missing_commands[@]} -gt 0 ]; then
        echo "❌ Missing required commands: ${missing_commands[*]}"
        echo ""
        echo "On NixOS, you can:"
        echo "  1. Use nix-shell: nix-shell -p qemu curl python3 git"
        echo "  2. Add to your configuration.nix: environment.systemPackages = with pkgs; [ qemu curl python3 git ];"
        echo "  3. Install temporarily: nix-env -iA nixpkgs.qemu nixpkgs.curl nixpkgs.python3 nixpkgs.git"
        return 1
    fi

    # Check if KVM is available
    if [ ! -r /dev/kvm ]; then
        echo "⚠️  KVM not available. VM will run slower."
        echo "   On NixOS, ensure virtualisation.libvirtd.enable = true; in configuration.nix"
        echo "   Or add your user to the kvm group and rebuild."
    fi

    return 0
}

function check_arch_dependencies() {
    local missing_packages=()

    for package in "${ARCH_PACKAGES[@]}"; do
        if ! pacman -Q "$package" &>/dev/null; then
            missing_packages+=("$package")
        fi
    done

    if [ ${#missing_packages[@]} -gt 0 ]; then
        echo "❌ Missing required packages: ${missing_packages[*]}"
        echo ""
        read -p "Would you like to install them now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_arch_packages "${missing_packages[@]}"
        else
            echo "   You can install them manually with: sudo pacman -S ${missing_packages[*]}"
            return 1
        fi
    fi

    # Check if KVM is available
    if [ ! -r /dev/kvm ]; then
        echo "⚠️  KVM not available. VM will run slower."
        echo "   Make sure your user is in the 'kvm' group: sudo usermod -a -G kvm $USER"
        echo "   Then logout and login again."
    fi

    return 0
}

function check_freebsd_dependencies() {
    local missing_packages=()

    for package in "${FREEBSD_PACKAGES[@]}"; do
        if ! pkg info -e "$package" > /dev/null 2>&1; then
            missing_packages+=("$package")
        fi
    done

    if [ ${#missing_packages[@]} -gt 0 ]; then
        echo "❌ Missing required packages: ${missing_packages[*]}"
        echo ""
        read -p "Would you like to install them now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_freebsd_packages "${missing_packages[@]}"
        else
            echo "   You can install them manually with: sudo pkg install ${missing_packages[*]}"
            return 1
        fi
    fi

    # Check if qemu is available; if not, prompt for QEMU or bhyve setup
    if ! command -v qemu >/dev/null 2>&1; then
        cat <<'EOF'
⚠️  Additional system setup is required (not applied automatically).
❌  QEMU not available.
   You can use either QEMU or bhyve on FreeBSD.

   1) QEMU
   2) bhyve

EOF
        read -p "Choose a virtualization backend to set up (1/2, or anything else to skip): " -r

        if [[ $REPLY == "1" ]]; then
            cat <<'EOF'
Adopted from [Chapter 24.6. Virtualization with QEMU on FreeBSD](https://docs.freebsd.org/en/books/handbook/virtualization/#qemu-virtualization-host-guest) by @MFarabi619
   To set up QEMU, run:
   sudo pkg install qemu

   # Fix missing or broken qemu symlink
   if [ "$(readlink /usr/local/bin/qemu)" != "/usr/local/bin/qemu-system-x86_64" ]; then
     sudo ln -sf /usr/local/bin/qemu-system-x86_64 /usr/local/bin/qemu
   fi

   sudo sysctl net.link.tap.user_open=1
   sudo grep -qxF "net.link.tap.user_open=1" /etc/sysctl.conf || \
   echo 'net.link.tap.user_open=1' | sudo tee -a /etc/sysctl.conf
   sudo grep -qxF "add path 'tap*' mode 0660 group operator" /etc/devfs.rules || \
   printf "add path 'tap*' mode 0660 group operator\n" | sudo tee -a /etc/devfs.rules

   Then test with:
   qemu
EOF
        elif [[ $REPLY == "2" ]]; then
            cat <<'EOF'
Adopted from [Chapter 24.6. Virtualization with bhyve on FreeBSD](https://docs.freebsd.org/en/books/handbook/virtualization/#virtualization-host-bhyve) by @MFarabi619
   To set up bhyve, run:
   sudo kldload vmm

   sudo ifconfig tap0 create
   sudo sysctl net.link.tap.up_on_open=1
   sudo grep -qxF "net.link.tap.up_on_open=1" /etc/sysctl.conf || \
   echo 'net.link.tap.up_on_open=1' | sudo tee -a /etc/sysctl.conf
   sudo grep -qxF "add path 'tap*' mode 0660 group operator" /etc/devfs.rules || \
   printf "add path 'tap*' mode 0660 group operator\n" | sudo tee -a /etc/devfs.rules

   sudo ifconfig bridge0 create
   sudo ifconfig bridge0 addm igb0 addm tap0
   sudo ifconfig bridge0 up
EOF
        else
            echo "   Skipping virtualization backend setup."
        fi
    fi

    # Check if /dev/vmm exists for bhyve acceleration
if ! kldstat -q -m vmm; then
    cat <<'EOF'
⚠️  bhyve/VMM not available. Native FreeBSD virtualization may not work.
  Make sure the vmm module is loaded: sudo kldload vmm
EOF
fi

    # Check if tap access is likely unavailable for non-root users
    if ! sysctl -n net.link.tap.user_open >/dev/null 2>&1 || [ "$(sysctl -n net.link.tap.user_open 2>/dev/null)" != "1" ]; then
        cat <<'EOF'
⚠️  Non-root tap access is not enabled.
   To enable it, run: sudo sysctl net.link.tap.user_open=1
   Then persist it in /etc/sysctl.conf.
EOF
    fi

    return 0
}

check_darwin_dependencies() {
    if [[ "$(uname -p 2>/dev/null || true)" != "arm" && "$(uname -p 2>/dev/null || true)" != "arm64" ]]; then
        echo "❌ x86_64-darwin is not supported"
        exit 1
    fi

    # NOTE: temporary UTM-first workflow for Darwin. Later we should simplify
    # this by removing UTM and driving qemu directly.
    if command -v utmctl >/dev/null 2>&1; then
        echo "UTM version $(utmctl version) is installed"

        if [[ "${HYDEVM_CHECK_DEPS_ONLY:-0}" == "1" ]]; then
            echo "Supported VM guests on macOS Host: NixOS, FreeBSD"
            return 0
        fi

        echo "Supported VM guests on macOS Host: NixOS, FreeBSD"
        echo ""
        echo "Choose a VM target OS:"
        echo "  1) NixOS"
        echo "  2) FreeBSD"
        read -r -p "Select target OS (1/2): " reply

        if [[ "$reply" == "1" ]]; then
            HYDEVM_DARWIN_TARGET="nixos"
            export HYDEVM_DARWIN_TARGET
            echo "Selected target: NixOS"
            exit 0
        elif [[ "$reply" == "2" ]]; then
            HYDEVM_DARWIN_TARGET="freebsd"
            export HYDEVM_DARWIN_TARGET
            echo "Selected target: FreeBSD"
            exit 0
        fi

        echo "❌ Invalid selection. Please choose 1 for NixOS or 2 for FreeBSD."
        return 1
    fi

    if command -v nix >/dev/null 2>&1; then
        cat <<'EOF'
❌ UTM is not installed.

You can set it up with nix using:
  nix shell nixpkgs#utm

Or manually:
1. Install UTM via https://mac.getutm.app.
2. Install UTM via brew (requires brew): brew install --cask utm
3. Install UTM via Determinate Nix (if needed):
   curl -fsSL https://install.determinate.systems/nix | sh -s -- install
   Then use a nix shell, home manager, or nix-darwin.

For nix-darwin, ensure Homebrew paths are available when using Homebrew-managed UTM:
environment.systemPath = [
  "/usr/local/bin"
  "/opt/homebrew/bin"
];

More info: https://nix-darwin.github.io/nix-darwin/manual/index.html#opt-homebrew.enable
EOF
        return 1
    fi

    if command -v brew >/dev/null 2>&1; then
        cat <<'EOF'
❌ UTM is not installed.

Homebrew is available. Install UTM with:
  brew install --cask utm

Or manually:
1. Install UTM via https://mac.getutm.app.
2. Install UTM via Determinate Nix:
   curl -fsSL https://install.determinate.systems/nix | sh -s -- install
   Then use a nix shell, home manager, or nix-darwin.

For nix-darwin, ensure Homebrew paths are available when using Homebrew-managed UTM:
environment.systemPath = [
  "/usr/local/bin"
  "/opt/homebrew/bin"
];

More info: https://nix-darwin.github.io/nix-darwin/manual/index.html#opt-homebrew.enable
EOF
        return 1
    fi

    cat <<'EOF'
UTM is required on macOS for the current HyDE VM flow.

You can set it up manually in one of these ways:
1. Install UTM via https://mac.getutm.app.
2. Install UTM via brew, requires installing brew.
3. Install UTM via Determinate Nix, requires installing Determinate nix with:
   curl -fsSL https://install.determinate.systems/nix | sh -s -- install
   Then use a nix shell, home manager, or nix-darwin.
EOF

    return 1
}

function install_darwin_dependencies() {
    if [[ "$(uname -p 2>/dev/null || true)" != "arm" && "$(uname -p 2>/dev/null || true)" != "arm64" ]]; then
        echo "❌ x86_64-darwin is not supported"
        exit 1
    fi

    if command -v utmctl >/dev/null 2>&1; then
        echo "✅ UTM is already installed: $(utmctl version)"
        return 0
    fi

    echo "📦 UTM is required on macOS for the current HyDE VM flow."

    if command -v brew >/dev/null 2>&1; then
        read -r -p "Install UTM with Homebrew now? (y/N): " reply
        if [[ "$reply" =~ ^[Yy]$ ]]; then
            brew install --cask utm
            return 0
        fi
    fi

    if command -v nix >/dev/null 2>&1; then
        read -r -p "Open nix shell with UTM now (nix shell nixpkgs#utm)? (y/N): " reply
        if [[ "$reply" =~ ^[Yy]$ ]]; then
            nix shell nixpkgs#utm
            echo "Re-run hydevm after entering the nix shell."
            return 1
        fi
    fi

    cat <<'EOF'
Install UTM manually with one of these options:
1. Install UTM via https://mac.getutm.app.
2. Install UTM via brew, requires installing brew.
3. Install UTM via Determinate Nix, requires installing Determinate nix with:
   curl -fsSL https://install.determinate.systems/nix | sh -s -- install
   Then use a nix shell, home manager, or nix-darwin.

For nix-darwin, ensure Homebrew paths are available when using Homebrew-managed UTM:
environment.systemPath = [
  "/usr/local/bin"
  "/opt/homebrew/bin"
];

More info: https://nix-darwin.github.io/nix-darwin/manual/index.html#opt-homebrew.enable
EOF

    return 1
}

function install_arch_packages() {
    local packages=("$@")

    echo "📦 Installing missing packages: ${packages[*]}"

    # Update package database
    echo "🔄 Updating package database..."
    sudo pacman -Sy

    # Install required packages
    echo "📥 Installing packages..."
    sudo pacman -S --needed "${packages[@]}"

    # Add user to kvm group if it exists and we installed qemu
    if [[ " ${packages[*]} " =~ " qemu-desktop " ]] && getent group kvm >/dev/null; then
        echo "👥 Adding user to kvm group..."
        sudo usermod -a -G kvm "$USER"
        echo "⚠️  Please logout and login again for group changes to take effect"
    fi

    echo "✅ Packages installed successfully"
}

function install_freebsd_packages() {
    local packages=("$@")

    echo "📦 Installing missing packages: ${packages[*]}"

    # Update package database
    echo "🔄 Updating package database..."
    sudo pkg update

    # Install required packages
    echo "📥 Installing packages..."
    sudo pkg install -y "${packages[@]}"

    echo "✅ Packages installed successfully"
}

function install_all_dependencies() {
    local os
    os=$(detect_os)

    if [[ "$os" != "arch" && "$os" != "freebsd" && "$os" != "darwin" ]]; then
        echo "❌ --install-deps is only supported on Arch Linux, FreeBSD, and Darwin"
        echo "   Current OS: $os"
        exit 1
    fi

    echo "📦 Installing all HydeVM dependencies..."

    if [[ "$os" == "arch" ]]; then
        install_arch_packages "${ARCH_PACKAGES[@]}"
    echo "💡 You may need to reboot or logout/login for all changes to take effect"
    elif [[ "$os" == "freebsd" ]]; then
        install_freebsd_packages "${FREEBSD_PACKAGES[@]}"
    elif [[ "$os" == "darwin" ]]; then
        install_darwin_dependencies
    fi
}

function check_deps_only() {
    local os
    local memory
    local accel_available
    local accel_label
    local cpu_cores

    os=$(detect_os)
    echo "🔍 Checking HydeVM dependencies..."
    echo "   Detected OS: $os"

    HYDEVM_CHECK_DEPS_ONLY=1
    export HYDEVM_CHECK_DEPS_ONLY
    if check_dependencies; then
        unset HYDEVM_CHECK_DEPS_ONLY
        echo "✅ All dependencies are installed"

        # Check additional system info
        echo ""
        echo "📊 System Information:"
        cpu_cores="$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo "Unknown")"

        case "$os" in
            freebsd)
                memory="$(sysctl -n hw.physmem 2>/dev/null | awk '{printf "%.1fGiB", $1/1024/1024/1024}' || echo "Unknown")"
                accel_available="$(kldstat -q -m vmm && echo "Yes" || echo "No")"
                accel_label="BSD Hypervisor (bhyve)"
                ;;
            darwin)
                memory="$(sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.1fGiB", $1/1024/1024/1024}' || echo "Unknown")"

                if command -v qemu-system-aarch64 >/dev/null 2>&1 && \
                  qemu-system-aarch64 -accel help 2>/dev/null | grep -q hvf; then
                    accel_available="Yes"
                else
                    accel_available="No"
                fi

                accel_label="Apple HVF"
                ;;
            *)
                memory="$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}' || echo "Unknown")"
                accel_available="$([ -r /dev/kvm ] && echo "Yes" || echo "No")"
                accel_label="KVM"
                ;;
        esac

        echo "   CPU cores: $cpu_cores"
        echo "   Memory: $memory"
        echo "   $accel_label: $accel_available"

        if command -v qemu-system-x86_64 >/dev/null 2>&1; then
            echo "   QEMU version: $(qemu-system-x86_64 --version | head -1)"
        fi

        return 0
    else
        unset HYDEVM_CHECK_DEPS_ONLY
        return 1
    fi
}

function get_qemu_command() {
    # Try to find qemu-system-x86_64 in common locations
    if command -v qemu-system-x86_64 >/dev/null 2>&1; then
        echo "qemu-system-x86_64"
    elif [ -x "/usr/bin/qemu-system-x86_64" ]; then
        echo "/usr/bin/qemu-system-x86_64"
    elif [ -x "/usr/local/bin/qemu-system-x86_64" ]; then
        echo "/usr/local/bin/qemu-system-x86_64"
    else
        echo "qemu-system-x86_64"  # fallback
    fi
}

function get_python_command() {
    # Try to find python in common locations
    if command -v python3 >/dev/null 2>&1; then
        echo "python3"
    elif command -v python >/dev/null 2>&1; then
        echo "python"
    else
        echo "python3"  # fallback
    fi
}

function run_qemu_vm() {
    local vm_disk="$1"
    local memory="${2:-4G}"
    local cpus="${3:-2}"
    local extra_args="${4:-}"
    local qemu_cmd
    qemu_cmd=$(get_qemu_command)

    # Check if user wants to override QEMU command entirely
    if [ -n "${VM_QEMU_OVERRIDE:-}" ]; then
        echo "🔧 Using custom QEMU command override..."
        # Substitute $VM_DISK in the override command
        local qemu_override_cmd
        qemu_override_cmd=${VM_QEMU_OVERRIDE//\$VM_DISK/$vm_disk}
        eval "$qemu_override_cmd"
    else
        # Build QEMU command arguments
        local qemu_args=(
            -m "$memory"
            -smp "$cpus"
            -drive "file=$vm_disk,format=qcow2,if=virtio"
            -device virtio-vga-gl
            -display "gtk,gl=on,grab-on-hover=on"
            -boot "menu=on"
        )

        # Add KVM-specific arguments
        if [ -r /dev/kvm ]; then
            qemu_args+=(-enable-kvm -cpu host)
        else
            qemu_args+=(-cpu qemu64)
        fi

        # Add network arguments if extra_args are provided
        if [ -n "$extra_args" ]; then
            qemu_args+=(-device "virtio-net,netdev=net0" -netdev "user,id=net0,$extra_args")
        fi

        # Add any extra VM arguments
        if [ -n "${VM_EXTRA_ARGS:-}" ]; then
            # shellcheck disable=SC2086
            read -ra extra_vm_args <<< "$VM_EXTRA_ARGS"
            qemu_args+=("${extra_vm_args[@]}")
        fi

        # Execute QEMU with all arguments
        "$qemu_cmd" "${qemu_args[@]}"
    fi
}

function get_latest_arch_image_url() {
    echo "https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-basic.qcow2"
}

function download_archbox() {
    if [ ! -f "$BASE_IMAGE" ]; then
        echo "📦 Downloading Arch Linux base image..."
        local latest_url
        latest_url=$(get_latest_arch_image_url)
        curl -L "$latest_url" -o "$BASE_IMAGE"
        echo "✅ Base image downloaded successfully"
    fi
}

function get_latest_freebsd_image_url() {
    echo "https://download.freebsd.org/releases/VM-IMAGES/15.0-RELEASE/amd64/Latest/FreeBSD-15.0-RELEASE-amd64-ufs.qcow2.xz"
}

function download_freebsdbox() {
    if [ ! -f "$BASE_IMAGE" ]; then
        echo "📦 Downloading FreeBSD base image..."
        local latest_url
        latest_url=$(get_latest_freebsd_image_url)
        curl -L "$latest_url" -o "$BASE_IMAGE"
        echo "✅ Base image downloaded successfully"
    fi
}

function get_snapshot_name() {
    local ref="$1"
    if [ -z "$ref" ]; then
        echo "master"
    else
        # Sanitize branch/commit name for filename
        echo "${ref//[^a-zA-Z0-9._-]/_}"
    fi
}

function create_hyde_snapshot() {
    local ref="${1:-master}"
    local snapshot_name
    snapshot_name=$(get_snapshot_name "$ref")
    local snapshot_path="$SNAPSHOTS_DIR/hyde-$snapshot_name.qcow2"
    local qemu_cmd
    qemu_cmd=$(get_qemu_command)
    local python_cmd
    python_cmd=$(get_python_command)

    # Check if snapshot already exists
    if [ -f "$snapshot_path" ]; then
        echo "📸 Snapshot for '$ref' already exists"
        return 0
    fi

    echo "🔨 Creating HyDE snapshot for '$ref'..."

    # Create temporary VM image for setup
    local temp_image="$CACHE_DIR/temp-setup.qcow2"
    qemu-img create -f qcow2 -F qcow2 -b "$BASE_IMAGE" "$temp_image"

    # Create setup script that will be available in the VM
    local setup_script="$CACHE_DIR/setup.sh"
    cat > "$setup_script" <<SETUP_EOF
#!/bin/bash
set -e

echo "🚀 Setting up HyDE environment for branch/commit: $ref"

# Set root password for convenience
echo "🔐 Setting root password..."
echo -e "hydevm\nhydevm" | sudo passwd root

# Update system and install dependencies
echo "📦 Updating system and installing dependencies..."
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm git base-devel openssh curl

# Configure SSH
echo "🔧 Configuring SSH..."
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl enable sshd

# Clone or update HyDE repository
echo "📥 Setting up HyDE repository..."
cd /home/arch
if [ -d "HyDE" ]; then
    echo "   HyDE directory exists, updating..."
    cd HyDE
    git fetch origin
    git reset --hard HEAD  # Reset any local changes
else
    echo "   Cloning HyDE repository..."
    git clone "$HYDE_REPO" HyDE
    cd HyDE
fi

# Checkout specific branch/commit if provided
if [ "$ref" != "master" ]; then
    echo "🌿 Checking out branch/commit: $ref"
    git fetch origin

    # Check if it's a branch or commit
    if git show-ref --verify --quiet "refs/remotes/origin/$ref" 2>/dev/null; then
        echo "   Found branch: $ref"
        # Delete local branch if it exists, then create fresh one
        git branch -D "$ref" 2>/dev/null || true
        git checkout -b "$ref" "origin/$ref"
    else
        echo "   Treating as commit: $ref"
        git checkout "$ref"
    fi
else
    echo "🌿 Using master branch"
    git checkout master
    git pull origin master
fi

echo ""
echo "🎨 HyDE repository ready!"

# Check if HyDE is already installed
if [ -f "/home/arch/.config/hypr/hyprland.conf" ] && [ -f "/home/arch/.config/hyde/hyde.conf" ]; then
    echo "⚠️  HyDE appears to already be installed."
    echo "   Configuration files found. Skipping installation."
    echo "   If you want to reinstall, remove ~/.config/hypr and ~/.config/hyde first."
else
    echo "🚀 Starting HyDE installation..."
    cd /home/arch/HyDE/Scripts
    ./install.sh
    echo "✅ HyDE installation complete!"
fi

echo ""
echo "🎉 Setup complete!"
echo "💾 Please shutdown the VM now by running: sudo poweroff"
echo "   This will create the snapshot for future use."
echo ""
echo "📝 If something went wrong, you can re-run this script safely."
SETUP_EOF

    chmod +x "$setup_script"

    echo ""
    echo "🖥️  Starting VM for HyDE installation..."
    echo "📋 SETUP INSTRUCTIONS:"
    echo "   1. Wait for the VM to boot to login prompt"
    echo "   2. Login as: arch / arch"
    echo "   3. Run: curl -s http://10.0.2.2:8000/setup.sh -o ./setup.sh"
    echo "   4. Run: chmod +x ./setup.sh"
    echo "   5. Run: ./setup.sh"
    echo "   6. Wait for installation to complete"
    echo "      - Hit enter for defaults"
    echo "      - It will prompt for a password at the end, use 'arch'"
    echo "      - If you end up missing the password check, you can rerun the install script './setup.sh'"
    echo "   7. Run: sudo poweroff"
    echo ""
    echo "Starting simple HTTP server for script delivery..."

    # Start simple HTTP server in background to serve the setup script
    cd "$CACHE_DIR"
    # TODO: feat(hydevm) migrate from the python http server to a pure ssh solution, no setup script needed
    $python_cmd -m http.server 8000 --bind 127.0.0.1 &
    local server_pid=$!

    # Start VM for setup
    run_qemu_vm "$temp_image" "${VM_MEMORY:-4G}" "${VM_CPUS:-2}"

    # Kill the HTTP server
    kill $server_pid 2>/dev/null || true

    echo ""
    echo "💾 Converting VM to snapshot..."

    # Convert temporary image to final snapshot
    qemu-img convert -O qcow2 "$temp_image" "$snapshot_path"

    # Cleanup
    rm -f "$temp_image" "$setup_script"

    echo "✅ Snapshot created: hyde-$snapshot_name"
    echo "🚀 You can now run: hydevm $ref"
}

function run_vm() {
    local ref="${1:-master}"
    local persistent="${2:-false}"
    local snapshot_name
    snapshot_name=$(get_snapshot_name "$ref")
    local snapshot_path="$SNAPSHOTS_DIR/hyde-$snapshot_name.qcow2"
    local qemu_cmd
    qemu_cmd=$(get_qemu_command)

    # Ensure snapshot exists
    if [ ! -f "$snapshot_path" ]; then
        echo "📸 Snapshot for '$ref' not found, creating it..."
        create_hyde_snapshot "$ref"
    fi

    local vm_disk
    if [ "$persistent" = "true" ]; then
        echo "🔒 Running in persistent mode - changes will be saved"
        vm_disk="$snapshot_path"
    else
        echo "🔄 Running in non-persistent mode - changes will be discarded"
        vm_disk="$(mktemp -p "$CACHE_DIR" overlay.XXXXXX.qcow2)"
        qemu-img create -f qcow2 -F qcow2 -b "$snapshot_path" "$vm_disk"
        trap 'rm -f "$vm_disk"' EXIT
    fi

    echo "🚀 Starting HyDE VM (branch/commit: $ref)..."
    echo "   Login: arch / arch"
    echo "   SSH: ssh arch@localhost -p 2222"

    # Run VM with SSH port forwarding
    run_qemu_vm "$vm_disk" "${VM_MEMORY:-4G}" "${VM_CPUS:-2}" "hostfwd=tcp::2222-:22"
}

function list_snapshots() {
    echo "📸 Available HyDE snapshots:"
    if [ -d "$SNAPSHOTS_DIR" ]; then
        find "$SNAPSHOTS_DIR" -name "hyde-*.qcow2" -exec basename {} \; | \
            sed 's/^hyde-//' | sed 's/\.qcow2$//' | sort
    else
        echo "No snapshots found"
    fi
}

function clean_cache() {
    echo "🧹 Cleaning HydeVM cache..."
    rm -rf "$CACHE_DIR"
    echo "✅ Cache cleaned"
}

# Main logic
check_root

persistent="false"
ref="master"
original_argc=$#

if [ "$original_argc" -eq 0 ]; then
    os=$(detect_os)
    case "$os" in
        arch|nixos|freebsd|darwin) ;;
        *)
            print_usage
            echo ""
            echo "❌ Unsupported OS: $os"
            exit 1
            ;;
    esac
fi

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --persist)
            persistent="true"
            shift
            ;;
        --list)
            list_snapshots
            exit 0
            ;;
        --clean)
            clean_cache
            exit 0
            ;;
        --install-deps)
            install_all_dependencies
            exit 0
            ;;
        --check-deps)
            check_deps_only
            exit $?
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        -*)
            echo "❌ Unknown option: $1"
            print_usage
            exit 1
            ;;
        *)
            ref="$1"
            shift
            ;;
    esac
done

# Check dependencies before running
if ! check_dependencies; then
    exit 1
fi

# Ensure archbox is available
download_archbox

# Run VM
run_vm "$ref" "$persistent"

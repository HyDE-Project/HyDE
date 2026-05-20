#!/bin/bash

# DOORwayDEVM - Simplified VM tool for DOORwayDE contributors
# Works on both Arch Linux and NixOS with automatic OS detection

set -e

# Configuration
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/doorwaydevm"
BASE_IMAGE="$CACHE_DIR/archbase.qcow2"
SNAPSHOTS_DIR="$CACHE_DIR/snapshots"
DOORWAYDE_REPO="https://github.com/DOORwayDE-Project/DOORwayDE.git"
# Required packages for Arch Linux
ARCH_PACKAGES=(
    "qemu-desktop"
    "curl"
    "python"
    "git"
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
        else
            echo "unknown"
        fi
    elif command -v nixos-version >/dev/null 2>&1; then
        echo "nixos"
    elif command -v pacman >/dev/null 2>&1; then
        echo "arch"
    else
        echo "unknown"
    fi
}

function print_usage() {
    echo "DOORwayDEVM - Simplified VM tool for DOORwayDE contributors"
    echo "Supports: Arch Linux, NixOS"
    echo ""
    echo "Usage: doorwaydevm [OPTIONS] [BRANCH/COMMIT]"
    echo ""
    echo "Arguments:"
    echo "  BRANCH/COMMIT            Git branch or commit hash (default: master)"
    echo ""
    echo "Options:"
    echo "  --persist               Make VM changes persistent"
    echo "  --list                  List available snapshots"
    echo "  --clean                 Clean all cached data"
    echo "  --install-deps          Install required dependencies (Arch only)"
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
    echo "  doorwaydevm                  # Run master branch"
    echo "  doorwaydevm --persist        # Run master branch (persistent)"
    echo "  doorwaydevm feature-branch   # Run specific branch"
    echo "  doorwaydevm abc123           # Run specific commit"
    echo "  doorwaydevm --persist dev    # Run dev branch with persistence"
    echo ""
    echo "OS-specific notes:"
    echo "  Arch Linux: Missing packages will be auto-detected and offered for install"
    echo "  NixOS: automatically installs dependencies"
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
        *)
            echo "⚠️  Unsupported OS. This script supports Arch Linux and NixOS."
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

function install_all_arch_dependencies() {
    local os
    os=$(detect_os)

    if [[ "$os" != "arch" ]]; then
        echo "❌ --install-deps is only supported on Arch Linux"
        echo "   Current OS: $os"
        exit 1
    fi

    echo "📦 Installing all DOORwayDEVM dependencies..."
    install_arch_packages "${ARCH_PACKAGES[@]}"
    echo "💡 You may need to reboot or logout/login for all changes to take effect"
}

function check_deps_only() {
    local os
    os=$(detect_os)
    echo "🔍 Checking DOORwayDEVM dependencies..."
    echo "   Detected OS: $os"

    if check_dependencies; then
        echo "✅ All dependencies are installed"

        # Check additional system info
        echo ""
        echo "📊 System Information:"
        echo "   CPU cores: $(nproc)"
        echo "   Memory: $(free -h | awk '/^Mem:/ {print $2}' 2>/dev/null || echo "Unknown")"
        echo "   KVM available: $([ -r /dev/kvm ] && echo "Yes" || echo "No")"

        if command -v qemu-system-x86_64 >/dev/null 2>&1; then
            echo "   QEMU version: $(qemu-system-x86_64 --version | head -1)"
        fi

        return 0
    else
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

function get_snapshot_name() {
    local ref="$1"
    if [ -z "$ref" ]; then
        echo "master"
    else
        # Sanitize branch/commit name for filename
        echo "${ref//[^a-zA-Z0-9._-]/_}"
    fi
}

function create_doorwayde_snapshot() {
    local ref="${1:-master}"
    local snapshot_name
    snapshot_name=$(get_snapshot_name "$ref")
    local snapshot_path="$SNAPSHOTS_DIR/doorwayde-$snapshot_name.qcow2"
    local qemu_cmd
    qemu_cmd=$(get_qemu_command)
    local python_cmd
    python_cmd=$(get_python_command)

    # Check if snapshot already exists
    if [ -f "$snapshot_path" ]; then
        echo "📸 Snapshot for '$ref' already exists"
        return 0
    fi

    echo "🔨 Creating DOORwayDE snapshot for '$ref'..."

    # Create temporary VM image for setup
    local temp_image="$CACHE_DIR/temp-setup.qcow2"
    qemu-img create -f qcow2 -F qcow2 -b "$BASE_IMAGE" "$temp_image"

    # Create setup script that will be available in the VM
    local setup_script="$CACHE_DIR/setup.sh"
    cat > "$setup_script" <<SETUP_EOF
#!/bin/bash
set -e

echo "🚀 Setting up DOORwayDE environment for branch/commit: $ref"

# Set root password for convenience
echo "🔐 Setting root password..."
echo -e "doorwaydevm\ndoorwaydevm" | sudo passwd root

# Update system and install dependencies
echo "📦 Updating system and installing dependencies..."
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm git base-devel openssh curl

# Configure SSH
echo "🔧 Configuring SSH..."
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl enable sshd

# Clone or update DOORwayDE repository
echo "📥 Setting up DOORwayDE repository..."
cd /home/arch
if [ -d "DOORwayDE" ]; then
    echo "   DOORwayDE directory exists, updating..."
    cd DOORwayDE
    git fetch origin
    git reset --hard HEAD  # Reset any local changes
else
    echo "   Cloning DOORwayDE repository..."
    git clone "$DOORWAYDE_REPO" DOORwayDE
    cd DOORwayDE
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
echo "🎨 DOORwayDE repository ready!"

# Check if DOORwayDE is already installed
if [ -f "/home/arch/.config/hypr/hyprland.conf" ] && [ -f "/home/arch/.config/doorwayde/doorwayde.conf" ]; then
    echo "⚠️  DOORwayDE appears to already be installed."
    echo "   Configuration files found. Skipping installation."
    echo "   If you want to reinstall, remove ~/.config/hypr and ~/.config/doorwayde first."
else
    echo "🚀 Starting DOORwayDE installation..."
    cd /home/arch/DOORwayDE/Scripts
    ./install.sh
    echo "✅ DOORwayDE installation complete!"
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
    echo "🖥️  Starting VM for DOORwayDE installation..."
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
    # TODO: feat(doorwaydevm) migrate from the python http server to a pure ssh solution, no setup script needed
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

    echo "✅ Snapshot created: doorwayde-$snapshot_name"
    echo "🚀 You can now run: doorwaydevm $ref"
}

function run_vm() {
    local ref="${1:-master}"
    local persistent="${2:-false}"
    local snapshot_name
    snapshot_name=$(get_snapshot_name "$ref")
    local snapshot_path="$SNAPSHOTS_DIR/doorwayde-$snapshot_name.qcow2"
    local qemu_cmd
    qemu_cmd=$(get_qemu_command)

    # Ensure snapshot exists
    if [ ! -f "$snapshot_path" ]; then
        echo "📸 Snapshot for '$ref' not found, creating it..."
        create_doorwayde_snapshot "$ref"
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

    echo "🚀 Starting DOORwayDE VM (branch/commit: $ref)..."
    echo "   Login: arch / arch"
    echo "   SSH: ssh arch@localhost -p 2222"

    # Run VM with SSH port forwarding
    run_qemu_vm "$vm_disk" "${VM_MEMORY:-4G}" "${VM_CPUS:-2}" "hostfwd=tcp::2222-:22"
}

function list_snapshots() {
    echo "📸 Available DOORwayDE snapshots:"
    if [ -d "$SNAPSHOTS_DIR" ]; then
        find "$SNAPSHOTS_DIR" -name "doorwayde-*.qcow2" -exec basename {} \; | \
            sed 's/^doorwayde-//' | sed 's/\.qcow2$//' | sort
    else
        echo "No snapshots found"
    fi
}

function clean_cache() {
    echo "🧹 Cleaning DOORwayDEVM cache..."
    rm -rf "$CACHE_DIR"
    echo "✅ Cache cleaned"
}

# Main logic
check_root

persistent="false"
ref="master"

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
            install_all_arch_dependencies
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

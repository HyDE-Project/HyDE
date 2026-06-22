#!/bin/bash

# HydeVM - Simplified VM tool for HyDE contributors
# Works on both Arch Linux and NixOS with automatic OS detection

set -e

# Configuration
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/hydevm"
BASE_IMAGE="$CACHE_DIR/archbase.qcow2"
SNAPSHOTS_DIR="$CACHE_DIR/snapshots"
HYDE_REPO="https://github.com/HyDE-Project/HyDE.git"
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
    echo "HydeVM - Simplified VM tool for HyDE contributors"
    echo "Supports: Arch Linux, NixOS"
    echo ""
    echo "Usage: hydevm [OPTIONS] [BRANCH/COMMIT]"
    echo ""
    echo "Arguments:"
    echo "  BRANCH/COMMIT            Git branch or commit hash (default: master)"
    echo ""
    echo "Options:"
    echo "  --persist               Make VM changes persistent"
    echo "  --ssh-only              Run VM headless (no display window, SSH-only access)"
    echo "  --snapshot-from <ref>   Clone an existing snapshot as a new branch for testing"
    echo "  --snapshot-as <name>    Save current VM state as a named snapshot (use with --persist)"
    echo "  --mount <path>          Share a host directory live into the VM via 9p (e.g., --mount \$PWD)"
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
    echo "  hydevm                               # Run master branch"
    echo "  hydevm --persist                     # Run master branch (persistent)"
    echo "  hydevm --ssh-only                    # Run master headless (SSH-only)"
    echo "  hydevm --persist dev                 # Run dev branch with persistence"
    echo "  hydevm --mount ~/HyDE                # Share local HyDE folder live into the VM"
    echo "  hydevm --mount ~/HyDE --ssh-only     # Headless with live folder sharing"
    echo "  hydevm --ssh-only --persist          # Run master headless with persistence"
    echo "  hydevm --snapshot-from master my-test # Clone master snapshot as my-test"
    echo ""
    echo "Live Folder Sharing (--mount):"
    echo "  Mounts a host directory inside the VM at /mnt/host via 9p virtio."
    echo "  Changes on the host appear instantly in the VM — no sync or copy needed."
    echo "  Inside the VM:"
    echo "    mount -t 9p host_share /mnt/host"
    echo "    cd /mnt/host   # your live files are here"
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

    echo "📦 Installing all HydeVM dependencies..."
    install_arch_packages "${ARCH_PACKAGES[@]}"
    echo "💡 You may need to reboot or logout/login for all changes to take effect"
}

function check_deps_only() {
    local os
    os=$(detect_os)
    echo "🔍 Checking HydeVM dependencies..."
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
    local ssh_only="${5:-false}"
    local mount_path="${6:-}"
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
            -boot "menu=on"
        )

        if [ "$ssh_only" = "true" ]; then
            # Headless mode: no display, no GPU device
            qemu_args+=(-display none -vga none)
            echo "🖥️  Running headless (SSH-only mode)"
        else
            # Normal mode with GPU acceleration
            qemu_args+=(-device virtio-vga-gl -display "gtk,gl=on,grab-on-hover=on")
        fi

        # Add KVM-specific arguments
        if [ -r /dev/kvm ]; then
            qemu_args+=(-enable-kvm -cpu host)
        else
            qemu_args+=(-cpu qemu64)
        fi

        # Always add network adapter for SSH access and HTTP server reachability
        # Use extra_args if provided (e.g. for SSH forwarding), otherwise default to SSH forwarding
        local net_args="${extra_args:-hostfwd=tcp::2222-:22}"
        qemu_args+=(-device virtio-net,netdev=net0 -netdev "user,id=net0,$net_args")

        # Add 9p shared folder mount if --mount was specified
        if [ -n "$mount_path" ]; then
            if [ -d "$mount_path" ]; then
                local mount_tag="host_share"
                echo "📁 Sharing host directory: $mount_path"
                echo "   Mount inside VM: mount -t 9p $mount_tag /mnt/host"
                qemu_args+=(-fsdev "local,id=fsdev0,path=$mount_path,security_model=mapped-xattr")
                qemu_args+=(-device "virtio-9p-pci,fsdev=fsdev0,mount_tag=$mount_tag")
            else
                echo "⚠️  Mount path '$mount_path' does not exist or is not a directory. Skipping."
            fi
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

function create_hyde_snapshot() {
    local ref="${1:-master}"
    local ssh_only="${2:-false}"
    local mount_path="${3:-}"
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

    # If --mount is provided, symlink the local HyDE repo so setup.sh can use it
    local local_repo=""
    if [ -n "$mount_path" ] && [ -d "$mount_path" ]; then
        local_repo="$mount_path"
        echo "📁 Will use local HyDE repo from mount: $local_repo"
    fi

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

# Set up auto-mount for 9p shared folder via systemd (persists across boots)
sudo mkdir -p /mnt/host
sudo tee /etc/systemd/system/mnt-host.mount > /dev/null <<'MOUNT_EOF'
[Unit]
Description=HyDE host 9p mount
[Mount]
What=host_share
Where=/mnt/host
Type=9p
Options=trans=virtio,version=9p2000.L
[Install]
WantedBy=local-fs.target
MOUNT_EOF
sudo systemctl enable mnt-host.mount 2>/dev/null || true
sudo mount -t 9p host_share /mnt/host 2>/dev/null || true

echo "   Checking for 9p host share..."
if mountpoint -q /mnt/host 2>/dev/null; then
    echo "🔗 Host mount detected at /mnt/host — using local HyDE repo!"
    echo "   This gives you live updates as you edit files on the host."
    rm -rf /home/arch/HyDE
    ln -sf /mnt/host /home/arch/HyDE
fi

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
    if [ -n "$mount_path" ]; then
        echo "📁 You used --mount, so after step 2 you can also:"
        echo "   sudo mkdir -p /mnt/host && sudo mount -t 9p host_share /mnt/host"
        echo "   Then your host files are live at /mnt/host"
    fi
    echo "Starting simple HTTP server for script delivery..."

    # Start simple HTTP server in background to serve the setup script
    cd "$CACHE_DIR"
    # TODO: feat(hydevm) migrate from the python http server to a pure ssh solution, no setup script needed
    $python_cmd -m http.server 8000 --bind 0.0.0.0 &
    local server_pid=$!

    # Start VM for setup
    run_qemu_vm "$temp_image" "${VM_MEMORY:-4G}" "${VM_CPUS:-2}" "" "$ssh_only" "$mount_path"

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

function duplicate_snapshot() {
    local source_ref="$1"
    local target_ref="$2"

    if [ -z "$source_ref" ] || [ -z "$target_ref" ]; then
        echo "❌ Usage: hydevm --snapshot-from <source> <target>"
        return 1
    fi

    local source_snap
    source_snap=$(get_snapshot_name "$source_ref")
    local target_snap
    target_snap=$(get_snapshot_name "$target_ref")

    local source_path="$SNAPSHOTS_DIR/hyde-$source_snap.qcow2"
    local target_path="$SNAPSHOTS_DIR/hyde-$target_snap.qcow2"

    if [ ! -f "$source_path" ]; then
        echo "❌ Source snapshot for '$source_ref' not found."
        echo "   Run 'hydevm --list' to see available snapshots."
        return 1
    fi

    if [ -f "$target_path" ]; then
        echo "⚠️  Snapshot for '$target_ref' already exists."
        read -p "   Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "❌ Aborted."
            return 1
        fi
    fi

    echo "📋 Cloning snapshot '$source_ref' → '$target_ref'..."
    qemu-img create -f qcow2 -F qcow2 -b "$source_path" "$target_path"
    echo "✅ Snapshot cloned: hyde-$target_snap"
    echo "   Run: hydevm $target_ref"
    echo "   Or:  hydevm --ssh-only $target_ref"
    echo "   Or:  hydevm --persist $target_ref"
}

function run_vm() {
    local ref="${1:-master}"
    local persistent="${2:-false}"
    local ssh_only="${3:-false}"
    local mount_path="${4:-}"
    local snapshot_name
    snapshot_name=$(get_snapshot_name "$ref")
    local snapshot_path="$SNAPSHOTS_DIR/hyde-$snapshot_name.qcow2"
    local qemu_cmd
    qemu_cmd=$(get_qemu_command)

    # Ensure snapshot exists
    if [ ! -f "$snapshot_path" ]; then
        echo "📸 Snapshot for '$ref' not found, creating it..."
        create_hyde_snapshot "$ref" "$ssh_only" "$mount_path"
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

    if [ -n "$mount_path" ]; then
        echo "📁 Host folder shared at /mnt/host (mount -t 9p host_share /mnt/host)"
    fi

    # Run VM with SSH port forwarding
    run_qemu_vm "$vm_disk" "${VM_MEMORY:-4G}" "${VM_CPUS:-2}" "hostfwd=tcp::2222-:22" "$ssh_only" "$mount_path"
}

function list_snapshots() {
    echo "📸 Available HyDE snapshots:"
    if [ -d "$SNAPSHOTS_DIR" ]; then
        local count=0
        while IFS= read -r snap; do
            echo "   - $snap"
            count=$((count + 1))
        done < <(find "$SNAPSHOTS_DIR" -name "hyde-*.qcow2" -exec basename {} \; | \
            sed 's/^hyde-//' | sed 's/\.qcow2$//' | sort)
        if [ "$count" -eq 0 ]; then
            echo "   (no snapshots found)"
        fi
    else
        echo "   (no snapshots found)"
    fi
}

function snapshot_as() {
    local source_ref="${1:-master}"
    local target_name="$2"

    if [ -z "$target_name" ]; then
        list_snapshots
        echo ""
        read -p "📝 Name for the new snapshot: " -r target_name
        if [ -z "$target_name" ]; then
            echo "❌ No name provided. Aborted."
            return 1
        fi
    fi

    local source_snap
    source_snap=$(get_snapshot_name "$source_ref")
    local target_snap
    target_snap=$(get_snapshot_name "$target_name")

    local source_path="$SNAPSHOTS_DIR/hyde-$source_snap.qcow2"
    local target_path="$SNAPSHOTS_DIR/hyde-$target_snap.qcow2"

    if [ ! -f "$source_path" ]; then
        echo "❌ Snapshot for '$source_ref' not found."
        echo "   Run 'hydevm --list' to see available snapshots."
        return 1
    fi

    if [ -f "$target_path" ]; then
        echo "⚠️  Snapshot '$target_name' already exists."
        read -p "   Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "❌ Aborted."
            return 1
        fi
    fi

    echo "💾 Saving snapshot '$source_ref' → '$target_name'..."
    qemu-img create -f qcow2 -F qcow2 -b "$source_path" "$target_path"
    echo "✅ Snapshot saved as: hyde-$target_snap"
    echo "   Run: hydevm $target_name"
    echo "   Or:  hydevm --persist $target_name"
    echo "   Or:  hydevm --ssh-only $target_name"
}

function clean_cache() {
    echo "🧹 Cleaning HydeVM cache..."
    rm -rf "$CACHE_DIR"
    echo "✅ Cache cleaned"
}

# Main logic
check_root

persistent="false"
ssh_only="false"
ref="master"
snapshot_from=""
snapshot_as_name=""
mount_path=""

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --persist)
            persistent="true"
            shift
            ;;
        --ssh-only)
            ssh_only="true"
            shift
            ;;
        --mount)
            shift
            mount_path="$1"
            if [ -z "$mount_path" ]; then
                echo "❌ --mount requires a path (e.g., --mount \$PWD)"
                exit 1
            fi
            # Resolve to absolute path
            mount_path="$(realpath -m "$mount_path" 2>/dev/null || echo "$mount_path")"
            shift
            ;;
        --snapshot-from)
            shift
            snapshot_from="$1"
            if [ -z "$snapshot_from" ]; then
                echo "❌ --snapshot-from requires a source ref (e.g., master)"
                exit 1
            fi
            shift
            ;;
        --snapshot-as)
            shift
            snapshot_as_name="$1"
            if [ -z "$snapshot_as_name" ]; then
                echo "❌ --snapshot-as requires a name (e.g., --snapshot-as my-saved-state)"
                exit 1
            fi
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

# Handle snapshot from/save operations
if [ -n "$snapshot_from" ]; then
    duplicate_snapshot "$snapshot_from" "$ref"
    exit $?
fi

if [ -n "$snapshot_as_name" ]; then
    snapshot_as "$ref" "$snapshot_as_name"
    exit $?
fi

# Check dependencies before running
if ! check_dependencies; then
    exit 1
fi

# Ensure archbox is available
download_archbox

# Run VM
run_vm "$ref" "$persistent" "$ssh_only" "$mount_path"

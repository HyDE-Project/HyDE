#!/usr/bin/env bash
#
# HALLwayDE Setup Script for NixOS
# Part of the HALLway OS ecosystem
#
# Usage: ./setup-nixos.sh [options]
#   -f, --force     Overwrite existing configs without prompting
#   -n, --dry-run   Show what would be done without making changes
#   -h, --help      Show this help message
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script location (resolve symlinks)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HALLWAYDE_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIGS_DIR="$HALLWAYDE_ROOT/Configs"

# Options
FORCE=false
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            FORCE=true
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            echo "HALLwayDE Setup Script for NixOS"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -f, --force     Overwrite existing configs without prompting"
            echo "  -n, --dry-run   Show what would be done without making changes"
            echo "  -h, --help      Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

run_cmd() {
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}[DRY-RUN]${NC} $*"
    else
        "$@"
    fi
}

# Check if running on NixOS
check_nixos() {
    if [[ ! -f /etc/NIXOS ]]; then
        log_warn "Not running on NixOS - script is designed for NixOS but may work elsewhere"
    else
        log_success "NixOS detected"
    fi
}

# Check required packages
check_packages() {
    log_info "Checking required packages..."

    local required=(hyprland waybar rofi dunst hyprlock hypridle kitty)
    local recommended=(wlogout cliphist grim slurp swww hyprsunset satty)
    local missing_required=()
    local missing_recommended=()

    for pkg in "${required[@]}"; do
        if ! command -v "$pkg" &>/dev/null; then
            missing_required+=("$pkg")
        fi
    done

    for pkg in "${recommended[@]}"; do
        if ! command -v "$pkg" &>/dev/null; then
            missing_recommended+=("$pkg")
        fi
    done

    if [[ ${#missing_required[@]} -gt 0 ]]; then
        log_error "Missing required packages: ${missing_required[*]}"
        echo ""
        echo "Add these to your NixOS or Home Manager configuration:"
        echo ""
        echo "  environment.systemPackages = with pkgs; ["
        for pkg in "${missing_required[@]}"; do
            echo "    $pkg"
        done
        echo "  ];"
        echo ""
        exit 1
    fi

    if [[ ${#missing_recommended[@]} -gt 0 ]]; then
        log_warn "Missing recommended packages: ${missing_recommended[*]}"
        echo "  Some features may not work without these."
    fi

    log_success "Required packages present"
}

# Backup existing config
backup_config() {
    local target="$1"
    local backup_dir="$HOME/.config/hallwayde-backups/$(date +%Y%m%d_%H%M%S)"

    if [[ -e "$target" && ! -L "$target" ]]; then
        log_info "Backing up $target"
        run_cmd mkdir -p "$backup_dir"
        run_cmd mv "$target" "$backup_dir/"
        return 0
    elif [[ -L "$target" ]]; then
        # It's a symlink, just remove it
        run_cmd rm -f "$target"
        return 0
    fi
    return 1
}

# Create symlink with backup
create_link() {
    local source="$1"
    local target="$2"

    if [[ ! -e "$source" ]]; then
        log_warn "Source does not exist: $source"
        return 1
    fi

    if [[ -e "$target" || -L "$target" ]]; then
        if [[ "$FORCE" == true ]]; then
            backup_config "$target"
        else
            if [[ -L "$target" ]]; then
                local current_link
                current_link=$(readlink -f "$target")
                if [[ "$current_link" == "$(readlink -f "$source")" ]]; then
                    log_success "Already linked: $target"
                    return 0
                fi
            fi
            log_warn "Target exists: $target (use --force to overwrite)"
            return 1
        fi
    fi

    # Ensure parent directory exists
    run_cmd mkdir -p "$(dirname "$target")"
    run_cmd ln -sf "$source" "$target"
    log_success "Linked: $target -> $source"
}

# Copy binaries (can't symlink compiled binaries reliably)
copy_binaries() {
    log_info "Installing HALLwayDE utilities..."

    run_cmd mkdir -p "$HOME/.local/bin"

    for bin in "$CONFIGS_DIR/.local/bin"/*; do
        if [[ -f "$bin" ]]; then
            local name
            name=$(basename "$bin")
            run_cmd cp -f "$bin" "$HOME/.local/bin/$name"
            run_cmd chmod +x "$HOME/.local/bin/$name"
            log_success "Installed: ~/.local/bin/$name"
        fi
    done

    # Check if ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        log_warn "~/.local/bin is not in your PATH"
        echo "  Add this to your shell config:"
        echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
}

# Main setup
main() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║           HALLwayDE Setup for NixOS                       ║"
    echo "║   Your desktop should be beautiful, functional, and yours ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""

    if [[ "$DRY_RUN" == true ]]; then
        log_warn "Dry run mode - no changes will be made"
        echo ""
    fi

    # Checks
    check_nixos
    check_packages
    echo ""

    # Setup .config symlinks
    log_info "Setting up configuration symlinks..."

    local config_dirs=(
        "hypr"
        "waybar"
        "rofi"
        "dunst"
        "hallwayde"
        "kitty"
        "wlogout"
        "swaync"
    )

    for dir in "${config_dirs[@]}"; do
        if [[ -d "$CONFIGS_DIR/.config/$dir" ]]; then
            create_link "$CONFIGS_DIR/.config/$dir" "$HOME/.config/$dir"
        fi
    done
    echo ""

    # Setup .local symlinks
    log_info "Setting up local data symlinks..."

    run_cmd mkdir -p "$HOME/.local/lib"
    run_cmd mkdir -p "$HOME/.local/share"

    create_link "$CONFIGS_DIR/.local/lib/hallwayde" "$HOME/.local/lib/hallwayde"
    create_link "$CONFIGS_DIR/.local/share/hallwayde" "$HOME/.local/share/hallwayde"
    create_link "$CONFIGS_DIR/.local/share/hypr" "$HOME/.local/share/hypr"
    echo ""

    # Copy binaries
    copy_binaries
    echo ""

    # Summary
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                    Setup Complete!                        ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    log_info "Next steps:"
    echo "  1. Edit ~/.config/hypr/monitors.conf for your display"
    echo "  2. Edit ~/.config/hypr/userprefs.conf for your preferences"
    echo "  3. Reload Hyprland: hyprctl reload"
    echo ""
    log_info "Key bindings:"
    echo "  Super + Return    Terminal"
    echo "  Super + D         App launcher"
    echo "  Super + Q         Close window"
    echo "  Super + /         Show all keybindings"
    echo ""
}

main "$@"

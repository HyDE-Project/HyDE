#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: build-iso.sh --disk DEVICE [options]

Options:
  --disk DEVICE       Disk to erase during installation (prefer /dev/disk/by-id/...)
  --user NAME         Default first account name (default: hyde)
  --output PATH       Output ISO path (default: NixOS-HyDE-autoinstall.iso)
  -h, --help          Show this help

Build on NixOS or another Linux system with Nix and flakes enabled. The
password is requested twice. The installer requires UEFI and wired networking.
USAGE
}

target_disk=""
default_user=hyde
output_path=NixOS-HyDE-autoinstall.iso
while (($#)); do
    case "$1" in
        --disk) target_disk="${2:?Missing target disk}"; shift 2 ;;
        --user) default_user="${2:?Missing username}"; shift 2 ;;
        --output) output_path="${2:?Missing output path}"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done

[[ -n "$target_disk" ]] || { usage >&2; exit 2; }
[[ "$target_disk" =~ ^/dev/(disk/by-id/[A-Za-z0-9._:+-]+|(sd[a-z]+|vd[a-z]+|nvme[0-9]+n[0-9]+|mmcblk[0-9]+))$ ]] || {
    echo "Invalid disk path; use a whole disk or /dev/disk/by-id identity." >&2
    exit 2
}
[[ "$target_disk" != *-part[0-9]* ]] || { echo "Select a whole disk, not a partition." >&2; exit 2; }
[[ "$default_user" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || { echo "Invalid username." >&2; exit 2; }
[[ -b "$target_disk" ]] || { echo "Target disk is not available on this build host: $target_disk" >&2; exit 2; }
command -v nix >/dev/null || { echo "Nix is required to build the ISO." >&2; exit 1; }
command -v openssl >/dev/null || { echo "OpenSSL is required to hash the root password." >&2; exit 1; }
command -v lsblk >/dev/null || { echo "lsblk is required to validate the target disk." >&2; exit 1; }
[[ "$(lsblk -dn -o TYPE -- "$target_disk")" == disk ]] || { echo "The target must be a whole disk." >&2; exit 2; }

read -rsp "Root password: " password; echo
read -rsp "Repeat password: " password_repeat; echo
[[ -n "$password" && "$password" == "$password_repeat" ]] || { echo "Passwords are empty or do not match." >&2; exit 2; }
password_hash="$(printf '%s\n' "$password" | openssl passwd -6 -stdin)"
unset password password_repeat

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../../.." && pwd)"
output_path="$(realpath -m "$output_path")"
mkdir -p "$(dirname -- "$output_path")"
temp_dir="$(mktemp -d)"
trap 'rm -rf -- "$temp_dir"' EXIT
source_dir="$temp_dir/source"
mkdir -p "$source_dir"
tar -C "$repo_root" --exclude-vcs --exclude='*.iso' --exclude='*.iso.sha256' \
    --exclude='./out' --exclude='./result' --exclude='./result-*' -cf - . \
    | tar -C "$source_dir" -xf -

TARGET_DISK="$target_disk" ROOT_PASSWORD_HASH="$password_hash" DEFAULT_USER="$default_user" \
python3 - "$source_dir/Scripts/iso/nixos/install-settings.json" <<'PY'
import json
import os
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
path.write_text(json.dumps({
    "targetDisk": os.environ["TARGET_DISK"],
    "rootPasswordHash": os.environ["ROOT_PASSWORD_HASH"],
    "defaultUser": os.environ["DEFAULT_USER"],
}, indent=2) + "\n")
PY
unset password_hash

nix build --extra-experimental-features 'nix-command flakes' --no-link --print-out-paths \
        "$source_dir#nixosConfigurations.hydeIso.config.system.build.isoImage" \
        > "$temp_dir/build-path"
iso_dir="$(cat "$temp_dir/build-path")/iso"
iso_source="$(find "$iso_dir" -maxdepth 1 -type f -name '*.iso' -print -quit)"
[[ -n "$iso_source" ]] || { echo "Nix build produced no ISO image." >&2; exit 1; }
install -m 0644 "$iso_source" "$output_path"
sha256sum "$output_path" > "${output_path}.sha256"
echo "Created $output_path (checksum: ${output_path}.sha256)"

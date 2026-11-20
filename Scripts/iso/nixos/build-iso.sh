#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: build-iso.sh --disk DEVICE [options]

Options:
  --disk DEVICE       Persistent /dev/disk/by-id identity to erase at boot
  --user NAME         Default first account name (default: hyde)
  --output PATH       Output ISO path (default: HyDEOS-NixOS.iso)
  -h, --help          Show this help

Build on NixOS or another Linux system with Nix and flakes enabled. The
normal-user password is set at first boot. The installer requires UEFI and
wired networking.
USAGE
}

target_disk=""
default_user=hyde
output_path=HyDEOS-NixOS.iso
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
[[ "$target_disk" =~ ^/dev/disk/by-id/[A-Za-z0-9._:+-]+$ ]] || {
    echo "Use a persistent whole-disk /dev/disk/by-id identity." >&2
    exit 2
}
[[ "$target_disk" != *-part[0-9]* ]] || { echo "Select a whole disk, not a partition." >&2; exit 2; }
[[ "$default_user" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || { echo "Invalid username." >&2; exit 2; }
command -v nix >/dev/null || { echo "Nix is required to build the ISO." >&2; exit 1; }

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../../.." && pwd)"
output_path="$(realpath -m "$output_path")"
mkdir -p "$(dirname -- "$output_path")"
temp_dir="$(mktemp -d)"
trap 'rm -rf -- "$temp_dir"' EXIT
source_dir="$temp_dir/source"
if [[ -n "$(git -C "$repo_root" status --porcelain --untracked-files=normal)" ]]; then
    echo "Build from a clean Git checkout so untracked files and secrets cannot enter the ISO." >&2
    exit 1
fi
mkdir -p "$source_dir"
git -C "$repo_root" archive --format=tar HEAD | tar -C "$source_dir" -xf -

TARGET_DISK="$target_disk" DEFAULT_USER="$default_user" \
python3 - "$source_dir/Scripts/iso/nixos/install-settings.json" <<'PY'
import json
import os
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
path.write_text(json.dumps({
    "targetDisk": os.environ["TARGET_DISK"],
    "defaultUser": os.environ["DEFAULT_USER"],
}, indent=2) + "\n")
PY

nix build --extra-experimental-features 'nix-command flakes' --no-link --print-out-paths \
        "$source_dir#nixosConfigurations.hydeIso.config.system.build.isoImage" \
        > "$temp_dir/build-path"
iso_dir="$(cat "$temp_dir/build-path")/iso"
iso_source="$(find "$iso_dir" -maxdepth 1 -type f -name '*.iso' -print -quit)"
[[ -n "$iso_source" ]] || { echo "Nix build produced no ISO image." >&2; exit 1; }
install -m 0644 "$iso_source" "$output_path"
sha256sum "$output_path" > "${output_path}.sha256"
echo "Created $output_path (checksum: ${output_path}.sha256)"

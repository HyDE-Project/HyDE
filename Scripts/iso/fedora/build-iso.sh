#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: build-iso.sh --source Fedora-Everything-netinst.iso --disk DEVICE [options]

Options:
  --source PATH       Fedora netinstall ISO to customize
  --disk DEVICE       Persistent /dev/disk/by-id identity to erase at boot
  --user NAME         First-boot account (default: hyde)
  --hyde-repository URL  HyDE repository to install (default: upstream)
  --hyde-branch REF      HyDE ref to install (default: pinned upstream commit)
  --output PATH       Output ISO path (default: HyDEOS-Fedora.iso)
  -h, --help          Show this help

The first-boot prompt sets the normal-user password. The installer erases the
selected disk after explicit confirmation and needs a wired DHCP connection.
EOF
}

source_iso=""
target_disk=""
hyde_user="hyde"
hyde_repository="https://github.com/HyDE-Project/HyDE.git"
hyde_branch="ca9ed884b8885b0c504e1fdc4edb806226a9c19b"
output_iso="HyDEOS-Fedora.iso"

while (($#)); do
    case "$1" in
        --source) source_iso="${2:?Missing ISO path}"; shift 2 ;;
        --disk) target_disk="${2:?Missing target disk}"; shift 2 ;;
        --user) hyde_user="${2:?Missing username}"; shift 2 ;;
        --hyde-repository) hyde_repository="${2:?Missing HyDE repository URL}"; shift 2 ;;
        --hyde-branch) hyde_branch="${2:?Missing HyDE branch}"; shift 2 ;;
        --output) output_iso="${2:?Missing output path}"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done

if [[ -z "$source_iso" || -z "$target_disk" ]]; then
    usage >&2
    exit 2
fi
if [[ ! -f "$source_iso" ]]; then
    echo "Fedora ISO not found: $source_iso" >&2
    exit 1
fi
if ! [[ "$target_disk" =~ ^/dev/disk/by-id/[A-Za-z0-9._:+-]+$ ]] || [[ "$target_disk" == *-part[0-9]* ]]; then
    echo "Use a persistent whole-disk /dev/disk/by-id identity." >&2
    exit 2
fi
kickstart_disk="$target_disk"
if ! command -v mkksiso >/dev/null 2>&1; then
    echo "mkksiso is missing; install Fedora's lorax package first." >&2
    exit 1
fi
if ! [[ "$hyde_user" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; then
    echo "Invalid Linux username: $hyde_user" >&2
    exit 2
fi
if ! [[ "$hyde_repository" =~ ^https://[A-Za-z0-9._/-]+\.git$ ]]; then
    echo "Invalid HyDE repository URL: $hyde_repository" >&2
    exit 2
fi
if ! [[ "$hyde_branch" =~ ^[A-Za-z0-9._/-]+$ ]]; then
    echo "Invalid HyDE branch: $hyde_branch" >&2
    exit 2
fi

if [[ "$(realpath -m "$source_iso")" == "$(realpath -m "$output_iso")" ]]; then
    echo "The output ISO must be different from the source ISO." >&2
    exit 2
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
temp_dir="$(mktemp -d)"
trap 'rm -rf -- "$temp_dir"' EXIT
kickstart="$temp_dir/ks.cfg"

sed \
    -e "s|@DISK@|$kickstart_disk|g" \
    -e "s|@USER@|$hyde_user|g" \
    -e "s|@HYDE_REPO_URL@|$hyde_repository|g" \
    -e "s|@HYDE_REPO_BRANCH@|$hyde_branch|g" \
    "$script_dir/kickstart.ks.in" > "$kickstart"

mkdir -p "$(dirname -- "$output_iso")"
mkksiso --ks "$kickstart" "$source_iso" "$output_iso"
sha256sum "$output_iso" > "${output_iso}.sha256"
echo "Created $output_iso"
echo "Checksum: ${output_iso}.sha256"

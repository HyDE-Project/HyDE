#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: build-iso.sh --source Fedora-Everything-netinst.iso [options]

Options:
  --source PATH       Fedora netinstall ISO to customize
  --hyde-repository URL  HyDE repository to install (default: upstream)
  --hyde-branch REF      HyDE ref to install (default: pinned upstream commit)
  --output PATH       Output ISO path (default: HyDEOS.iso)
  -h, --help          Show this help

Anaconda asks for installation storage at boot. The first-boot prompt creates
the normal user and sets its password. Installation needs wired DHCP networking.
EOF
}

source_iso=""
hyde_repository="https://github.com/HyDE-Project/HyDE.git"
hyde_branch="ca9ed884b8885b0c504e1fdc4edb806226a9c19b"
output_iso="HyDEOS.iso"

while (($#)); do
    case "$1" in
        --source) source_iso="${2:?Missing ISO path}"; shift 2 ;;
        --hyde-repository) hyde_repository="${2:?Missing HyDE repository URL}"; shift 2 ;;
        --hyde-branch) hyde_branch="${2:?Missing HyDE branch}"; shift 2 ;;
        --output) output_iso="${2:?Missing output path}"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done

if [[ -z "$source_iso" ]]; then
    usage >&2
    exit 2
fi
if [[ ! -f "$source_iso" ]]; then
    echo "Fedora ISO not found: $source_iso" >&2
    exit 1
fi
if ! command -v mkksiso >/dev/null 2>&1; then
    echo "mkksiso is missing; install Fedora's lorax package first." >&2
    exit 1
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
    -e "s|@HYDE_REPO_URL@|$hyde_repository|g" \
    -e "s|@HYDE_REPO_BRANCH@|$hyde_branch|g" \
    "$script_dir/kickstart.ks.in" > "$kickstart"

mkdir -p "$(dirname -- "$output_iso")"
mkksiso --ks "$kickstart" "$source_iso" "$output_iso"
(
    cd -- "$(dirname -- "$output_iso")"
    sha256sum "$(basename -- "$output_iso")" > "$(basename -- "$output_iso").sha256"
)
echo "Created $output_iso"
echo "Checksum: ${output_iso}.sha256"

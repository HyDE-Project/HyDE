#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: build-iso.sh --disk DEVICE [options]

Options:
  --disk DEVICE       Disk to erase (prefer /dev/disk/by-id/...)
  --user NAME         First-boot account (default: hyde)
  --hyde-repository URL  HyDE Git repository (default: upstream)
  --hyde-branch NAME     HyDE branch (default: dev)
  --output DIRECTORY  Output directory (default: ./out)
  -h, --help          Show this help

Build on Arch Linux with archiso installed. The password is requested twice.
The ISO requires UEFI boot and a wired DHCP network for unattended setup.
USAGE
}

target_disk=""
hyde_user="hyde"
hyde_repository="https://github.com/HyDE-Project/HyDE.git"
hyde_branch="dev"
output_dir="out"
while (($#)); do
    case "$1" in
        --disk) target_disk="${2:?Missing target disk}"; shift 2 ;;
        --user) hyde_user="${2:?Missing username}"; shift 2 ;;
        --hyde-repository) hyde_repository="${2:?Missing repository URL}"; shift 2 ;;
        --hyde-branch) hyde_branch="${2:?Missing branch}"; shift 2 ;;
        --output) output_dir="${2:?Missing output directory}"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done
[[ -n "$target_disk" ]] || { usage >&2; exit 2; }
[[ "$target_disk" =~ ^/dev/(disk/by-id/[A-Za-z0-9._:+-]+|(sd[a-z]+|vd[a-z]+|nvme[0-9]+n[0-9]+|mmcblk[0-9]+))$ ]] || { echo "Invalid disk path." >&2; exit 2; }
[[ "$target_disk" != *-part[0-9]* ]] || { echo "Select a whole disk, not a partition." >&2; exit 2; }
[[ "$hyde_user" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || { echo "Invalid username." >&2; exit 2; }
[[ "$hyde_repository" =~ ^https://[A-Za-z0-9._/-]+\.git$ ]] || { echo "Invalid repository URL." >&2; exit 2; }
[[ "$hyde_branch" =~ ^[A-Za-z0-9._/-]+$ ]] || { echo "Invalid branch." >&2; exit 2; }
[[ -d /usr/share/archiso/configs/releng ]] || { echo "Install archiso on an Arch Linux build host." >&2; exit 1; }
command -v mkarchiso >/dev/null || { echo "mkarchiso not found." >&2; exit 1; }
[[ -b "$target_disk" ]] || { echo "Target disk is not available on this build host: $target_disk" >&2; exit 2; }
[[ "$(lsblk -dn -o TYPE -- "$target_disk")" == disk ]] || { echo "The target must be a whole disk." >&2; exit 2; }

read -rsp "Password for ${hyde_user}: " password; echo
read -rsp "Repeat password: " password_repeat; echo
[[ -n "$password" && "$password" == "$password_repeat" ]] || { echo "Passwords are empty or do not match." >&2; exit 2; }
password_hash="$(printf '%s\n' "$password" | openssl passwd -6 -stdin)"
unset password password_repeat

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../../.." && pwd)"
output_dir="$(realpath -m "$output_dir")"
mkdir -p "$(dirname -- "$output_dir")"
temp_dir="$(mktemp -d)"
trap 'rm -rf -- "$temp_dir"' EXIT
profile="$temp_dir/profile"
cp -a /usr/share/archiso/configs/releng "$profile"
if ((EUID == 0)); then
    root_command=()
else
    command -v sudo >/dev/null || { echo "Run as root or install sudo." >&2; exit 1; }
    root_command=(sudo)
fi
"${root_command[@]}" chown -R "$(id -u):$(id -g)" "$profile"

cat >> "$profile/packages.x86_64" <<'PACKAGES'
archinstall
base-devel
git
openssh
pciutils
sudo
PACKAGES

install -D -m 0755 "$script_dir/auto-install.sh" "$profile/airootfs/usr/local/bin/hyde-iso-auto-install"
install -D -m 0644 "$script_dir/hyde-iso-auto-install.service" "$profile/airootfs/etc/systemd/system/hyde-iso-auto-install.service"
mkdir -p "$profile/airootfs/etc/systemd/system/multi-user.target.wants"
ln -s ../hyde-iso-auto-install.service "$profile/airootfs/etc/systemd/system/multi-user.target.wants/hyde-iso-auto-install.service"

cat > "$temp_dir/build-config.json" <<JSON
{
  "hyde_user": "$hyde_user",
  "hyde_repository": "$hyde_repository",
  "hyde_branch": "$hyde_branch",
  "target_disk": "$target_disk",
  "password_hash": "$password_hash"
}
JSON
unset password_hash
install -m 0600 "$temp_dir/build-config.json" "$profile/airootfs/root/hyde-iso-config.json"

mkdir -p "$output_dir"
"${root_command[@]}" mkarchiso -v -w "$temp_dir/work" -o "$output_dir" "$profile"
iso_path="$(find "$output_dir" -maxdepth 1 -type f -name '*.iso' -printf '%T@ %p\n' | sort -nr | head -1 | cut -d' ' -f2-)"
[[ -n "$iso_path" ]] || { echo "mkarchiso produced no ISO." >&2; exit 1; }
sha256sum "$iso_path" > "${iso_path}.sha256"
echo "Created $iso_path (checksum: ${iso_path}.sha256)"

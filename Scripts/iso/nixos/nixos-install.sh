#!/usr/bin/env bash
set -euo pipefail

settings=/etc/hyde-iso-settings.json
log=/var/log/hyde-nixos-install.log
exec > >(tee -a "$log") 2>&1

read_setting() {
    python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$settings" "$1"
}

target_disk="$(read_setting targetDisk)"
disk_identity="$target_disk"
root_password_hash="$(read_setting rootPasswordHash)"
default_user="$(read_setting defaultUser)"

[[ -d /sys/firmware/efi ]] || { echo "Boot this ISO in UEFI mode."; exit 1; }
[[ -b "$target_disk" ]] || { echo "Target disk is unavailable: $target_disk"; exit 1; }
target_disk="$(readlink -f -- "$target_disk")"
[[ -b "$target_disk" ]] || { echo "Target identity did not resolve to a block device: $disk_identity"; exit 1; }
[[ "$(lsblk -dn -o TYPE -- "$target_disk")" == disk ]] || { echo "Target must be a whole disk: $target_disk"; exit 1; }
[[ "$(blockdev --getsize64 "$target_disk")" -ge $((20 * 1024 * 1024 * 1024)) ]] || {
    echo "The target disk must be at least 20 GiB."
    exit 1
}

for _ in {1..120}; do
    if curl --fail --silent --show-error --connect-timeout 5 --max-time 15 \
        https://cache.nixos.org/nix-cache-info >/dev/null 2>&1; then break; fi
    sleep 2
done
curl --fail --silent --show-error --connect-timeout 5 --max-time 15 \
    https://cache.nixos.org/nix-cache-info >/dev/null || {
    echo "Cannot reach cache.nixos.org; connect wired Ethernet and retry before installation."
    exit 1
}

case "$(basename "$target_disk")" in
    nvme*n*|mmcblk*) partition_prefix="${target_disk}p" ;;
    *) partition_prefix="$target_disk" ;;
esac

echo "Selected target $disk_identity resolves to $target_disk; the entire disk will be erased."
sgdisk --zap-all \
    --new=1:1MiB:+1GiB --typecode=1:ef00 --change-name=1:EFI \
    --new=2:0:0 --typecode=2:8300 --change-name=2:NixOS \
    "$target_disk"
partprobe "$target_disk"
sleep 2
mkfs.fat -F 32 "${partition_prefix}1"
mkfs.ext4 -F "${partition_prefix}2"
mount "${partition_prefix}2" /mnt
mkdir -p /mnt/boot /mnt/etc/nixos
mount "${partition_prefix}1" /mnt/boot
cp -a /etc/hyde-installer-source/. /mnt/etc/nixos/

nixos-generate-config --root /mnt --show-hardware-config \
    > /mnt/etc/nixos/Scripts/iso/nixos/hardware-configuration.nix
install -d -m 0700 /mnt/var/lib
install -m 0600 <(printf '%s\n' "$root_password_hash") /mnt/var/lib/hyde-root-password
python3 - "$settings" /mnt/etc/nixos/Scripts/iso/nixos/install-settings.json <<'PY'
import json
import pathlib
import sys
source, destination = map(pathlib.Path, sys.argv[1:])
settings = json.loads(source.read_text())
settings.pop("rootPasswordHash", None)
destination.write_text(json.dumps(settings, indent=2) + "\n")
PY

NIX_CONFIG='experimental-features = nix-command flakes' \
    nixos-install --root /mnt --flake /mnt/etc/nixos#hyde --no-root-passwd
sync
reboot

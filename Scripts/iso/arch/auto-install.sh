#!/usr/bin/env bash
set -euo pipefail

config=/root/hyde-iso-config.json
log=/var/log/hyde-iso-install.log
exec > >(tee -a "$log") 2>&1

if [[ ! -d /sys/firmware/efi ]]; then
    echo "This ISO requires UEFI; stopping without changing disks."
    exit 1
fi
[[ -r "$config" ]] || { echo "Missing ISO configuration: $config"; exit 1; }

# Wait for DHCP before archinstall downloads its package set.
for _ in {1..90}; do
    if getent hosts archlinux.org >/dev/null 2>&1; then break; fi
    sleep 2
done
getent hosts archlinux.org >/dev/null || { echo "No network connection; connect Ethernet and reboot."; exit 1; }

disk_identity="$(python -c 'import json,sys; print(json.load(open(sys.argv[1]))["target_disk"])' "$config")"
[[ -b "$disk_identity" ]] || { echo "Target identity is unavailable: $disk_identity"; exit 1; }
target_disk="$(readlink -f -- "$disk_identity")"
[[ -b "$target_disk" ]] || { echo "Target identity did not resolve to a block device: $disk_identity"; exit 1; }
[[ "$(lsblk -dn -o TYPE -- "$target_disk")" == disk ]] || { echo "Target must be a whole disk: $target_disk"; exit 1; }
echo "Selected target $disk_identity resolves to $target_disk."
printf 'This image will erase this disk. Type ERASE within 30 seconds to continue: '
if ! read -r -t 30 confirmation || [[ "$confirmation" != ERASE ]]; then
    echo 'Installation cancelled; the target disk was not changed.'
    exit 1
fi

HYDE_TARGET_DISK="$target_disk" python - "$config" /run/hyde-archinstall "$log" <<'PY'
import json
import os
import pathlib
import secrets
import subprocess
import sys
import uuid

source, destination, log = sys.argv[1:]
config = json.loads(pathlib.Path(source).read_text())
disk = os.environ.get("HYDE_TARGET_DISK", config["target_disk"])
size_bytes = pathlib.Path("/sys/class/block", pathlib.Path(disk).name, "size").read_text().strip()
size_mib = int(size_bytes) * 512 // (1024 * 1024)
if size_mib < 20 * 1024:
    raise SystemExit("Target disk must be at least 20 GiB.")

partition = lambda start, size, mountpoint, fs_type, flags: {
    "btrfs": [],
    "dev_path": None,
    "flags": flags,
    "fs_type": fs_type,
    "size": {"sector_size": {"unit": "B", "value": 512}, "unit": "MiB", "value": size},
    "mount_options": [],
    "mountpoint": mountpoint,
    "obj_id": str(uuid.uuid4()),
    "start": {"sector_size": {"unit": "B", "value": 512}, "unit": "MiB", "value": start},
    "status": "create",
    "type": "primary",
}

root_size = size_mib - 1026
install_script = """#!/usr/bin/env bash
set -euo pipefail
hyde_repo=@REPOSITORY@
hyde_branch=@BRANCH@
default_user=@USER@
repo=/usr/local/src/HyDE
install -d -m 0755 /usr/local/src
if [[ -e "$repo" && ! -d "$repo/.git" ]]; then
    mv "$repo" "$repo.incomplete.$(date +%s)"
fi
if [[ -d "$repo/.git" ]]; then
    git -C "$repo" remote set-url origin "$hyde_repo"
    git -C "$repo" fetch --depth=1 origin "$hyde_branch"
    git -C "$repo" checkout --detach FETCH_HEAD
else
    clone_dir="/usr/local/src/.HyDE.clone.$$"
    trap 'rm -rf -- "$clone_dir"' EXIT
    git clone --depth=1 --no-checkout "$hyde_repo" "$clone_dir"
    git -C "$clone_dir" fetch --depth=1 origin "$hyde_branch"
    git -C "$clone_dir" checkout --detach FETCH_HEAD
    mv "$clone_dir" "$repo"
    trap - EXIT
fi
cd "$repo"
login_user="$default_user"
id "$login_user" >/dev/null 2>&1 || { echo "archinstall did not create $login_user."; exit 1; }
login_home="$(getent passwd "$login_user" | cut -d: -f6)"
timeout 300 passwd "$login_user"
install -d -m 0750 /etc/sudoers.d
printf '%s ALL=(ALL:ALL) NOPASSWD: ALL\\n' "$login_user" > /etc/sudoers.d/00-hyde-firstboot
chmod 0440 /etc/sudoers.d/00-hyde-firstboot
visudo -cf /etc/sudoers.d/00-hyde-firstboot
trap 'rm -f /etc/sudoers.d/00-hyde-firstboot' EXIT
runuser -u "$login_user" -- env HOME="$login_home" USER="$login_user" LOGNAME="$login_user" PATH="$login_home/.local/bin:$PATH" HYDE_NO_REBOOT_PROMPT=1 "$repo/Scripts/install.sh" --defaults --restore --services
runuser -u "$login_user" -- env HOME="$login_home" PATH="$login_home/.local/bin:$PATH" hyde-shell luainit
rm -f /etc/sudoers.d/00-hyde-firstboot
trap - EXIT
printf '%%wheel ALL=(ALL:ALL) ALL\\n' > /etc/sudoers.d/10-wheel
chmod 0440 /etc/sudoers.d/10-wheel
visudo -cf /etc/sudoers.d/10-wheel
cat > /etc/sddm.conf.d/20-hyde-autologin.conf <<SDDM
[Autologin]
User=$login_user
Session=hyprland.desktop
Relogin=true
SDDM
install -d -m 0755 /etc/sddm.conf.d
systemctl enable sddm.service
systemctl set-default graphical.target
systemctl disable hyde-autoinstall.service
reboot
""".replace("@USER@", config["hyde_user"]).replace("@REPOSITORY@", config["hyde_repository"]).replace("@BRANCH@", config["hyde_branch"])

import base64
encoded = base64.b64encode(install_script.encode()).decode()
unit = """[Unit]
Description=Configure HyDE and choose the login account
Wants=network-online.target
After=network-online.target
Before=display-manager.service
Conflicts=getty@tty1.service

[Service]
Type=oneshot
TimeoutStartSec=2h
StandardInput=tty
StandardOutput=tty
StandardError=journal
TTYPath=/dev/tty1
TTYReset=yes
TTYVHangup=yes
TTYVTDisallocate=yes
ExecStart=/usr/local/sbin/hyde-autoinstall
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
"""
encoded_unit = base64.b64encode(unit.encode()).decode()

result = {
    "archinstall-language": "English",
    "audio_config": {"audio": "pipewire"},
    "bootloader_config": {"bootloader": "Systemd-boot", "uki": False, "removable": False},
    "debug": False,
    "disk_config": {
        "config_type": "default_layout",
        "device_modifications": [{
            "device": disk,
            "partitions": [
                partition(1, 1024, "/boot", "fat32", ["boot"]),
                partition(1025, root_size, "/", "ext4", []),
            ],
            "wipe": True,
        }],
    },
    "hostname": "hydeos",
    "kernels": ["linux"],
    "locale_config": {"kb_layout": "us", "sys_enc": "UTF-8", "sys_lang": "en_US"},
    "network_config": {"type": "nm"},
    "ntp": True,
    "offline": False,
    "packages": ["base-devel", "git", "networkmanager", "pciutils", "sudo"],
    "services": ["NetworkManager"],
    "silent": True,
    "swap": {"enabled": True, "algorithm": "zstd"},
    "timezone": "UTC",
    "custom_commands": [
        "printf '%s' '" + encoded + "' | base64 -d > /usr/local/sbin/hyde-autoinstall && printf '%s' '" + encoded_unit + "' | base64 -d > /etc/systemd/system/hyde-autoinstall.service && chmod 0755 /usr/local/sbin/hyde-autoinstall && systemctl enable hyde-autoinstall.service",
    ],
}
pathlib.Path(destination).write_text(json.dumps(result, indent=2) + "\n")
temporary_password = secrets.token_hex(32)
password_hash = subprocess.check_output(
    ["openssl", "passwd", "-6", "-stdin"], input=temporary_password + "\n", text=True
).strip()
del temporary_password
credentials = {
    "users": [{"username": config["hyde_user"], "enc_password": password_hash, "sudo": True}]
}
creds_path = pathlib.Path(destination + ".creds")
creds_path.write_text(json.dumps(credentials, indent=2) + "\n")
creds_path.chmod(0o600)
PY

archinstall --config /run/hyde-archinstall --creds /run/hyde-archinstall.creds --silent
systemctl disable hyde-iso-auto-install.service
rm -f /run/hyde-archinstall /run/hyde-archinstall.creds "$config"
reboot

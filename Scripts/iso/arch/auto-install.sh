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

python - "$config" /run/hyde-archinstall "$log" <<'PY'
import json
import pathlib
import sys
import uuid

source, destination, log = sys.argv[1:]
config = json.loads(pathlib.Path(source).read_text())
disk = config["target_disk"]
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

root_size = size_mib - 1025
install_script = """#!/usr/bin/env bash
set -euo pipefail
hyde_user=@USER@
hyde_repo=@REPOSITORY@
hyde_branch=@BRANCH@
hyde_home="$(getent passwd "$hyde_user" | cut -d: -f6)"
install -d -m 0750 /etc/sudoers.d
printf '%s\n' "$hyde_user ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/hyde-autoinstall
chmod 0440 /etc/sudoers.d/hyde-autoinstall
visudo -cf /etc/sudoers.d/hyde-autoinstall
runuser -u "$hyde_user" -- git clone --depth=1 --branch "$hyde_branch" "$hyde_repo" "$hyde_home/HyDE"
chown -R "$hyde_user:$hyde_user" "$hyde_home/HyDE"
runuser -u "$hyde_user" -- env HOME="$hyde_home" bash -lc "cd '$hyde_home/HyDE' && ./Scripts/install.sh --defaults --restore --services"
rm -f /etc/sudoers.d/hyde-autoinstall
systemctl disable hyde-autoinstall.service
""".replace("@USER@", config["hyde_user"]).replace("@REPOSITORY@", config["hyde_repository"]).replace("@BRANCH@", config["hyde_branch"])

import base64
encoded = base64.b64encode(install_script.encode()).decode()
unit = """[Unit]
Description=Run HyDE setup after first boot
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
TimeoutStartSec=infinity
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
    "hostname": "hyde",
    "kernels": ["linux"],
    "locale_config": {"kb_layout": "us", "sys_enc": "UTF-8", "sys_lang": "en_US"},
    "network_config": {"type": "nm"},
    "ntp": True,
    "offline": False,
    "packages": ["base-devel", "git", "networkmanager", "pciutils", "sudo"],
    "services": ["NetworkManager"],
    "silent": True,
    "swap": {"enabled": True, "algorithm": "zstd"},
    "timezone": "Europe/Rome",
    "custom_commands": [
        "printf '%s' '" + encoded + "' | base64 -d > /usr/local/sbin/hyde-autoinstall && printf '%s' '" + encoded_unit + "' | base64 -d > /etc/systemd/system/hyde-autoinstall.service && chmod 0755 /usr/local/sbin/hyde-autoinstall && systemctl enable hyde-autoinstall.service",
    ],
}
pathlib.Path(destination).write_text(json.dumps(result, indent=2) + "\n")
credentials = {
    "users": [{"sudo": True, "username": config["hyde_user"], "enc_password": config["password_hash"]}],
}
pathlib.Path(destination + ".creds").write_text(json.dumps(credentials, indent=2) + "\n")
pathlib.Path(destination + ".creds").chmod(0o600)
PY

archinstall --config /run/hyde-archinstall --creds /run/hyde-archinstall.creds --silent
systemctl disable hyde-iso-auto-install.service
rm -f /run/hyde-archinstall /run/hyde-archinstall.creds "$config"
reboot

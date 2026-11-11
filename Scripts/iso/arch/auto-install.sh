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
echo "Selected target $disk_identity resolves to $target_disk; archinstall will erase it."

HYDE_TARGET_DISK="$target_disk" python - "$config" /run/hyde-archinstall "$log" <<'PY'
import json
import os
import pathlib
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
repo=/root/HyDE
if [[ -e "$repo" && ! -d "$repo/.git" ]]; then
    mv "$repo" "$repo.incomplete.$(date +%s)"
fi
if [[ -d "$repo/.git" ]]; then
    git -C "$repo" remote set-url origin "$hyde_repo"
    git -C "$repo" fetch --depth=1 origin "$hyde_branch"
    git -C "$repo" checkout --detach FETCH_HEAD
else
    clone_dir="/root/.HyDE.clone.$$"
    trap 'rm -rf -- "$clone_dir"' EXIT
    git clone --depth=1 --branch "$hyde_branch" "$hyde_repo" "$clone_dir"
    mv "$clone_dir" "$repo"
    trap - EXIT
fi
cd "$repo"
HOME=/root HYDE_NO_REBOOT_PROMPT=1 ./Scripts/install.sh --defaults --restore --services
install -d -m 0755 /etc/skel/.local
for item in .config .local/bin .local/lib .local/share .bashrc .zshrc .zprofile .bash_profile; do
    [[ -e "/root/$item" ]] || continue
    if [[ "$item" == .local/* ]]; then
        cp -a "/root/$item" "/etc/skel/$item"
    else
        cp -a "/root/$item" /etc/skel/
    fi
done
chown -R root:root /etc/skel
install -d -m 0755 /usr/share/wayland-sessions /etc/sddm.conf.d
cat > /usr/share/wayland-sessions/hyde-root.desktop <<'SESSION'
[Desktop Entry]
Name=HyDE (root)
Comment=HyDE session running as root
Exec=Hyprland --i-am-really-stupid
Type=Application
SESSION

printf '\\nHyDE is ready. Create a normal user now? [Y/n] '
read -r create_user
if [[ "$create_user" =~ ^[Nn]$ ]]; then
    login_user=root
    login_session=hyde-root.desktop
else
    while :; do
        printf 'Username [%s]: ' "$default_user"
        read -r login_user
        login_user="${login_user:-$default_user}"
        if [[ "$login_user" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] && ! id "$login_user" >/dev/null 2>&1; then
            break
        fi
        echo 'Invalid or already existing username; use lowercase letters, digits, _ or -.'
    done
    useradd --create-home --skel=/etc/skel --groups=wheel,video,audio,input --shell=/bin/bash "$login_user"
    passwd "$login_user"
    install -d -m 0750 /etc/sudoers.d
    printf '%%wheel ALL=(ALL:ALL) ALL\\n' > /etc/sudoers.d/10-wheel
    chmod 0440 /etc/sudoers.d/10-wheel
    visudo -cf /etc/sudoers.d/10-wheel
    login_session=hyprland.desktop
fi
cat > /etc/sddm.conf.d/20-hyde-autologin.conf <<SDDM
[Users]
AllowRootLogin=true

[Autologin]
User=$login_user
Session=$login_session
Relogin=true
SDDM
systemctl enable sddm.service
systemctl disable hyde-autoinstall.service
""".replace("@USER@", config["hyde_user"]).replace("@REPOSITORY@", config["hyde_repository"]).replace("@BRANCH@", config["hyde_branch"])

import base64
encoded = base64.b64encode(install_script.encode()).decode()
unit = """[Unit]
Description=Configure HyDE and choose the login account
Wants=network-online.target
After=network-online.target
Before=display-manager.service

[Service]
Type=oneshot
TimeoutStartSec=infinity
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
credentials = {"root_enc_password": config["password_hash"]}
pathlib.Path(destination + ".creds").write_text(json.dumps(credentials, indent=2) + "\n")
pathlib.Path(destination + ".creds").chmod(0o600)
PY

archinstall --config /run/hyde-archinstall --creds /run/hyde-archinstall.creds --silent
systemctl disable hyde-iso-auto-install.service
rm -f /run/hyde-archinstall /run/hyde-archinstall.creds "$config"
reboot

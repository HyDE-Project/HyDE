# HyDE operating system installers

These builders create installation ISOs for systems based on Fedora Linux,
Arch Linux, and NixOS. The corresponding operating system projects and their
contributors retain their names, trademarks, copyrights, and software licenses.
HyDE packages and configures the desktop environment; it does not claim
ownership of the underlying operating systems or other upstream software.
Release descriptions for each image should identify its base as Fedora Linux,
Arch Linux, or NixOS.

Suggested release descriptions:

- Fedora image: “HyDE installer, based on Fedora Linux.”
- Arch image: “HyDE installer, based on Arch Linux.”
- NixOS image: “HyDE installer, based on NixOS.”

Each builder asks for the root password twice; the generated ISO retains its
salted hash. Temporary build-file cleanup does not remove the copy embedded in
the ISO. Do not distribute personal installation media or reuse an existing
password. The target disk is selected at build time, then fully erased and
formatted automatically when the ISO boots. The installed system starts HyDE
setup as root and asks whether to create a normal desktop account or continue
using root. Creating an account asks for a username and password. New accounts
inherit the same HyDE configuration as root from `/etc/skel`.

Use wired Ethernet for unattended OS installation and HyDE setup. Wi-Fi setup
is not part of the automated flow. Never select the USB drive containing the
ISO as the target disk. Prefer a persistent `/dev/disk/by-id/...` path so the
selected disk stays identifiable across boots. Back up important data before
booting the generated image.

## Fedora Linux

Build on Fedora with `lorax` installed. Download the Fedora Everything netinstall
ISO, then run:

```bash
Scripts/iso/fedora/build-iso.sh \
  --source Fedora-Everything-netinst.iso \
  --disk /dev/disk/by-id/wwn-0xYOUR_DISK_ID \
  --output Fedora-HyDE.iso
```

The Kickstart installs Fedora in text mode with a Btrfs layout. On first boot,
the system clones HyDE and applies its existing defaults to `/root`. The default
source is the `kairosci/HyDE` `feat/fedora-install` branch containing the Fedora
integration from PR #2232. Use `--hyde-repository` and `--hyde-branch` to select
another source.

## Arch Linux

Build on Arch Linux with `archiso` installed. The installer requires UEFI boot,
Secure Boot disabled, and a target disk of at least 20 GiB. It creates a 1 GiB
EFI partition and uses the remaining disk for an ext4 root partition.

```bash
Scripts/iso/arch/build-iso.sh \
  --disk /dev/disk/by-id/wwn-0xYOUR_DISK_ID \
  --output ./out
```

The live ISO starts `archinstall` with an unattended configuration. The target
system gets HyDE's existing defaults applied to `/root` on first boot. If the
installation fails, the live environment log is at
`/var/log/hyde-iso-install.log`.

## NixOS

Build on NixOS or another Linux system with Nix flakes enabled. The installer
requires UEFI boot, wired networking, and a target disk of at least 20 GiB. It
creates a 1 GiB EFI partition and an ext4 root partition. NixOS downloads the
system closure during installation.

```bash
Scripts/iso/nixos/build-iso.sh \
  --disk /dev/disk/by-id/wwn-0xYOUR_DISK_ID \
  --output NixOS-HyDE.iso
```

The installer writes the HyDE NixOS configuration to the selected disk and
boots into the root HyDE session. On first login, choose whether to create a
normal user with the same default configuration or keep using root.

## Root session

The root option is available because HyDE is first configured for `/root`.
Hyprland normally blocks root sessions; choosing to remain root starts its
session with `--i-am-really-stupid`. The normal account path uses the standard
Hyprland session. Fedora and Arch copy the root defaults to `/etc/skel`; NixOS
provides the same defaults through its system configuration.

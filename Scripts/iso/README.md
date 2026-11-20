# HyDEOS installers

These builders create personal HyDEOS installation media based on Arch Linux,
Fedora Linux, and NixOS. This is a per-machine installer, not a distributable
ISO. Do not publish generated images. Distribution names, trademarks,
copyrights, and software licenses remain with their respective owners. Before
any public distribution, review the [Fedora Remix guidelines](https://fedoraproject.org/wiki/Remix),
[Arch Linux trademark policy](https://terms.archlinux.org/docs/trademark-policy/),
and corresponding source obligations for bundled software.

The target disk identity is selected at build time and checked again in the
installer. Builders do not require the target disk to be connected to the
build host. Before any disk changes, the installer requires the operator to type
`ERASE`. It creates a normal desktop account during first-boot setup; root is
not offered as a graphical session. The account password is entered at first
boot and is not embedded in the ISO.

Use wired Ethernet for OS installation and HyDE setup. Wi-Fi setup
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
  --output HyDEOS-Fedora.iso
```

The Kickstart installs Fedora in text mode with a Btrfs layout. On first boot,
the system clones upstream HyDE and applies its existing defaults to the new
user. The default source is pinned to upstream commit
`ca9ed884b8885b0c504e1fdc4edb806226a9c19b`. Use `--hyde-repository` and
`--hyde-branch` to select another source or revision.

## Arch Linux

Build on Arch Linux with `archiso` installed. The installer requires UEFI boot,
Secure Boot disabled, and a target disk of at least 20 GiB. It creates a 1 GiB
EFI partition and uses the remaining disk for an ext4 root partition.

```bash
Scripts/iso/arch/build-iso.sh \
  --disk /dev/disk/by-id/wwn-0xYOUR_DISK_ID \
  --output ./out
```

The live ISO starts `archinstall` after the erase confirmation. The configured
normal user receives HyDE's defaults on first boot. The output image is named
`HyDEOS-Arch.iso`. If installation fails, the live environment log is at
`/var/log/hyde-iso-install.log`.

## NixOS

Build on NixOS or another Linux system with Nix flakes enabled. The installer
requires UEFI boot, wired networking, and a target disk of at least 20 GiB. It
creates a 1 GiB EFI partition and an ext4 root partition. NixOS downloads the
system closure during installation.

```bash
Scripts/iso/nixos/build-iso.sh \
  --disk /dev/disk/by-id/wwn-0xYOUR_DISK_ID \
  --output HyDEOS-NixOS.iso
```

The installer writes the HyDE NixOS configuration to the selected disk. On
first boot, it creates a normal user with the default HyDE configuration and
reboots into that user's desktop session.

# HyDE Arch and Fedora ISO builders

These scripts build install media locally; generated ISO files and checksums are
not committed. Each build asks for the `hyde` account password twice and stores
only a salted password hash in temporary configuration. The temporary files are
removed after the build.

Both installers use DHCP and start HyDE setup automatically on first boot. Use
wired Ethernet for the unattended setup. Connect Wi-Fi manually before starting
the installer if wired networking is unavailable. Select the intended target
carefully: the whole selected disk is erased, including existing partitions and
operating systems. The target disk is embedded in the ISO at build time.

## Fedora

Build on Fedora with `lorax` installed. Download the Fedora Everything netinstall
ISO, then run:

```bash
Scripts/iso/fedora/build-iso.sh \
  --source Fedora-Everything-netinst.iso \
  --disk /dev/nvme0n1 \
  --output Fedora-HyDE.iso
```

The generated Kickstart installs Fedora in text mode, creates a Btrfs layout,
creates the `hyde` user, then clones HyDE and runs its default restore and
service setup on the first boot. The default source is the
`kairosci/HyDE` `feat/fedora-install` branch, which contains the Fedora
integration from PR #2232. Use `--hyde-repository` and `--hyde-branch` to
select another source.

## Arch Linux

Build on Arch Linux with `archiso` installed. The installer requires UEFI boot with Secure Boot disabled
and a target disk of at least 20 GiB. It creates a 1 GiB EFI partition and uses
the remaining space for an ext4 root partition.

```bash
Scripts/iso/arch/build-iso.sh \
  --disk /dev/nvme0n1 \
  --output ./out
```

The live ISO starts `archinstall` with an unattended configuration, creates the
`hyde` user with sudo access, and schedules HyDE's default restore and service
setup on first boot. If installation fails, its log is available at
`/var/log/hyde-iso-install.log` in the live environment before rebooting.

## Safety and network requirements

The disk argument is required so the destination is visible before the ISO is
built. Do not use the USB drive containing the installer as the target. Keep a
separate copy of important files before booting the generated ISO. Fedora's
Kickstart and Arch's `archinstall` both partition and format the selected disk
without asking for confirmation.

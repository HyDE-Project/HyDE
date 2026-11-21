# HyDEOS

HyDEOS is a public, Fedora-based desktop installer image. This project currently
builds one ISO, named `HyDEOS.iso`. It installs Fedora Linux and then configures
HyDE for the account chosen during first boot. HyDEOS is a community project and
is not an official Fedora product.

## Build

Build on Fedora Linux with `lorax` installed. Download the Fedora Everything
netinstall ISO and run:

```bash
Scripts/iso/fedora/build-iso.sh \
  --source Fedora-Everything-netinst.iso \
  --output HyDEOS.iso
```

The resulting image starts Anaconda. Choose the installation disk and review
the storage changes in Anaconda before starting installation. Use wired
Ethernet with DHCP for Fedora and HyDE setup. On first boot, HyDEOS asks for a
Linux username and password, installs HyDE for that user, and starts its
desktop session. No account password or target disk is embedded in the ISO.

The HyDE source defaults to upstream commit
`ca9ed884b8885b0c504e1fdc4edb806226a9c19b`. Use `--hyde-repository` and
`--hyde-branch` to select another source or revision.

The repository's **Build HyDEOS ISO** workflow downloads and verifies the Fedora
45 source image, builds `HyDEOS.iso`, and makes the image and SHA-256 file
available as a 30-day GitHub Actions artifact.

## Public distribution

The installed system replaces Fedora's branded release packages with the
generic equivalents, as required for a modified Fedora Remix. The Fedora
installer source image may still show Fedora branding; HyDEOS is identified as
a Fedora-based community project and does not claim to be an official Fedora
release. See the [Fedora Remix guidance](https://fedoraproject.org/wiki/Remix).

Before publishing an image, include its SHA-256 checksum and the notices and
corresponding source required by the licenses of the software it contains.
HyDEOS uses Fedora Linux software and HyDE; their names, marks, copyrights, and
licenses remain with their respective owners.

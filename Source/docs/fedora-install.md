# Fedora installation

HyDE's installer supports Fedora systems that use DNF. Install Git, clone HyDE,
then run the regular installer:

```bash
sudo dnf install git
git clone --depth 1 https://github.com/HyDE-Project/HyDE.git ~/HyDE
cd ~/HyDE/Scripts
./install.sh
```

The installer enables the `nett00n/hyprland` COPR for Hyprland and related
packages, plus `atim/starship` for Starship. It builds `hyprquery` from the HyDE
project source and `awww` v0.12.1 from upstream because Fedora does not provide
these tools as RPM packages.

For an unattended install with defaults, run:

```bash
./install.sh --defaults --restore --services
```

This selects zsh and the default SDDM theme and skips optional Flatpak and
Oh My Zsh prompts.

Fedora does not use the Arch NVIDIA DKMS path. Install and configure NVIDIA
drivers through the Fedora method that matches your hardware before installing
HyDE.

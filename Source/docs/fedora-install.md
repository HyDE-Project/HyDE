# Fedora installation

HyDE's Fedora installer path supports Fedora 44 and newer systems that use DNF.
Fedora 43 ships Waybar 0.14, which does not load every wildcard include used by
HyDE's Waybar layout; Fedora 44 and newer ship Waybar 0.15 or newer. Install
Git, clone HyDE, then run the regular installer:

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

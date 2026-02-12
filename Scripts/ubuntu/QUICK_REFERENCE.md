# Quick Reference: Ubuntu 24.04 Package Equivalencies for Hyprland

This is a condensed reference for the Arch→Ubuntu package mapping. For detailed instructions, see `UBUNTU_PACKAGE_MAPPING.md`.

## Installation Quick Commands

### 1. Install Essential Apt Packages
```bash
cd Scripts/ubuntu
./install_ubuntu_essentials.sh
```

### 2. Compile Hyprland Ecosystem
```bash
cd Scripts/ubuntu
./compile_hyprland_ecosystem.sh --recommended
```

### 3. Manual Updates (When Needed)
```bash
cd Scripts/ubuntu
./manual_update.sh
```

---

## Package Quick Reference

### Audio System ✅ (apt)
| Arch | Ubuntu | Command |
|------|--------|---------|
| `pipewire` | `pipewire` | `apt install pipewire` |
| `pipewire-audio` | `pipewire-audio-client-libraries` | `apt install pipewire-audio-client-libraries` |
| `gst-plugin-pipewire` | `gstreamer1.0-pipewire` | `apt install gstreamer1.0-pipewire` |
| `wireplumber` | `wireplumber` | `apt install wireplumber` |

### Network & Bluetooth ✅ (apt)
| Arch | Ubuntu | Command |
|------|--------|---------|
| `networkmanager` | `network-manager` | `apt install network-manager` |
| `network-manager-applet` | `network-manager-gnome` | `apt install network-manager-gnome` |
| `bluez-utils` | `bluez-tools` | `apt install bluez-tools` |

### Display Manager ✅ (apt)
| Arch | Ubuntu | Command |
|------|--------|---------|
| `sddm` | `sddm` | `apt install sddm` |
| `qt5-quickcontrols` | `qml-module-qtquick-controls` | `apt install qml-module-qtquick-controls` |
| `qt5-quickcontrols2` | `qml-module-qtquick-controls2` | `apt install qml-module-qtquick-controls2` |
| `qt5-graphicaleffects` | `qml-module-qtgraphicaleffects` | `apt install qml-module-qtgraphicaleffects` |

### Window Manager Core ❌ (compile)
| Arch | Ubuntu | Status |
|------|--------|--------|
| `hyprland` | **COMPILE** | See compilation guide |
| `uwsm` | **COMPILE** | See compilation guide |
| `xdg-desktop-portal-hyprland` | **COMPILE** | See compilation guide |

### WM Components (Mixed)
| Arch | Ubuntu | Status |
|------|--------|--------|
| `dunst` | ✅ `dunst` | `apt install dunst` |
| `rofi` | ✅ `rofi` | `apt install rofi` |
| `waybar` | ✅ `waybar` | `apt install waybar` |
| `swww` | ❌ **COMPILE** | Rust compilation |
| `hyprlock` | ❌ **COMPILE** | CMake compilation |
| `wlogout` | ❌ **COMPILE** | Meson compilation |
| `hypridle` | ❌ **COMPILE** | CMake compilation |
| `grim` | ✅ `grim` | `apt install grim` |
| `slurp` | ✅ `slurp` | `apt install slurp` |

### Theming ✅ (apt)
| Arch | Ubuntu | Command |
|------|--------|---------|
| `qt5ct` | `qt5ct` | `apt install qt5ct` |
| `qt6ct` | `qt6ct` | `apt install qt6ct` |
| `kvantum` | `qt6-style-kvantum` | `apt install qt6-style-kvantum` |
| `kvantum-qt5` | `qt5-style-kvantum` | `apt install qt5-style-kvantum` |
| `nwg-look` | **COMPILE** | Go compilation |

### Utilities
| Arch | Ubuntu | Status |
|------|--------|--------|
| `parallel` | ✅ `parallel` | `apt install parallel` |
| `jq` | ✅ `jq` | `apt install jq` |
| `imagemagick` | ✅ `imagemagick` | `apt install imagemagick` |
| `libnotify` | ✅ `libnotify-bin` | `apt install libnotify-bin` |
| `noto-fonts-emoji` | ✅ `fonts-noto-color-emoji` | `apt install fonts-noto-color-emoji` |
| `pacman-contrib` | 🔴 N/A | Use `apt list --upgradable` |

---

## Compilation Requirements

### Must Compile (Critical)
1. **hyprland** - The compositor
2. **uwsm** - Wayland session manager
3. **xdg-desktop-portal-hyprland** - Desktop integration

### Should Compile (Recommended)
4. **swww** - Wallpaper daemon (Rust)
5. **hyprlock** - Lock screen
6. **wlogout** - Logout menu
7. **hypridle** - Idle daemon

### Optional (Can Compile)
8. hyprpicker, satty, cliphist, wl-clip-persist, hyprsunset, nwg-look

---

## System Differences

### Package Manager Commands
| Action | Arch | Ubuntu |
|--------|------|--------|
| Update DB | `pacman -Sy` | `apt update` |
| Upgrade | `pacman -Syu` | `apt upgrade` |
| Install | `pacman -S pkg` | `apt install pkg` |
| Search | `pacman -Ss pkg` | `apt search pkg` |

### Service Management
| Action | Both |
|--------|------|
| Enable | `systemctl enable service` |
| Start | `systemctl start service` |
| Status | `systemctl status service` |

### Config Paths
| Type | Both |
|------|------|
| Hyprland | `~/.config/hypr/` |
| HyDE | `~/.config/hyde/` |
| Systemd user | `~/.config/systemd/user/` |

---

## Update Policy

**NO AUTOMATIC UPDATES** - All updates are manual:

- System packages: `sudo apt update && sudo apt upgrade`
- Hyprland ecosystem: `Scripts/ubuntu/manual_update.sh`

---

## Common Issues & Solutions

### Issue: Package not found
**Solution:** Enable universe repository:
```bash
sudo add-apt-repository universe
sudo apt update
```

### Issue: Build fails with missing dependencies
**Solution:** Run compilation script again (installs dependencies):
```bash
./compile_hyprland_ecosystem.sh
```

### Issue: Hyprland not in SDDM menu
**Solution:** Ensure SDDM is enabled:
```bash
sudo systemctl enable sddm
sudo systemctl restart sddm
```

### Issue: Want to update Hyprland
**Solution:** Use manual update script:
```bash
./manual_update.sh --hyprland
```

---

## File Locations

| File | Purpose |
|------|---------|
| `Scripts/UBUNTU_PACKAGE_MAPPING.md` | Complete mapping & compilation guide |
| `Scripts/pkg_ubuntu_core.lst` | Ubuntu package list |
| `Scripts/ubuntu/README.md` | Ubuntu-specific documentation |
| `Scripts/ubuntu/install_ubuntu_essentials.sh` | Install apt packages |
| `Scripts/ubuntu/compile_hyprland_ecosystem.sh` | Compile from source |
| `Scripts/ubuntu/manual_update.sh` | Manual updates only |
| `Scripts/ubuntu/QUICK_REFERENCE.md` | This file |

---

**Status Legend:**
- ✅ Available via apt (direct)
- ⚠️ Available via apt (different name)
- ❌ Requires compilation
- 🔴 No equivalent (Arch-specific)

**Last Updated:** 2026-02-12  
**Target:** Ubuntu 24.04.3 LTS (Noble)

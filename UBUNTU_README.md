# Ubuntu 24.04 Adaptation Available! 🐧

This fork includes a complete Ubuntu 24.04 adaptation for HyDE (Hyprland Desktop Environment).

## What's New

✅ **Essential Hyprland packages only** - No bloat, just core functionality  
✅ **Manual updates only** - You control when to update  
✅ **Complete package mapping** - Every Arch package mapped to Ubuntu equivalent  
✅ **Ready-to-use scripts** - Install and compile with simple commands  

## Quick Start for Ubuntu 24.04

### 1. Install Essential Packages (from apt)
```bash
cd Scripts/ubuntu
./install_ubuntu_essentials.sh
```
Installs ~42 packages: audio, network, display manager, basic WM components

### 2. Compile Hyprland Ecosystem (from source)
```bash
./compile_hyprland_ecosystem.sh --recommended
```
Compiles: Hyprland, uwsm, xdg-desktop-portal-hyprland, swww, hyprlock, wlogout, hypridle

### 3. Manual Updates (when you want them)
```bash
./manual_update.sh
```
Interactive menu for selective updates - **never runs automatically**

## Documentation

📖 **Complete Guide:** [`Scripts/UBUNTU_PACKAGE_MAPPING.md`](Scripts/UBUNTU_PACKAGE_MAPPING.md)  
📖 **Ubuntu README:** [`Scripts/ubuntu/README.md`](Scripts/ubuntu/README.md)  
📖 **Quick Reference:** [`Scripts/ubuntu/QUICK_REFERENCE.md`](Scripts/ubuntu/QUICK_REFERENCE.md)  
📖 **Summary:** [`Scripts/ubuntu/UBUNTU_ADAPTATION_SUMMARY.md`](Scripts/ubuntu/UBUNTU_ADAPTATION_SUMMARY.md)  

## What's Included

### ✅ Essential Packages (42 via apt)
- Audio: PipeWire + clients
- Network: NetworkManager, Bluez
- Display: SDDM + Qt modules
- WM: dunst, rofi, waybar, grim, slurp
- Integration: polkit, xdg portals
- Utilities: parallel, jq, imagemagick
- Theming: Qt5/Qt6, Kvantum

### ❌ Compiled Packages (13 from source)
**Critical:** hyprland, uwsm, xdg-desktop-portal-hyprland  
**Recommended:** swww, hyprlock, wlogout, hypridle  
**Optional:** hyprpicker, satty, cliphist, wl-clip-persist, hyprsunset, nwg-look  

### ❌ Not Included (Optional Apps)
Excluded as requested: Firefox, VS Code, Dolphin, Steam, Spotify, etc.

## Key Features

🔧 **Manual Updates Only**
- No automatic updates
- Dedicated manual update script
- User confirmation required
- Backup before updates

📋 **Clear Package Mapping**
- Every package status indicated (✅ apt, ❌ compile, 🔴 none)
- Exact installation commands
- Compilation instructions
- System differences documented

🎯 **Essential Only**
- Core Hyprland functionality
- Audio, network, display basics
- No optional applications

## For Arch Users

This fork maintains full Arch compatibility. The Ubuntu adaptation is completely separate:
- Original Arch scripts untouched
- Ubuntu-specific files in `Scripts/ubuntu/`
- Use original `install.sh` on Arch systems

## System Requirements (Ubuntu)

- **OS:** Ubuntu 24.04.3 LTS (Noble)
- **CPU:** 2+ cores (compilation takes 30-60 min)
- **RAM:** 8GB recommended
- **Disk:** ~2GB for build + install

## Files Created

```
Scripts/
├── UBUNTU_PACKAGE_MAPPING.md      # Complete Arch→Ubuntu mapping (19KB)
├── pkg_ubuntu_core.lst            # Ubuntu package list (6KB)
└── ubuntu/
    ├── README.md                  # Ubuntu documentation (7KB)
    ├── QUICK_REFERENCE.md         # Quick lookup tables (6KB)
    ├── UBUNTU_ADAPTATION_SUMMARY.md # Complete summary (9KB)
    ├── install_ubuntu_essentials.sh # Install apt packages (6KB)
    ├── compile_hyprland_ecosystem.sh # Compile from source (13KB)
    └── manual_update.sh           # Manual updates (13KB)
```

**Total:** 8 files, ~2,700 lines, comprehensive documentation + scripts

## Installation Time

- **Apt packages:** 5-10 minutes
- **Compilation:** 30-60 minutes (depends on CPU)
- **Total:** ~45-70 minutes

## Testing Status

⚠️ **Not yet tested on real Ubuntu 24.04 system**

This adaptation was created based on:
- Ubuntu 24.04 package availability research
- Official Hyprland build documentation
- Community compilation guides
- Package manager differences

**Please test and report issues!**

## Original HyDE Project

This is a fork of the original HyDE project:
- **Original:** [HyDE-Project/HyDE](https://github.com/HyDE-Project/HyDE)
- **Upstream docs:** [Original README](README.md)

## Credits

- **Original HyDE:** Prasanth Rangan and contributors
- **Ubuntu Adaptation:** This fork (2026-02-12)
- **Hyprland:** [hyprwm/Hyprland](https://github.com/hyprwm/Hyprland)

## License

Same as original HyDE project - see [LICENSE](LICENSE)

---

**🚀 Ready to try it?** Head to [`Scripts/ubuntu/`](Scripts/ubuntu/) to get started!

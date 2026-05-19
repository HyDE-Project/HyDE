# HALLwayDE

**The Hyprland Desktop Environment for HALLway OS**

> **Your desktop should be beautiful, functional, and yours — by default.**

HALLwayDE is a complete Hyprland desktop environment built for NixOS and the [HALLway](https://github.com/MarkusBitterman/HALLway) ecosystem. It originated as a fork of [HyDE](https://github.com/HyDE-Project/HyDE) and has been fully rebranded and adapted for declarative NixOS configuration.

---

## Table of Contents

- [What is HALLwayDE?](#what-is-hallwayde)
- [Quick Start](#quick-start)
- [Components](#components)
- [Configuration](#configuration)
- [Themes](#themes)
- [Keybindings](#keybindings)
- [Contributing](#contributing)
- [Origins & Acknowledgments](#origins--acknowledgments)

---

## What is HALLwayDE?

HALLwayDE is the desktop environment layer of HALLway OS. It provides:

| Component | Purpose |
|-----------|---------|
| **Hyprland** | Wayland compositor with animations and tiling |
| **Waybar** | Highly customizable status bar |
| **Rofi** | Application launcher and menu system |
| **Dunst** | Notification daemon |
| **Hyprlock** | Lock screen |
| **Wlogout** | Logout/power menu |
| **Wallbash** | Dynamic theming from wallpapers |

**Why HALLwayDE exists:**

- **NixOS-native** — Designed for declarative configuration with Home Manager
- **Part of HALLway** — Shares the ecosystem's philosophy of user sovereignty
- **Independent evolution** — The DE evolves separately from the OS configuration
- **Self-contained** — All configs live in this repo, not scattered across the system

---

## Quick Start

### For HALLway OS Users

HALLwayDE is designed to integrate with the [HALLway](https://github.com/MarkusBitterman/HALLway) NixOS flake.

**Prerequisites**: Hyprland and dependencies installed via NixOS/Home Manager

```bash
# Clone HALLwayDE
git clone https://github.com/MarkusBitterman/HALLwayDE.git ~/HALLwayDE

# Run the setup script
cd ~/HALLwayDE/Scripts
./setup-nixos.sh

# Or use the flake (in your HALLway config):
# imports = [ inputs.hallwayde.homeManagerModules.default ];
# hallwayde.enable = true;
```

### Required NixOS Packages

Add these to your NixOS or Home Manager configuration:

```nix
# Core (required)
hyprland
waybar
rofi-wayland
dunst
hyprlock
hypridle
wlogout
hyprpaper  # or swww

# Screenshots & clipboard
grim
slurp
cliphist

# Utilities
kitty          # terminal
brightnessctl  # brightness control
playerctl      # media controls
pamixer        # volume control

# Optional
hyprsunset     # blue light filter
satty          # screenshot annotation
dolphin        # file manager
```

---

## Components

### Core Utilities

| Tool | Description |
|------|-------------|
| `hallwayde-shell` | Shell wrapper for HALLwayDE operations |
| `hallwaydectl` | IPC control utility |
| `hallwayde-ipc` | Direct IPC communication |

### Scripts Library

Located in `~/.local/lib/hallwayde/`:

| Script | Function |
|--------|----------|
| `animations.sh` | Animation preset switching |
| `brightnesscontrol.sh` | Screen brightness with notifications |
| `volumecontrol.sh` | Audio volume with visual feedback |
| `screenshot.sh` | Screenshot capture (area, window, full) |
| `cliphist.sh` | Clipboard history manager |
| `lockscreen.sh` | Hyprlock launcher |
| `rofilaunch.sh` | Rofi menu launcher |
| `wallpaper.sh` | Wallpaper management |
| `theme.switch.sh` | Theme switching |

---

## Configuration

### Directory Structure

```
~/.config/
├── hypr/
│   ├── hyprland.conf      # Main config (sources others)
│   ├── keybindings.conf   # All keybindings
│   ├── windowrules.conf   # Window-specific rules
│   ├── monitors.conf      # Display configuration ← EDIT THIS
│   ├── userprefs.conf     # Your personal preferences ← EDIT THIS
│   ├── animations.conf    # Animation settings
│   └── themes/            # Theme colors
├── waybar/                # Status bar config
├── rofi/                  # Launcher themes
└── hallwayde/
    └── config.toml        # HALLwayDE settings

~/.local/
├── lib/hallwayde/         # Utility scripts
├── share/hallwayde/       # Data files, schemas
└── bin/                   # hallwayde-shell, hallwaydectl
```

### User Configuration Files

**`~/.config/hypr/monitors.conf`** — Your display setup:
```conf
# Single monitor
monitor=HDMI-A-1,1920x1080@60,0x0,1

# Dual monitors
monitor=DP-1,2560x1440@144,0x0,1
monitor=HDMI-A-1,1920x1080@60,2560x0,1
```

**`~/.config/hypr/userprefs.conf`** — Personal preferences:
```conf
input {
    kb_layout = us
    follow_mouse = 1
    sensitivity = 0

    touchpad {
        natural_scroll = yes
    }
}

misc {
    enable_swallow = true
    swallow_regex = (kitty|Alacritty)
}
```

---

## Themes

HALLwayDE supports dynamic theming via Wallbash — colors are extracted from your wallpaper.

### Available Themes

Compatible with themes from [HyDE-Project/hyde-themes](https://github.com/HyDE-Project/hyde-themes):

<div align="center">
  <table><tr><td>

[![Catppuccin-Latte](https://placehold.co/130x30/dd7878/eff1f5?text=Catppuccin-Latte&font=Oswald)](https://github.com/HyDE-Project/hyde-themes/tree/Catppuccin-Latte)
[![Catppuccin-Mocha](https://placehold.co/130x30/b4befe/11111b?text=Catppuccin-Mocha&font=Oswald)](https://github.com/HyDE-Project/hyde-themes/tree/Catppuccin-Mocha)
[![Decay-Green](https://placehold.co/130x30/90ceaa/151720?text=Decay-Green&font=Oswald)](https://github.com/HyDE-Project/hyde-themes/tree/Decay-Green)
[![Tokyo-Night](https://placehold.co/130x30/7aa2f7/24283b?text=Tokyo-Night&font=Oswald)](https://github.com/HyDE-Project/hyde-themes/tree/Tokyo-Night)
[![Gruvbox-Retro](https://placehold.co/130x30/475437/B5CC97?text=Gruvbox-Retro&font=Oswald)](https://github.com/HyDE-Project/hyde-themes/tree/Gruvbox-Retro)
[![Rosé-Pine](https://placehold.co/130x30/c4a7e7/191724?text=Rosé-Pine&font=Oswald)](https://github.com/HyDE-Project/hyde-themes/tree/Rose-Pine)
[![Nordic-Blue](https://placehold.co/130x30/D9D9D9/476A84?text=Nordic-Blue&font=Oswald)](https://github.com/HyDE-Project/hyde-themes/tree/Nordic-Blue)
[![Synth-Wave](https://placehold.co/130x30/495495/ff7edb?text=Synth-Wave&font=Oswald)](https://github.com/HyDE-Project/hyde-themes/tree/Synth-Wave)

  </td></tr></table>
</div>

### Theme Commands

```bash
# Switch theme
hallwayde-shell theme.switch.sh

# Set wallpaper
hallwayde-shell wallpaper.sh /path/to/wallpaper.jpg

# Keybinding
Super + T  # Theme selector
```

---

## Keybindings

See [KEYBINDINGS.md](KEYBINDINGS.md) for the complete reference.

### Essential Keys

| Keybind | Action |
|---------|--------|
| `Super + Return` | Terminal (Kitty) |
| `Super + D` | Application launcher (Rofi) |
| `Super + Q` | Close window |
| `Super + W` | Toggle floating |
| `Super + F` | Fullscreen |
| `Super + /` | Show all keybindings |
| `Super + L` | Lock screen |
| `Super + Shift + E` | Logout menu |

### Window Management

| Keybind | Action |
|---------|--------|
| `Super + Arrow` | Focus direction |
| `Super + Shift + Arrow` | Move window |
| `Super + 1-9` | Switch workspace |
| `Super + Shift + 1-9` | Move to workspace |

### Screenshots

| Keybind | Action |
|---------|--------|
| `Print` | Screenshot area |
| `Super + Print` | Screenshot window |
| `Ctrl + Print` | Screenshot full screen |

---

## Styles

<div align="center"><table><tr>Theme Select</tr><tr><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/theme_select_1.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/theme_select_2.png"/></td></tr></table></div>

<div align="center"><table><tr><td>Wallpaper Select</td><td>Launcher Select</td></tr><tr><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/walls_select.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/rofi_style_sel.png"/></td></tr></table></div>

<div align="center"><table><tr>Rofi Launcher</tr><tr><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/rofi_style_1.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/rofi_style_2.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/rofi_style_3.png"/></td></tr></table></div>

<div align="center"><table><tr>Wlogout Menu</tr><tr><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/wlog_style_1.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/wlog_style_2.png"/></td></tr></table></div>

---

## Contributing

We welcome contributions! HALLwayDE follows HALLway's development practices.

### Development Setup

```bash
git clone https://github.com/MarkusBitterman/HALLwayDE.git
cd HALLwayDE

# Enter dev shell with all tools
nix develop

# Make changes to configs in Configs/
# Test by symlinking to your ~/.config/

# Validate before committing
shellcheck Scripts/*.sh
```

### Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on your system
5. Submit a PR with clear description

---

## Origins & Acknowledgments

HALLwayDE originated as a fork of [HyDE](https://github.com/HyDE-Project/HyDE), the Hyprland Desktop Environment project. We've rebranded and adapted it for NixOS while maintaining theme compatibility with the upstream ecosystem.

**Upstream lineage:**
- [prasanthrangan/hyprdots](https://github.com/prasanthrangan/hyprdots) — Original Hyprdots project
- [HyDE-Project/HyDE](https://github.com/HyDE-Project/HyDE) — HyDE continuation
- [HyDE-Project/hyde-themes](https://github.com/HyDE-Project/hyde-themes) — Compatible theme repository

**Thanks to:**
- The HyDE Project team for the excellent foundation
- The Hyprland developers
- The NixOS community

---

## License

This project inherits the license from HyDE. See [LICENSE](LICENSE) for details.

---

<div align="center">

**Part of the [HALLway](https://github.com/MarkusBitterman/HALLway) ecosystem**

*Your digital life should live on your hardware, under your rules — by default.*

</div>

# DOORwayDE

**The Hyprland Desktop Environment for HALLway OS**

> **Your desktop should be beautiful, functional, and yours — by default.**

DOORwayDE is a complete Hyprland desktop environment built for NixOS and the [HALLway](https://github.com/MarkusBitterman/HALLway) ecosystem. It originated as a fork of [HyDE](https://github.com/HyDE-Project/HyDE) and has been fully rebranded and adapted for declarative NixOS configuration.

---

## Table of Contents

- [What is DOORwayDE?](#what-is-doorwayde)
- [Quick Start](#quick-start)
- [Components](#components)
- [Configuration](#configuration)
- [Themes](#themes)
- [Keybindings](#keybindings)
- [Contributing](#contributing)
- [Origins & Acknowledgments](#origins--acknowledgments)

---

## What is DOORwayDE?

DOORwayDE is the desktop environment layer of HALLway OS. It provides:

| Component | Purpose |
|-----------|---------|
| **Hyprland** | Wayland compositor with animations and tiling |
| **Waybar** | Highly customizable status bar |
| **Rofi** | Application launcher and menu system |
| **Dunst** | Notification daemon |
| **Hyprlock** | Lock screen |
| **Wlogout** | Logout/power menu |
| **Wallbash** | Dynamic theming from wallpapers |

**Why DOORwayDE exists:**

- **NixOS-native** — Designed for declarative configuration with Home Manager
- **Part of HALLway** — Shares the ecosystem's philosophy of user sovereignty
- **Independent evolution** — The DE evolves separately from the OS configuration
- **Self-contained** — All configs live in this repo, not scattered across the system

---

## Quick Start

### For HALLway OS Users

DOORwayDE is designed to integrate with the [HALLway](https://github.com/MarkusBitterman/HALLway) NixOS flake.

**Prerequisites**: Hyprland and dependencies installed via NixOS/Home Manager

```bash
# Clone DOORwayDE
git clone https://github.com/MarkusBitterman/DOORwayDE.git ~/DOORwayDE

# Run the setup script
cd ~/DOORwayDE/Scripts
./setup-nixos.sh

# Or use the flake (in your HALLway config):
# imports = [ inputs.doorwayde.homeManagerModules.default ];
# doorwayde.enable = true;
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
| `doorwayde-shell` | Shell wrapper for DOORwayDE operations |
| `doorwaydectl` | IPC control utility |
| `doorwayde-ipc` | Direct IPC communication |

### Scripts Library

Located in `~/.local/lib/doorwayde/`:

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
│   ├── hyprland.lua       # Main config (sources others)
│   ├── keybindings.lua    # All keybindings
│   ├── windowrules.lua    # Window-specific rules
│   ├── monitors.lua       # Display configuration ← EDIT THIS
│   ├── userprefs.lua      # Your personal preferences ← EDIT THIS
│   ├── animations.lua     # Animation settings
│   └── themes/            # Theme colors (wallbash still emits .conf
│                          #   colour files which dynamic.lua sources)
├── waybar/                # Status bar config
├── rofi/                  # Launcher themes
└── doorwayde/
    └── config.toml        # DOORwayDE settings

~/.local/
├── lib/doorwayde/         # Utility scripts
├── share/doorwayde/       # Data files, schemas
└── bin/                   # doorwayde-shell, doorwaydectl
```

### User Configuration Files

**`~/.config/hypr/monitors.lua`** — Your display setup:
```lua
-- Single monitor
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "0x0", scale = "1" })

-- Dual monitors
hl.monitor({ output = "DP-1",     mode = "2560x1440@144", position = "0x0",    scale = "1" })
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60",  position = "2560x0", scale = "1" })
```

**`~/.config/hypr/userprefs.lua`** — Personal preferences:
```lua
hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = { natural_scroll = true },
    },
    misc = {
        enable_swallow = true,
        swallow_regex = "(kitty|Alacritty)",
    },
})
```

---

## Themes

DOORwayDE supports dynamic theming via Wallbash — colors are extracted from your wallpaper.

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
doorwayde-shell theme.switch.sh

# Set wallpaper
doorwayde-shell wallpaper.sh /path/to/wallpaper.jpg

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

We welcome contributions! DOORwayDE follows HALLway's development practices.

### Development Setup

```bash
git clone https://github.com/MarkusBitterman/DOORwayDE.git
cd DOORwayDE

# Enter dev shell with all tools
nix develop

# Validate before committing
shellcheck Scripts/*.sh
```

### Testing Hyprland Changes

**Live-reload** — once inside any Hyprland session, apply config changes without restarting:

```bash
hyprctl reload

# Target a specific instance (if multiple are running)
ls /tmp/hypr/                                    # list instances
HYPRLAND_INSTANCE_SIGNATURE=<sig> hyprctl reload
```

**Via TTY** — full DRM backend, identical to a real login (useful for GPU-specific features):

```
Ctrl+Alt+F2  →  login  →  start-hyprland
Ctrl+Alt+F7  →  back to XFCE (session stays live)
```

Inside DOORwayDE: `Super + F5` reloads the config live (see [Keybindings](#keybindings)).

### Troubleshooting Hyprland

If Hyprland loads the emergency fallback or refuses to start, validate the lua config first — this works even on hosts where the compositor itself can't launch (e.g. nested under X11):

```bash
Hyprland --verify-config        # exits 0 if clean, 1 + errors otherwise
```

On NixOS where `~/.config/hypr/` is a read-only nix-store symlink, point `--verify-config` at the working tree and let `XDG_DATA_HOME` override resolution of `require()`d modules so your unactivated edits are seen:

```bash
XDG_DATA_HOME=$PWD/Configs/.local/share \
  Hyprland --verify-config -c $PWD/Configs/.config/hypr/hyprland.lua
```

Common errors and where to fix them:

| Error pattern | What it means | Where to fix |
|---|---|---|
| `unexpected symbol near 'repeat'` | Lua reserved keyword as a bare table key | Use `repeating = true` (upstream renamed `repeat` → `repeating`) |
| `attempt to call a nil value (field 'X')` | `hl.X` doesn't exist on this Hyprland version | Check the [upstream lua example](https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.lua); note that `hl.source` does **not** exist in 0.55.1 |
| `... expects string, got table` | Type mismatch in `hl.window_rule` / `hl.monitor` | Convert the table to the string form the API wants (e.g. `opacity = "0.9 0.9 1.0"`) |
| `Unknown keysym: "X"` | The trailing key in a bind isn't a valid xkb keysym | Use xkb's name (e.g. `Control_R`, not Hyprland's modifier shorthand `CTRL_R`) |
| `CBackend::create() failed!` | **Not a config issue** — backend / seat problem | Check `journalctl -u greetd`; this is a NixOS/HALLway concern, not DOORwayDE |

For the full walkthrough — decision tree, log paths, worked examples, the wallbash-lua gap — see [`Wiki/Troubleshooting-Hyprland.md`](Wiki/Troubleshooting-Hyprland.md).

### Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on your system
5. Submit a PR with clear description

---

## Origins & Acknowledgments

DOORwayDE originated as a fork of [HyDE](https://github.com/HyDE-Project/HyDE), the Hyprland Desktop Environment project. We've rebranded and adapted it for NixOS while maintaining theme compatibility with the upstream ecosystem.

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

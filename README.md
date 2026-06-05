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
| **QuickShell** | QML/Qt6 shell: top bar, sidebars, OSD, notifications, session screen |
| **matugen** | Material You color theming from the active wallpaper |
| **Rofi** | Application launcher and menu system |
| **Hyprlock** | Lock screen |
| **swww** | Animated wallpaper backend |

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

```nix
# In your HALLway (or any NixOS home-manager) config:
imports = [ inputs.doorwayde.homeManagerModules.default ];
doorwayde.enable = true;
```

### Required NixOS Packages

When using the flake (`homeManagerModules.default`), all packages are declared in `doorwaydeDeps` and managed automatically — no manual package list needed.

For manual setups, core dependencies include:

```nix
hyprland          # compositor
quickshell        # shell (bar, sidebars, OSD, notifications)
matugen           # Material You color theming
rofi-wayland      # launcher
hyprlock          # lock screen
hypridle          # idle daemon
swww              # wallpaper backend
material-symbols  # icon font for QuickShell surfaces
polkit_gnome      # authentication agent

# Screenshots & clipboard
grim  slurp  cliphist

# Utilities
kitty  brightnessctl  playerctl  wireplumber

# Optional
hyprsunset  satty  dolphin
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
| `brightnesscontrol.sh` | Screen brightness with OSD feedback |
| `volumecontrol.sh` | Audio volume with OSD feedback |
| `screenshot.sh` | Screenshot capture (area, window, full) |
| `cliphist.sh` | Clipboard history manager |
| `lockscreen.sh` | Hyprlock launcher |
| `rofilaunch.sh` | Rofi menu launcher |
| `wallpaper.sh` | Wallpaper management + matugen trigger |

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
│   └── animations.lua     # Animation settings
├── quickshell/doorwayde/  # QuickShell shell (bar, sidebars, OSD, notifications)
│   ├── shell.qml          # Entry point
│   └── modules/ii/        # IllogicalImpulse-derived panels
├── matugen/               # Material You color templates
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

DOORwayDE uses **matugen** (Material You) for dynamic theming — colors are extracted from your active wallpaper and applied to the QuickShell surfaces and Hyprland border colors in real time.

### How it works

1. `wallpaper.sh` sets the wallpaper and writes a trigger file to `~/.cache/doorwayde/wall.set`
2. `doorwayde-matugen-watcher` (systemd user service) detects the change via `inotifywait`
3. `matugen image <wallpaper>` generates a Material You palette and writes:
   - `~/.local/share/matugen/hyprland-colors.lua` — Hyprland border colors (sourced by `dynamic.lua`)
   - `~/.config/quickshell/doorwayde/modules/common/Colors.qml` — QuickShell color singleton
4. Hyprland reloads automatically; QuickShell picks up the new `Colors.qml` values

### Wallpaper commands

```bash
# Set wallpaper (triggers matugen automatically)
doorwayde-shell wallpaper.sh /path/to/wallpaper.jpg
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
| `Super + Delete` | Session screen (lock / suspend / reboot / shutdown) |
| `Super + SPACE` | Toggle right sidebar (system controls) |
| `Super + Shift + SPACE` | Toggle left sidebar (productivity) |

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

> Screenshots coming soon — DOORwayDE is under active development as of 2026-06.

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
shellcheck Configs/.local/lib/doorwayde/*.sh
```

### Testing Hyprland Changes

**Live-reload** — once inside any Hyprland session, apply config changes without restarting:

```bash
hyprctl reload

# Target a specific instance (if multiple are running)
ls /tmp/hypr/                                    # list instances
HYPRLAND_INSTANCE_SIGNATURE=<sig> hyprctl reload
```

**Via TTY** — full DRM backend, identical to a real login. Required for testing keybindings
and GPU-specific features (native KMS/DRM):

```
Ctrl+Alt+F2  →  login  →  start-hyprland
Ctrl+Alt+F7  →  back to XFCE (session stays live)
```

**Via nested Wayland** — for visual-only checks (bar renders, wallpaper appears) without
logging out. `start-hyprland` requires a running Wayland compositor. Keyboard input is dead
in nested mode (libseat cannot open `/dev/input/*`) — this is expected:

```bash
# From an XFCE Wayland terminal, or just run nix develop:
export PATH="$HOME/.local/lib/doorwayde:$PATH"
export XDG_SESSION_DESKTOP=Hyprland
export XDG_CURRENT_DESKTOP=Hyprland
start-hyprland
```

**Debugging startup failures** (empty desktop, no bar or wallpaper):

```bash
# Lua config errors (stdout disabled after init — check the log file):
cat /run/user/$(id -u)/hypr/*/hyprland.log | grep -v "DEBUG from aquamarine"

# Daemon crashes (exec-once failures are silent in the Hyprland log):
journalctl --user -b -n 200 | grep -iE "(quickshell|doorwayde|hypr)"

# Sanity-check app2unit.sh is findable (run from the debug terminal above):
doorwayde-shell app -u test.scope -t scope -- echo "ok"
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

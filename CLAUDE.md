# CLAUDE.md - AI Assistant Guidelines for HALLwayDE

## Project Overview

**HALLwayDE** is the Hyprland Desktop Environment for [HALLway OS](https://github.com/MarkusBitterman/HALLway). It originated as a fork of [HyDE](https://github.com/HyDE-Project/HyDE) and has been fully rebranded as an independent project adapted for NixOS.

**Important distinction:** HALLwayDE is NOT a "port" of HyDE. It IS HALLwayDE — its own project with its own identity, that happens to share lineage with HyDE. When writing documentation or comments, refer to this project as "HALLwayDE" not "HyDE fork" or "ported from HyDE".

### Philosophy

> **Your desktop should be beautiful, functional, and yours — by default.**

This project follows the HALLway ecosystem principles:
- **User sovereignty** — Configs live in the repo, not scattered across the system
- **Declarative where possible** — Nix flake with Home Manager module
- **Practical over pure** — Bash script fallback for quick setup
- **Fork-friendly** — Easy to customize and extend

## Architecture

```
HALLwayDE/
├── Configs/                    # All dotfiles (the payload)
│   ├── .config/
│   │   ├── hypr/              # Hyprland config (main entry point)
│   │   ├── waybar/            # Status bar
│   │   ├── rofi/              # App launcher
│   │   ├── dunst/             # Notifications
│   │   ├── hallwayde/         # HALLwayDE-specific settings
│   │   ├── kitty/             # Terminal
│   │   └── wlogout/           # Logout menu
│   └── .local/
│       ├── bin/               # hallwayde-shell, hallwaydectl, hallwayde-ipc
│       ├── lib/hallwayde/     # 100+ utility scripts
│       └── share/hallwayde/   # Data files, schemas, templates
├── Scripts/                    # Installation and setup scripts
│   └── setup-nixos.sh         # NixOS setup script
├── flake.nix                  # Nix flake with Home Manager module
└── README.md                  # User documentation
```

## Key Files

| File | Purpose |
|------|---------|
| `Configs/.config/hypr/hyprland.conf` | Main Hyprland config entry point |
| `Configs/.config/hypr/monitors.conf` | Monitor configuration (user edits this) |
| `Configs/.config/hypr/userprefs.conf` | User preferences (keyboard, etc.) |
| `Configs/.config/hypr/keybindings.conf` | All keybindings |
| `Configs/.local/lib/hallwayde/globalcontrol.sh` | Core environment setup |
| `flake.nix` | Nix flake with homeManagerModules.default |
| `Scripts/setup-nixos.sh` | Manual setup script for NixOS |

## Working with This Codebase

### Naming Conventions

- **hallwayde** (lowercase) — paths, variables, file names
- **HALLWAYDE_** — environment variable prefix
- **HALLwayDE** — branding, documentation, user-facing text
- **hallwayde-shell** — CLI tools use hyphenated lowercase

### Environment Variables

All HALLwayDE environment variables use the `HALLWAYDE_` prefix:

```bash
$HALLWAYDE_CONFIG_HOME   # ~/.config/hallwayde
$HALLWAYDE_DATA_HOME     # ~/.local/share/hallwayde
$HALLWAYDE_CACHE_HOME    # ~/.cache/hallwayde
$HALLWAYDE_THEME         # Current theme name
$HALLWAYDE_HYPRLAND      # Marker variable in hyprland.conf
```

### Adding New Features

1. **Scripts** go in `Configs/.local/lib/hallwayde/`
2. **Configs** go in `Configs/.config/<app>/`
3. **Update flake.nix** if adding new config directories
4. **Update setup-nixos.sh** if adding new symlink targets

### Testing Changes

```bash
# Quick test (symlink approach)
ln -sf ~/HALLwayDE/Configs/.config/hypr ~/.config/hypr
hyprctl reload

# Full dev environment
nix develop
shellcheck Scripts/*.sh
```

## Upstream Relationship

HALLwayDE is forked from HyDE. When referencing upstream:
- Keep GitHub URLs pointing to HyDE-Project for attribution
- Use "forked from HyDE" in comments where appropriate
- Don't rename upstream references in theme files

## Common Tasks

### Rebrand a new upstream merge

If pulling changes from HyDE upstream:
```bash
# After merge, fix branding
find . -type f \( -name "*.sh" -o -name "*.conf" \) -exec sed -i 's/hyde/hallwayde/g' {} +
find . -type f \( -name "*.sh" -o -name "*.conf" \) -exec sed -i 's/HYDE_/HALLWAYDE_/g' {} +
# Review changes carefully - some hyde references should stay (URLs, attribution)
```

### Add a new config directory

1. Add to `Configs/.config/<newdir>/`
2. Add to `flake.nix` in `xdg.configFile`
3. Add to `Scripts/setup-nixos.sh` in `config_dirs` array

## Code Style

- **Shell scripts**: Use `shellcheck`, prefer `[[ ]]` over `[ ]`
- **Nix**: Use `nixfmt` or `alejandra`
- **Configs**: Follow upstream HyDE style for consistency
- **Comments**: Explain *why*, not *what*

## Integration with HALLway

HALLwayDE is designed to be imported into HALLway's flake:

```nix
# In HALLway's flake.nix inputs:
hallwayde.url = "github:MarkusBitterman/HALLwayDE";

# In home-manager config:
imports = [ inputs.hallwayde.homeManagerModules.default ];
hallwayde = {
  enable = true;
  monitor = "HDMI-A-1,1920x1080@100,0x0,1";
  keyboard = "us";
};
```

The flake exposes `lib.hallwaydeDeps` so HALLway can reference the same package list.

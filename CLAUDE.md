# CLAUDE.md - AI Assistant Guidelines for DOORwayDE

## Project Overview

**DOORwayDE** is the Hyprland Desktop Environment for [HALLway OS](https://github.com/MarkusBitterman/HALLway). It originated as a fork of [HyDE](https://github.com/HyDE-Project/HyDE) and has been fully rebranded as an independent project adapted for NixOS.

**Important distinction:** DOORwayDE is NOT a "port" of HyDE. It IS DOORwayDE — its own project with its own identity, that happens to share lineage with HyDE. When writing documentation or comments, refer to this project as "DOORwayDE" not "HyDE fork" or "ported from HyDE".

### Philosophy

> **Your desktop should be beautiful, functional, and yours — by default.**

This project follows the HALLway ecosystem principles:
- **User sovereignty** — Configs live in the repo, not scattered across the system
- **Declarative where possible** — Nix flake with Home Manager module
- **Practical over pure** — Bash script fallback for quick setup
- **Fork-friendly** — Easy to customize and extend

## Architecture

```
DOORwayDE/
├── Configs/                    # All dotfiles (the payload)
│   ├── .config/
│   │   ├── hypr/              # Hyprland config (main entry point)
│   │   ├── waybar/            # Status bar
│   │   ├── rofi/              # App launcher
│   │   ├── dunst/             # Notifications
│   │   ├── doorwayde/         # DOORwayDE-specific settings
│   │   ├── kitty/             # Terminal
│   │   └── wlogout/           # Logout menu
│   └── .local/
│       ├── bin/               # doorwayde-shell, doorwaydectl, doorwayde-ipc
│       ├── lib/doorwayde/     # 100+ utility scripts
│       └── share/doorwayde/   # Data files, schemas, templates
├── Scripts/                    # Installation and setup scripts
│   └── setup-nixos.sh         # NixOS setup script
├── flake.nix                  # Nix flake with Home Manager module
└── README.md                  # User documentation
```

## Key Files

| File | Purpose |
|------|---------|
| `Configs/.config/hypr/hyprland.lua` | Main Hyprland config entry point |
| `Configs/.config/hypr/monitors.lua` | Monitor configuration (user edits this — lua format) |
| `Configs/.config/hypr/userprefs.lua` | User preferences (keyboard, etc.) |
| `Configs/.config/hypr/keybindings.lua` | All keybindings |
| `Configs/.local/share/doorwayde/hyprland.lua` | Core DOORwayDE orchestrator (env, variables, defaults, dynamic, startup, finale) |
| `Configs/.local/lib/doorwayde/globalcontrol.sh` | Core environment setup |
| `flake.nix` | Nix flake with homeManagerModules.default |
| `Scripts/setup-nixos.sh` | Manual setup script for NixOS |

## Working with This Codebase

### Naming Conventions

- **doorwayde** (lowercase) — paths, variables, file names
- **DOORWAYDE_** — environment variable prefix
- **DOORwayDE** — branding, documentation, user-facing text
- **doorwayde-shell** — CLI tools use hyphenated lowercase

### Environment Variables

All DOORwayDE environment variables use the `DOORWAYDE_` prefix:

```bash
$DOORWAYDE_CONFIG_HOME   # ~/.config/doorwayde
$DOORWAYDE_DATA_HOME     # ~/.local/share/doorwayde
$DOORWAYDE_CACHE_HOME    # ~/.cache/doorwayde
$DOORWAYDE_THEME         # Current theme name
$DOORWAYDE_HYPRLAND      # Marker variable in hyprland.lua
```

### doorwayde-shell Path Architecture

`doorwayde-shell` resolves `LIB_DIR` relative to its own Nix store path:
- `BIN_DIR` → `<nix-store>/.local/bin/`
- `LIB_DIR` → `<nix-store>/.local/lib/`
- Scripts must live in `$LIB_DIR/doorwayde/` (NOT `hyde/` — which no longer exists)

`env.lua` injects `~/.local/lib/doorwayde/` into PATH for Hyprland child processes.
`home.sessionPath` in `flake.nix` covers all other session processes (XFCE, TTY).
The `nix develop` shell also exports this PATH so `doorwayde-shell app` works directly.

### Adding New Features

1. **Scripts** go in `Configs/.local/lib/doorwayde/`
2. **Configs** go in `Configs/.config/<app>/`
3. **Update flake.nix** if adding new config directories
4. **Update setup-nixos.sh** if adding new symlink targets

### Testing Changes

Configs in `Configs/.config/hypr/` use Hyprland 0.55+ lua format (`hl.config`, `hl.bind`, `hl.window_rule`). `hyprctl reload` works the same on lua configs as it did on hyprlang.

```bash
# Quick test (symlink approach)
ln -sf ~/DOORwayDE/Configs/.config/hypr ~/.config/hypr
hyprctl reload

# Full dev environment
nix develop
shellcheck Scripts/*.sh
```

## Upstream Relationship

DOORwayDE is forked from HyDE. When referencing upstream:
- Keep GitHub URLs pointing to HyDE-Project for attribution
- Use "forked from HyDE" in comments where appropriate
- Don't rename upstream references in theme files

## Common Tasks

### Rebrand a new upstream merge

If pulling changes from HyDE upstream:
```bash
# After merge, fix branding
find . -type f \( -name "*.sh" -o -name "*.conf" \) -exec sed -i 's/hyde/doorwayde/g' {} +
find . -type f \( -name "*.sh" -o -name "*.conf" \) -exec sed -i 's/HYDE_/DOORWAYDE_/g' {} +
# Review changes carefully - some hyde references should stay (URLs, attribution)
```

Note: these `*.conf` sed commands no longer apply to the lua files in `Configs/.config/hypr/` (which DOORwayDE now owns and maintains directly). The commands are still safe to run — they simply won't match much in the hypr/ tree anymore. Lua-side rebranding should be done by hand or with a separate `-name "*.lua"` pass if upstream ever adopts lua.

### Add a new config directory

1. Add to `Configs/.config/<newdir>/`
2. Add to `flake.nix` in `xdg.configFile`
3. Add to `Scripts/setup-nixos.sh` in `config_dirs` array

### Debugging a Hyprland Session (Empty Desktop)

If Hyprland starts but shows only a cursor with no bar or wallpaper:

1. **Hyprland log** — Lua config errors appear here (stdout is disabled after init):
   ```bash
   cat /run/user/$(id -u)/hypr/*/hyprland.log | grep -v "DEBUG from aquamarine"
   ```

2. **exec-once failures** — silent in the Hyprland log; check journalctl:
   ```bash
   journalctl --user -b -n 200 | grep -iE "(waybar|dunst|doorwayde|hypr)"
   ```

3. **Sanity-check app2unit.sh** without logging out (from XFCE Wayland or `nix develop`):
   ```bash
   export PATH="$HOME/.local/lib/doorwayde:$PATH"
   export XDG_SESSION_DESKTOP=Hyprland
   export XDG_CURRENT_DESKTOP=Hyprland
   doorwayde-shell app -u test.scope -t scope -- echo "ok"
   ```

4. **Nested Hyprland** (`start-hyprland` inside a Wayland compositor) — visual checks only.
   Keyboard is dead in nested mode: libseat's builtin backend cannot open `/dev/input/*`.
   This is expected, not a DOORwayDE bug.

## Code Style

- **Shell scripts**: Use `shellcheck`, prefer `[[ ]]` over `[ ]`
- **Nix**: Use `nixfmt` or `alejandra`
- **Configs**: Follow upstream HyDE style for consistency
- **Comments**: Explain *why*, not *what*

## Integration with HALLway

DOORwayDE is designed to be imported into HALLway's flake:

```nix
# In HALLway's flake.nix inputs:
doorwayde.url = "github:MarkusBitterman/DOORwayDE";

# In home-manager config:
imports = [ inputs.doorwayde.homeManagerModules.default ];
doorwayde = {
  enable = true;
  monitor = "HDMI-A-1,1920x1080@100,0x0,1";
  keyboard = "us";
};
```

The flake exposes `lib.doorwaydeDeps` so HALLway can reference the same package list.

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
│   │   ├── quickshell/        # QuickShell shell (bar, sidebars, OSD, notifications, session)
│   │   ├── matugen/           # Color template engine (Material You from wallpaper)
│   │   ├── rofi/              # App launcher
│   │   ├── doorwayde/         # DOORwayDE-specific settings
│   │   └── kitty/             # Terminal
│   └── .local/
│       ├── bin/               # doorwayde-shell, doorwaydectl, doorwayde-ipc
│       ├── lib/doorwayde/     # 100+ utility scripts
│       ├── share/hypr/        # Session orchestrators (startup, variables, env, dynamic)
│       └── share/doorwayde/   # Data files, templates
├── flake.nix                  # Nix flake with Home Manager module
└── README.md                  # User documentation
```

## QuickShell Shell Architecture

DOORwayDE's shell surface (Initiative II, Phases 12–16) is a single QuickShell process forked from [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) `ii/` (GPLv3, attribution preserved).

### Surface ownership

| Surface | QML entry point | Wayland layer | Namespace |
|---------|----------------|---------------|-----------|
| Top bar | `modules/ii/bar/Bar.qml` | Top | `quickshell:bar` |
| Right sidebar | `modules/ii/sidebarRight/SidebarRight.qml` | Overlay | `quickshell:sidebarRight` |
| Left sidebar | `modules/ii/sidebarLeft/SidebarLeft.qml` | Overlay | `quickshell:sidebarLeft` |
| OSD | `modules/ii/osd/Osd.qml` | Overlay | `quickshell:osd` |
| Notification popups | `modules/ii/notifications/NotificationPopups.qml` | Overlay | `quickshell:notificationPopups` |
| Session screen | `modules/ii/session/SessionScreen.qml` | Overlay | `quickshell:session` |

All surfaces are loaded by `panelFamilies/IllogicalImpulseFamily.qml` via `PanelLoader`.

### Color theming (matugen)

`doorwayde-matugen-watcher.service` calls `matugen image <wallpaper>` whenever the wallpaper changes (inotifywait). Matugen renders two templates:

- `~/.local/share/matugen/colors/hyprland-colors.lua` — Hyprland border accent colors (dofile'd by hyprland.lua)
- `~/.local/share/matugen/colors/Colors.qml` — QuickShell `Colors` singleton with all Material You tokens

`Colors.qml` is watched by QuickShell via `FileView`; changes trigger a live theme reload with no restart.

### IPC keybindings

Sidebar/session toggles use `qs ipc`. Two workarounds are required for QS 0.3.0:
- `-c doorwayde` — selects the named config instance (not the "default")
- `--any-display` — bypasses a display-filter bug caused by an empty `instance.lock` file
- `ExecStartPost` in `doorwayde-quickshell.service` creates `by-id/ipc.sock` → live socket symlink that `qs ipc` resolves to

### Runtime writes

QuickShell itself never writes files. All runtime output goes through matugen's template engine to `~/.local/share/matugen/colors/` (writable, not Nix-managed).

## Key Files

| File | Purpose |
|------|---------|
| `Configs/.config/hypr/hyprland.lua` | Main Hyprland config entry point |
| `Configs/.config/hypr/monitors.lua` | Monitor configuration (user edits this — lua format) |
| `Configs/.config/hypr/userprefs.lua` | User preferences (keyboard, etc.) |
| `Configs/.config/hypr/keybindings.lua` | All keybindings |
| `Configs/.local/share/hypr/startup.lua` | exec-once app launch sequence |
| `Configs/.local/share/hypr/variables.lua` | App definitions and session variables |
| `Configs/.local/share/hypr/env.lua` | Environment variable injection into Hyprland |
| `Configs/.local/share/doorwayde/hyprland.lua` | Core DOORwayDE orchestrator (sources the share/hypr/ files) |
| `Configs/.local/lib/doorwayde/globalcontrol.sh` | Core environment setup |
| `flake.nix` | Nix flake with homeManagerModules.default |

## Nix Store Workflow — CRITICAL

### Never edit deployed paths directly

Every file under `~/.config/`, `~/.local/bin/`, `~/.local/lib/doorwayde/`,
`~/.local/share/doorwayde/`, etc. is either:

- A **symlink into the Nix store** (`/nix/store/…`) — root-owned, epoch-timestamped,
  `EROFS: read-only file system` on any write attempt, OR
- A **generated file** produced by Home Manager at activation time.

**Do not attempt to edit these paths.** The `EROFS` error is the signal, not a
permissions problem to work around. Any tool call that tries to `Edit` or `Write`
a `/nix/store/` path (or a path that symlinks there) will fail immediately.

### Where to make changes

Every deployed file has a 1:1 source in this repo under `Configs/` at the same
relative path:

| Deployed path | Source in this repo |
|---|---|
| `~/.config/hypr/hyprland.lua` | `Configs/.config/hypr/hyprland.lua` |
| `~/.local/share/waybar/` | `Configs/.local/share/waybar/` |
| `~/.local/lib/doorwayde/waybar.py` | `Configs/.local/lib/doorwayde/waybar.py` |
| `~/.local/bin/doorwayde-shell` | `Configs/.local/bin/doorwayde-shell` |
| `~/.local/share/doorwayde/hyprland.lua` | `Configs/.local/share/doorwayde/hyprland.lua` |

**Rule**: When a file needs changing, always edit under `Configs/`, then rebuild.

### Rebuilding after source changes

```bash
sudo nixos-rebuild switch --flake ~/Developments/HALLway/#2600AD
```

The git tree may be dirty — that is expected and harmless during development.

### Identifying Nix store files

```bash
ls -la ~/.config/waybar        # symlink → /nix/store/... → read-only
ls -la ~/.local/lib/doorwayde/waybar.py  # same pattern
stat ~/.local/lib/doorwayde/waybar.py   # mtime = Dec 31 1969 (epoch 0) = Nix store
```

Signs a path is Nix-managed:
- `ls -la` shows `-> /nix/store/...`
- File timestamp is `Dec 31  1969` (epoch 0)
- Owner is `root root` with `r--r--r--` permissions

### Runtime writes into config directories

If a script needs to **write data at runtime** (backups, caches, state), it must
NOT write into `~/.config/<app>/` — that directory may be a read-only Nix store
symlink. Use the correct XDG write location:

| Data type | Correct path | Example |
|---|---|---|
| Persistent user data | `$XDG_DATA_HOME` (`~/.local/share/`) | theme state |
| Regeneratable/cache | `$XDG_CACHE_HOME` (`~/.cache/`) | wallbash output, layout backups |
| Runtime state | `$XDG_STATE_HOME` (`~/.local/state/`) | doorwayde staterc |
| Temp/socket files | `$XDG_RUNTIME_DIR` (`/run/user/<uid>/`) | IPC sockets |

**Caveat:** `$XDG_DATA_HOME/<app>/` may also be a Nix-managed whole-dir symlink
(e.g. `~/.local/share/waybar/` → Nix store). If redirecting from config to data
still hits EROFS, redirect further to `$XDG_CACHE_HOME/doorwayde/<app>/`.

### Whole-directory vs individual file links in the flake

When `flake.nix` manages a config dir as a single entry:
```nix
"waybar".source = "${configDir}/.config/waybar";   # WHOLE-DIR SYMLINK
```
The entire `~/.config/waybar/` becomes a read-only Nix store symlink. No script
can create files inside it at runtime.

When it uses individual file links (like hypr was migrated to):
```nix
"hypr/hyprland.lua".source = "${configDir}/.config/hypr/hyprland.lua";
"hypr/keybindings.lua".source = ...;
```
Home Manager creates a real `~/.config/hypr/` directory with individual symlinks
inside it — and generated files (`monitors.lua`, `userprefs.lua`) can coexist.

**If a script crashes with `EROFS` writing into `~/.config/<app>/`**, the fix is
one of:
1. Redirect the write to `$XDG_DATA_HOME` or `$XDG_CACHE_HOME` (preferred for
   runtime-generated data that doesn't belong in config), OR
2. Migrate `flake.nix` from whole-dir to individual file links for that app
   (required when generated config files must live alongside source-controlled ones).

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
The `nix develop` shell also exports this PATH so `launch-unit.sh` works directly.

### Adding New Features

1. **Scripts** go in `Configs/.local/lib/doorwayde/`
2. **Configs** go in `Configs/.config/<app>/`
3. **Update flake.nix** if adding new config directories

### Flake-based deploy workflow (DOORwayDE → HALLway)

DOORwayDE is a flake input to HALLway. The Nix evaluator fetches the latest
**pushed** commit — local uncommitted changes are completely invisible to it.

```bash
# In this repo (DOORwayDE):
git commit && git push

# In HALLway:
nix flake update doorwayde   # updates flake.lock to latest pushed commit
sudo nixos-rebuild switch --flake ~/Developments/HALLway/#2600AD
```

**Always commit and push before rebuilding in HALLway.** `nix flake update`
without a prior push will silently reuse the previous commit.

### Testing Changes

Configs in `Configs/.config/hypr/` use Hyprland 0.55+ lua format (`hl.config`, `hl.bind`, `hl.window_rule`). `hyprctl reload` works the same on lua configs as it did on hyprlang.

```bash
# After nixos-rebuild switch — smoke-test the deployed config for type errors:
Hyprland --verify-config

# To verify SOURCE files before rebuilding (temporarily redirects system module symlinks):
orig_hypr=$(readlink ~/.local/share/hypr)
orig_dw=$(readlink ~/.local/share/doorwayde)
ln -sfn "$HOME/Developments/DOORwayDE/Configs/.local/share/hypr" ~/.local/share/hypr
ln -sfn "$HOME/Developments/DOORwayDE/Configs/.local/share/doorwayde" ~/.local/share/doorwayde
Hyprland --verify-config 2>&1
ln -sfn "$orig_hypr" ~/.local/share/hypr
ln -sfn "$orig_dw" ~/.local/share/doorwayde

# Full dev environment
nix develop
shellcheck Configs/.local/lib/doorwayde/*.sh
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

### Debugging a Hyprland Session (Empty Desktop)

If Hyprland starts but shows only a cursor with no bar or wallpaper:

0. **Parse the config first** — catches type errors and nil-function calls without a
   running session. Prints to stdout; no Error Overlay required:
   ```bash
   Hyprland --verify-config
   ```
   Common migration errors: `"on"`/`"off"` where a `bool` is required, a Lua table
   where a `string` is required, or calling a nil `hl.*` function (e.g. `hl.keyword`).

1. **Hyprland log** — Lua config errors appear in the Error Overlay (on-screen) but
   are NOT reliably written to the log file. The log is most useful for exec-once and
   backend errors, not config parse errors. When in doubt, use step 0 instead.
   ```bash
   cat /run/user/$(id -u)/hypr/*/hyprland.log | grep -v "DEBUG from aquamarine"
   ```

2. **exec-once failures** — silent in the Hyprland log; check journalctl:
   ```bash
   journalctl --user -b -n 200 | grep -iE "(waybar|quickshell|doorwayde|hypr)"
   ```

3. **Check for EROFS crashes in startup scripts** — `waybar.py`, `wallpaper.sh`, etc.
   may crash silently if they try to write inside a whole-dir Nix store symlink
   (`~/.config/waybar/`, etc.). See **Nix Store Workflow** section above.
   Quick test: `~/.local/lib/doorwayde/launch-unit.sh -u doorwayde-Hyprland-bar.scope -t scope -- waybar.py --watch`
   and check `/tmp/doorwayde-bar-launch.log` for a Python traceback.

4. **Sanity-check launch-unit.sh** without logging out (from XFCE Wayland or `nix develop`):
   ```bash
   export PATH="$HOME/.local/lib/doorwayde:$PATH"
   export XDG_SESSION_DESKTOP=Hyprland
   export XDG_CURRENT_DESKTOP=Hyprland
   launch-unit.sh -u test.scope -t scope -- echo "ok"
   ```

5. **Nested Hyprland** (`start-hyprland` inside a Wayland compositor) — visual checks only.
   Keyboard is dead in nested mode: libseat's builtin backend cannot open `/dev/input/*`.
   This is expected, not a DOORwayDE bug.

## Code Style

- **Shell scripts**: Use `shellcheck`, prefer `[[ ]]` over `[ ]`
- **Nix**: Use `nixfmt` (`nixfmt flake.nix`)
- **Python**: Use `ruff` (`ruff check --fix` or `ruff format`)
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

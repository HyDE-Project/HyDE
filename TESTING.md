# DOORwayDE Testing Guide

DOORwayDE is NixOS-only. The upstream HyDE install-script workflow does not apply.

## Quick Sanity Checks

After any change to `doorwayde-shell` or `flake.nix`:

```bash
# 1. Verify app2unit.sh is findable (the most common startup failure):
doorwayde-shell app -u test.scope -t scope -- echo "ok"

# 2. Lint shell scripts:
shellcheck Scripts/*.sh

# 3. Validate Hyprland Lua config:
XDG_DATA_HOME=$PWD/Configs/.local/share \
  Hyprland --verify-config -c $PWD/Configs/.config/hypr/hyprland.lua
```

`nix develop` automatically sets the PATH and XDG env vars needed for check #1.

---

## Testing Without Logging Out

Use an XFCE Wayland session as the outer compositor. From a terminal there:

```bash
# Recommended — sets env automatically:
nix develop

# Or export manually:
export PATH="$HOME/.local/lib/doorwayde:$PATH"
export XDG_SESSION_DESKTOP=Hyprland
export XDG_CURRENT_DESKTOP=Hyprland
```

Then:

| Goal | Method | Caveats |
|------|--------|---------|
| Visual checks (bar, wallpaper) | `start-hyprland` | Keyboard dead in nested mode — expected |
| Keybinding tests | TTY login (`Ctrl+Alt+F2`) | Full native session required |
| GPU / DRM features | TTY login | Needs real KMS backend |
| Config parse | `Hyprland --verify-config` | Can run anywhere |
| exec-once behavior | Native login | No CI equivalent yet |

> ⚠️ `start-hyprland` only works inside a running Wayland compositor.
> libseat's builtin backend cannot open `/dev/input/*` in nested mode — keyboard
> input will be completely dead. This is expected, not a DOORwayDE bug.

---

## Debugging a Hyprland Session

### Empty desktop (no bar, no wallpaper, no daemons)

```bash
# Step 1 — check for Lua config errors (stdout is disabled after init):
cat /run/user/$(id -u)/hypr/*/hyprland.log | grep -v "DEBUG from aquamarine"

# Step 2 — check for daemon crashes (exec-once failures are NOT in the Hyprland log):
journalctl --user -b -n 200 | grep -iE "(waybar|dunst|doorwayde|hypr)"

# Step 3 — verify app2unit.sh is findable (root cause of most empty-desktop issues):
doorwayde-shell app -u test.scope -t scope -- echo "ok"
```

### After `home-manager switch` deploys changes

Log into a native Hyprland session and verify:
- Waybar renders
- Wallpaper appears
- `notify-send test` triggers a dunst notification
- `Super + Q` closes a focused window (keybindings are always registered)

---

## NixOS Rebuild Workflow

```bash
# From ~/Developments/HALLway/ (host: #2600AD):
nixos-rebuild switch --flake .#2600AD

# Or home-manager only:
home-manager switch --flake .#bittermang@2600AD
```

---

## What Gets Tested

| Test | Tool | What it catches |
|------|------|----------------|
| Lua parse | `Hyprland --verify-config` | Syntax errors, nil `hl.*` API calls |
| Shell lint | `shellcheck Scripts/*.sh` | Shell script bugs |
| app2unit path | `doorwayde-shell app ... -- echo ok` | PATH / LIB_DIR mismatches in doorwayde-shell |
| Runtime startup | Native Hyprland login | exec-once failures, daemon crashes |

> **Note:** exec-once runtime failures are **silent** in the Hyprland log.
> They appear in `journalctl --user`. There is currently no CI coverage for
> them — testing requires a real session or a mock systemd user environment.

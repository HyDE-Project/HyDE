# DOORwayDE Lua Migration TODO

> **Goal**: Migrate Hyprland configs from hyprlang to lua format (Hyprland 0.55+)

## References

- [Official lua example](https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.lua)
- [Hyprland Wiki](https://wiki.hypr.land/Configuring/Start/)
- [Lua-ification announcement](https://hypr.land/news/26_lua/)

---

## Quick Fixes

- [x] **flake.nix**: Rename `swww` → `awww` (package renamed in nixpkgs)
- [ ] **flake.nix**: Verify `configType = "lua"` is correct after migration

---

## Phase 1: Entry Point

Create `hyprland.lua` as the new entry point that can coexist with existing `.conf` files during transition.

- [ ] Create `Configs/.config/hypr/hyprland.lua`
- [ ] Test hybrid loading (lua entry + hyprlang modules)

---

## Phase 2: User-Editable Configs

| File | Status | Notes |
|------|--------|-------|
| `monitors.conf` → `monitors.lua` | ⬜ TODO | User monitor config |
| `userprefs.conf` → `userprefs.lua` | ⬜ TODO | User preferences |
| `keybindings.conf` → `keybindings.lua` | ⬜ TODO | 150+ binds, custom grouping |
| `windowrules.conf` → `windowrules.lua` | ⬜ TODO | Window rules |
| `workflows.conf` → `workflows.lua` | ⬜ TODO | Workflow selector |

---

## Phase 3: Animation Presets

| File | Status |
|------|--------|
| `animations.conf` → `animations.lua` | ⬜ TODO |
| `animations/standard.conf` → `standard.lua` | ⬜ TODO |
| `animations/fast.conf` → `fast.lua` | ⬜ TODO |
| `animations/optimized.conf` → `optimized.lua` | ⬜ TODO |
| `animations/me-1.conf` → `me-1.lua` | ⬜ TODO |
| `animations/diablo-2.conf` → `diablo-2.lua` | ⬜ TODO |

---

## Phase 4: Theme System

| File | Status |
|------|--------|
| `themes/theme.conf` → `theme.lua` | ⬜ TODO |
| `themes/colors.conf` → `colors.lua` | ⬜ TODO |
| `themes/wallbash.conf` → `wallbash.lua` | ⬜ TODO |
| `shaders.conf` → `shaders.lua` | ⬜ TODO |

---

## Phase 5: Workflow Presets

| File | Status |
|------|--------|
| `workflows/default.conf` → `default.lua` | ⬜ TODO |
| `workflows/gaming.conf` → `gaming.lua` | ⬜ TODO |
| `workflows/editing.conf` → `editing.lua` | ⬜ TODO |
| `workflows/powersaver.conf` → `powersaver.lua` | ⬜ TODO |
| `workflows/snappy.conf` → `snappy.lua` | ⬜ TODO |

---

## Phase 6: Core DOORwayDE System

These files in `~/.local/share/hypr/` define the DOORwayDE runtime:

| File | Status | Notes |
|------|--------|-------|
| `variables.conf` | ⬜ TODO | Script paths, app commands, systemd integration |
| `defaults.conf` | ⬜ TODO | Default settings |
| `env.conf` | ⬜ TODO | Environment setup |
| `startup.conf` | ⬜ TODO | Autostart applications |
| `dynamic.conf` | ⬜ TODO | Dynamic theming |
| `windowrules.conf` | ⬜ TODO | Default window rules |
| `finale.conf` | ⬜ TODO | Variable finalization |

Main entry:
| File | Status |
|------|--------|
| `.local/share/doorwayde/hyprland.conf` | ⬜ TODO |

---

## Phase 7: Cleanup

- [ ] Update flake.nix to deploy `.lua` files
- [ ] Update scripts that reference `.conf` files (grep for `.conf`)
- [ ] Remove deprecated `.conf` files
- [ ] Update CLAUDE.md with lua config info
- [ ] Update README.md examples

---

## Files to Keep as hyprlang

These tools have their own config format (not Hyprland's):

| File | Reason |
|------|--------|
| `hyprlock.conf` | hyprlock's own parser |
| `hyprlock/*.conf` | hyprlock themes |
| `hypridle.conf` | hypridle's own parser |
| `hyprsunset.conf` | hyprsunset config |

---

## Syntax Quick Reference

```lua
-- Variables
local mainMod = "SUPER"
local terminal = "kitty"

-- Keybindings
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))

-- Config sections
hl.config({
    general = { gaps_in = 5, border_size = 2 },
    decoration = { rounding = 10 },
})

-- Window rules
hl.window_rule({
    match = { class = "^(pavucontrol)$" },
    float = true,
})

-- Monitor
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "0x0", scale = "1" })

-- Require other files
require("keybindings")
require("themes/colors")
```

---

## Progress Log

### 2026-05-20
- [x] Created TODO.md workbook
- [x] Fixed `swww` → `awww` in flake.nix
- [ ] Cleaned up HyDE legacy documentation (TEAM_ROLES.md, etc.)

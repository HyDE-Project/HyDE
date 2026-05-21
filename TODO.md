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

- [x] Create `Configs/.config/hypr/hyprland.lua`
- [ ] Test hybrid loading (lua entry + hyprlang modules via `hl.source()`)

---

## Phase 2: User-Editable Configs

| File | Status | Notes |
|------|--------|-------|
| `monitors.conf` → `monitors.lua` | ✅ DONE | User monitor config |
| `userprefs.conf` → `userprefs.lua` | ✅ DONE | User preferences |
| `windowrules.conf` → `windowrules.lua` | ✅ DONE | Window rules (with layer rules) |
| `keybindings.conf` → `keybindings.lua` | ✅ DONE | 150+ binds, custom grouping |
| `workflows.conf` → `workflows.lua` | ✅ DONE | Workflow selector |

---

## Phase 3: Animation Presets

| File | Status |
|------|--------|
| `animations.conf` → `animations.lua` | ✅ DONE |
| `animations/standard.conf` → `standard.lua` | ✅ DONE |
| `animations/fast.conf` → `fast.lua` | ✅ DONE |
| `animations/optimized.conf` → `optimized.lua` | ✅ DONE |
| `animations/me-1.conf` → `me-1.lua` | ✅ DONE |
| `animations/diablo-2.conf` → `diablo-2.lua` | ✅ DONE |

---

## Phase 4: Theme System

| File | Status |
|------|--------|
| `themes/theme.conf` → `theme.lua` | ✅ DONE |
| `themes/colors.conf` → `colors.lua` | ✅ DONE |
| `themes/wallbash.conf` → `wallbash.lua` | ✅ DONE |
| `shaders.conf` → `shaders.lua` | ✅ DONE |

---

## Phase 5: Workflow Presets

| File | Status |
|------|--------|
| `workflows/default.conf` → `default.lua` | ✅ DONE |
| `workflows/gaming.conf` → `gaming.lua` | ✅ DONE |
| `workflows/editing.conf` → `editing.lua` | ✅ DONE |
| `workflows/powersaver.conf` → `powersaver.lua` | ✅ DONE |
| `workflows/snappy.conf` → `snappy.lua` | ✅ DONE |

---

## Phase 6: Core DOORwayDE System

These files in `~/.local/share/hypr/` define the DOORwayDE runtime:

| File | Status | Notes |
|------|--------|-------|
| `variables.conf` → `variables.lua` | ✅ DONE | Shared-state lua module (returns table) |
| `defaults.conf` → `defaults.lua` | ✅ DONE | `hl.config()` + gestures as `hl.keyword()` |
| `env.conf` → `env.lua` | ✅ DONE | `hl.config({ env = {...} })` |
| `startup.conf` → `startup.lua` | ✅ DONE | `hl.config({ exec_once = {...} })`, reads `vars.start.*` |
| `dynamic.conf` → `dynamic.lua` | ✅ DONE | Sources theme files; `hl.keyword()` for `group:groupbar:*` |
| `windowrules.conf` → `windowrules.lua` | ✅ DONE | Core DOORwayDE rules (separate from user one) |
| `finale.conf` → `finale.lua` | ✅ DONE | `doorwayde:*` custom keywords via `hl.keyword()` + `pcall` |
| `migration.conf` | ⏭️ SKIPPED | Version-guard logic obsolete on pinned 0.55+ |

Main entry:
| File | Status |
|------|--------|
| `.local/share/doorwayde/hyprland.lua` | ✅ DONE — core orchestrator with `package.path` setup |
| User `.config/hypr/hyprland.lua` updated | ✅ DONE — `hl.source(.conf)` → `dofile(.lua)` |

**Load order (final):** `monitors` → `userprefs` → user `windowrules` → `keybindings` → `env` → `variables` → `defaults` → core `windowrules` → `dynamic` → `startup` → `workflows` → `finale`

**Caveats to verify at runtime:**
- `hl.keyword("group:groupbar:col.active", "rgba($wallbash_pry3ee)")` — does hyprland's lua bridge accept the dotted nested form?
- `hl.keyword("doorwayde:theme", ...)` — does it accept arbitrary custom-namespace keywords? Wrapped in `pcall` so failures are silent (matches original `# noerror true`)
- `hl.source()` of the wallbash-generated `.conf` files works during the hybrid period (and is still needed until Phase 7 updates the wallbash script to emit lua)

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
- [x] Cleaned up HyDE legacy documentation (TEAM_ROLES.md, etc.)
- [x] Created `hyprland.lua` entry point
- [x] Converted `monitors.conf` → `monitors.lua`
- [x] Converted `userprefs.conf` → `userprefs.lua`
- [x] Converted `windowrules.conf` → `windowrules.lua` (including layer rules)
- [x] Converted `workflows.conf` → `workflows.lua` (loader)
- [x] Converted `workflows/default.conf` → `default.lua`
- [x] Converted `workflows/gaming.conf` → `gaming.lua`
- [x] Converted `workflows/editing.conf` → `editing.lua`
- [x] Converted `workflows/powersaver.conf` → `powersaver.lua`
- [x] Converted `workflows/snappy.conf` → `snappy.lua`
- [x] Converted `animations.conf` → `animations.lua` (loader)
- [x] Converted `animations/standard.conf` → `standard.lua`
- [x] Converted `animations/fast.conf` → `fast.lua`
- [x] Converted `animations/optimized.conf` → `optimized.lua`
- [x] Converted `animations/me-1.conf` → `me-1.lua`
- [x] Converted `animations/diablo-2.conf` → `diablo-2.lua`
- [x] Converted `themes/theme.conf` → `theme.lua`
- [x] Converted `themes/colors.conf` → `colors.lua` (wallbash placeholder)
- [x] Converted `themes/wallbash.conf` → `wallbash.lua` (wallbash placeholder)
- [x] Converted `shaders.conf` → `shaders.lua`
- [x] Converted `keybindings.conf` → `keybindings.lua` (150+ binds, all bind flags)
- [x] **Phase 6**: Created shared `variables.lua` module (returns table for cross-file state)
- [x] Converted core `env.conf` → `env.lua`
- [x] Converted core `defaults.conf` → `defaults.lua`
- [x] Converted core `windowrules.conf` → `windowrules.lua`
- [x] Converted core `dynamic.conf` → `dynamic.lua` (hl.source for wallbash-generated theme files)
- [x] Converted core `startup.conf` → `startup.lua` (reads `vars.start.*` for daemon commands)
- [x] Converted core `finale.conf` → `finale.lua` (`doorwayde:*` keywords via pcall'd `hl.keyword`)
- [x] Created core entry `.local/share/doorwayde/hyprland.lua` (orchestrator with `package.path` setup)
- [x] Updated user `.config/hypr/hyprland.lua`: `hl.source(.conf)` → `dofile(.lua)`, removed stale TODO block, fixed workflows load order

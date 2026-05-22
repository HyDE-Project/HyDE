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

- [x] Update flake.nix to generate `monitors.lua` / `userprefs.lua` text= (was `.conf`)
- [x] Update `animations.sh` to find `*.lua` and write `animations.lua`
- [x] Convert remaining 14 animation `.conf` presets to `.lua` (full preset parity)
- [x] Update `workflows.sh` to write `workflows.lua` (kept `workflows/*.conf` as metadata source — see deferred section)
- [x] Update `keybinds_hint.sh` (removed dead `kb_hint_conf` array — actual hint generator is `hint-hyprland.py` which uses `hyprctl binds -j`)
- [x] Update `system.monitor.sh` (removed broken keybindings.conf grep, simplified to `${TERMINAL:-kitty}`)
- [x] Convert keybinding `description` strings from `"Group: action"` to `"[Group|Sub] action"` (113 substitutions; matches `hint-hyprland.py:parse_description` format)
- [x] Delete deprecated `.conf` files (27 files — see commit)
- [x] Delete dead placeholder lua files at `themes/{colors,theme,wallbash}.lua` (not required by anything; dynamic.lua sources the wallbash-generated `.conf` versions)
- [x] Update CLAUDE.md with lua config info
- [x] Update README.md examples

### Phase 7 Deferred (low-priority follow-ups)

- [ ] `workflows.sh:get_info` still reads `WORKFLOW_ICON` / `WORKFLOW_DESCRIPTION` from `workflows/*.conf` via `get_hyprConf`. Until we add lua-comment-based metadata parsing (or expose them as `_G.WORKFLOW_*` globals in the preset `.lua` files), we keep `workflows/*.conf` alongside `workflows/*.lua` purely as metadata sources.
- [ ] `wallbash` / `theme.switch` still emit hyprlang `themes/{colors,theme,wallbash}.conf`. `dynamic.lua` was supposed to source them via `hl.source()` — but `hl.source` **does not exist** on Hyprland 0.55.1 (confirmed empirically — see Phase 8 below). Migration plan needs to change to "wallbash emits `colors.lua` returning a colour table that `hl.config()` consumes."
- [x] ~~Runtime verification: `hl.keyword(...)` and `hl.source()` of wallbash-generated `.conf` files.~~ **Verified negative**: both APIs return nil on 0.55.1. Replaced `hl.keyword("gesture", ...)` with `hl.gesture({...})` and `hl.keyword("group:groupbar:*", ...)` with `hl.config({ group = { groupbar = {...} } })`. `hl.source()` has no equivalent — wallbash integration is on hold (see Phase 8).

---

## Phase 8: Post-migration follow-ups

Items discovered after the initial lua migration landed, while shaking down `--verify-config` errors and writing the troubleshooting docs.

### Documentation

- [x] **Wiki seeded** — `Wiki/README.md` (landing page / IA) and `Wiki/Troubleshooting-Hyprland.md` (depth article) created. README now points at the wiki for deep troubleshooting; the README itself only carries a concise cheat-sheet (~25 lines).
- [ ] **Write the remaining planned wiki articles** — `Architecture-Overview.md`, `Theming-and-Wallbash.md`, `Keybindings-Reference.md`, `Scripting-API.md`, `Lua-Migration-Notes.md`, `Hyprland-Lua-API-Cheatsheet.md`. See `Wiki/README.md` for one-line scopes.

### Wallbash → lua port (blocked by missing upstream API)

- [ ] **Refactor wallbash to emit lua.** The wallbash pipeline writes `~/.config/hypr/themes/colors.conf` (hyprlang format). `Configs/.local/share/hypr/dynamic.lua` was supposed to source it via `hl.source(...)`, but `hl.source` doesn't exist on 0.55.1 — `try_source(...)` calls in `dynamic.lua` are documented placeholder no-ops. Until `wallbash` is refactored to emit `themes/colors.lua` (a module returning a colour table that `hl.config({ general = { ["col.active_border"] = ... } })` consumes), dynamic wallbash-driven theming is on pause. Groupbar uses Hyprland defaults; window borders use the lua-side static values.
- [ ] **Watch for upstream sourcing API.** If Hyprland later adds a way to source other `.conf` / `.lua` files from a lua config, the existing `try_source(...)` placeholder in `dynamic.lua` becomes a one-line change.

### Config validation in CI

- [ ] **Wire `Hyprland --verify-config` into GitHub Actions.** It exists, returns exit codes, and was the only reason we caught the `repeat = true` bug, the `hl.keyword` nils, and the windowrules type mismatches. Add a workflow that runs `XDG_DATA_HOME=$PWD/Configs/.local/share Hyprland --verify-config -c $PWD/Configs/.config/hypr/hyprland.lua` on every PR so we can't reintroduce parse-level regressions.

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

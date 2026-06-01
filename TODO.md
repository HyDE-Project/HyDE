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

## Phase 9: De-HyDE migration (runtime → declarative)

> **Goal**: Now that Hyprland-on-NixOS is working, systematically replace HyDE's runtime-imperative patterns (Python/Bash scripts owning files and systemd units at session start) with declarative NixOS equivalents (flake.nix owns files via `xdg.configFile.X.text` and units via `systemd.user.services.X`).
>
> **Approach**: Small bursts, each leaves a working desktop. Rebuild + smoke-test between passes. Roadmap captured durably so work survives across sessions.

### Inventory: runtime-born systemd units (born by `launch-unit.sh` → `systemd-run --user`)

| Unit | Type | Command | Pass |
|---|---|---|---|
| `doorwayde-Hyprland-bar.scope` | scope | `waybar.py --watch` | 2 |
| `doorwayde-Hyprland-notifications.service` | service | `dunst` | 4 |
| `doorwayde-Hyprland-wallpaper.service` | service | `wallpaper.sh --start --global` | 4 |
| `doorwayde-Hyprland-text-clipboard.service` | service | `wl-paste --type text --watch cliphist store` | 3 |
| `doorwayde-Hyprland-image-clipboard.service` | service | `wl-paste --type image --watch cliphist store` | 3 |
| `doorwayde-Hyprland-clipboard-persist.service` | service | `wl-clip-persist --clipboard regular` | 3 |
| `doorwayde-Hyprland-network-manager-applet.service` | service | `nm-applet --indicator` | 3 |
| `doorwayde-Hyprland-removable-media-applet.service` | service | `udiskie --no-automount --smart-tray` | 3 |
| `doorwayde-Hyprland-bluetooth-applet.service` | service | `blueman-applet` | 3 |
| `doorwayde-Hyprland-battery-notify.service` | service | `batterynotify.sh` | 4 |
| `doorwayde-Hyprland-idle.service` | service | `hypridle` | 5 |
| `doorwayde-Hyprland-blue-light-filter.service` | service | `hyprsunset` | 5 |
| `doorwayde-Hyprland-doorwayde-config.service` | service | `doorwayde-config --no-startup` | 6 |
| (auth dialogue) | service | `polkitkdeauth.sh` | 6 |
| (XDG portal reset) | exec | `doorwayde-shell resetxdgportal.sh` | 6 |
| (gnome-keyring) | daemon | `gnome-keyring-daemon --daemonize` | 6 (cross-flake) |
| (dbus + systemd env import) | exec | `dbus-update-activation-environment` + `systemctl import-environment` | 6 |
| (cursor) | exec | `hyprctl setcursor` | stays (needs Hyprland IPC) |

### Pass-by-pass plan

- [x] **Pass 1 — Foundations** — khing hygiene + `includes.json` declarative + roadmap memory. Validates declarative-content pattern before touching the launch path.
- [ ] **Pass 2 — Waybar declarative service** — add `systemd.user.services.doorwayde-waybar` (preserve `Slice=app.slice`, `CollectMode=inactive-or-failed`, `ExitType=cgroup`, `Restart=always`, `WantedBy=[hyprland-session.target]`); remove `BAR = ...` from `variables.lua` + the `vars.start.BAR` exec from `startup.lua`; gut `watch_waybar()` in `waybar.py`. Highest-visibility unit, smallest blast radius if it works.
- [ ] **Pass 3 — Low-risk daemons (5 services)** — text-clipboard, image-clipboard, nm-applet, udiskie, blueman-applet. Stateless watchers. Verification: tray icons appear, cliphist accumulates.
- [ ] **Pass 4 — Notifications + battery + wallpaper (3 services)** — dunst, battery-notify, wallpaper. Wallpaper is trickiest (depends on theme state). Verify theme switching still works after.
- [ ] **Pass 5 — Idle + blue-light (2 services)** — hypridle, hyprsunset.
- [ ] **Pass 6 — One-shot setup units (cross-flake)** — `doorwayde-config --no-startup`, `polkitkdeauth.sh`, `resetxdgportal.sh`, dbus+systemd env import as oneshot services. **gnome-keyring**: DOORwayDE removes the runtime daemon launch from `variables.lua:81` + `startup.lua`; HALLway adds `services.gnome.gnome-keyring.enable = true` (system-level NixOS option for PAM auto-unlock). Both changes must land in one rebuild window.
- [ ] **Pass 7 — Delete `launch-unit.sh` and `app()` helper** — once all units are declarative, the wrapper has zero callers. Remove `Configs/.local/lib/doorwayde/launch-unit.sh`, the `app()` function, and the `start` table from `variables.lua`. Strip `startup.lua`'s `hl.on("hyprland.start", ...)` to just `hyprctl setcursor` (the IPC-dependent call that genuinely needs to run from Hyprland's lifecycle).
- [ ] **Pass 8 — waybar.py runtime writes audit + lift** — audit each runtime write (`config.jsonc`, `style.css`, `theme.css`, `global.css`, `user-style.css`, `staterc`). Categorize lift-able (Nix-eval-time) vs runtime (theme-state-derived). Result: waybar.py shrinks to theme-delta-only responsibilities.
- [ ] **Pass 9 — `doorwayde-shell` audit** — document current Nix-store-resolving wrapper shape; identify load-bearing vs vestigial HyDE inheritance. Mostly documentation pass.
- [ ] **Pass 10 — Final sweep** — update README + CLAUDE.md to reflect declarative model; remove vestigial HyDE references in docs; archive the Phase 9 entry.

### Pass 1 — completed work

- [x] **Khing hygiene** — `dunstrc` (6 lines, `/home/khing/` → `~/`), `cava.sh` (shellcheck directive → `/dev/null`), `wallbash.conf` (drop user path from line 4 comment).
- [x] **`includes.json` declarative** — flake.nix gains `xdg.configFile."waybar/includes/includes.json".text` generator using `builtins.readDir` over `${configDir}/.local/share/waybar/modules`. Source file at `Configs/.config/waybar/includes/includes.json` deleted. `waybar.py::generate_includes()` rewritten to write only `~/.config/waybar/includes/position.json` (the dynamic position delta). Every layout under `Configs/.local/share/waybar/layouts/` gets `$XDG_CONFIG_HOME/waybar/includes/position.json` added to its include array so the dynamic file gets picked up alongside the static Nix-managed one.
- [x] **Memory** — audit closed; `feedback_startup_debugging.md` tightened (absolute-paths rule scoped to `hl.exec_cmd()` startup context only — does NOT apply to keybinding dispatch or `setkw`-style metadata; counter-example: `variables.lua:39-42`); new memories for the roadmap pointer and the declarative-includes pattern; `MEMORY.md` index updated.

### Caveats / risk-control

- The desktop must be left working between passes. Any pass that breaks it gets reverted, root-caused, and re-attempted with tighter scope. Hyprland working is the load-bearing baseline.
- DOORwayDE → HALLway deploy is non-negotiable: `git commit && git push` in DOORwayDE *first*, then `nix flake update doorwayde` in HALLway, then `sudo nixos-rebuild switch`. Local DOORwayDE changes are invisible to the Nix evaluator. (See `feedback-flake-deploy-workflow` memory.)

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

### 2026-05-22
- [x] **Fix doorwayde-shell app subcommand** — PATH was built from `$LIB_DIR/hyde` (non-existent
  post-rebrand); updated to `$LIB_DIR/doorwayde`. Fixes all exec-once startup daemons (waybar,
  dunst, wallpaper, hypridle, etc.) silently failing on every Hyprland session.
- [x] **Fix doorwayde-shell globalcontrol.sh** — source path `hyde/` → `doorwayde/`
- [x] **Fix doorwayde-shell runtime dir** — `$XDG_RUNTIME_DIR/hyde` → `doorwayde`
- [x] **flake.nix home.sessionPath** — added `~/.local/lib/doorwayde` for session-wide coverage
  (complements env.lua which only covers Hyprland child processes)
- [x] **Dev shell shellHook** — documents start-hyprland Wayland-only limitation, log locations,
  sanity-check commands; exports Hyprland env vars for XFCE/dev testing
- [x] **Docs** — CLAUDE.md debugging + path architecture, TESTING.md replaced, CHANGELOG v26.5.22

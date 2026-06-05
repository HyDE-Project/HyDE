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

### Wallbash → lua port — **SUPERSEDED by Phase 11 (matugen)**

After surveying the Hyprland dotfiles landscape (2026-06-04 planning session), this work has been recoded from "blocked" to "superseded." The Phase 10-16 initiative replaces the wallbash → `hl.source()` pipeline with matugen → QuickShell `FileView` reactive subscription. Hyprland no longer needs to re-read color files at runtime — QuickShell will own all the colored UI surfaces (top bar, sidebars, OSD, notifications). The wallbash color extraction code (`Configs/.local/lib/doorwayde/color/hypr.sh`) is targeted for deletion in Phase 16.

- ~~Refactor wallbash to emit lua.~~ — Won't do. Matugen emits the formats QuickShell + GTK + Hyprland border colors consume directly via its template engine.
- ~~Watch for upstream sourcing API.~~ — Won't do. Architecture no longer depends on `hl.source()`.

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
- [x] **Pass 2 — Waybar declarative service** — added `systemd.user.services.doorwayde-waybar` to flake.nix; `waybar.py --watch` repurposed as `ExecStartPre` (preps state-file / config.jsonc / position.json then exits); `waybar` itself runs as `ExecStart`. Removed `BAR` line from `variables.lua` and the `hl.exec_cmd(vars.start.BAR)` from `startup.lua`. `watch_waybar()` gutted to just `generate_includes()`. The double-wrap (`bar.scope` wrapping `bar.service`) is gone — there's now a single declarative `doorwayde-waybar.service`.
- [x] **Pass 3 — Low-risk daemons (5 services)** — text-clipboard, image-clipboard, network-manager-applet, removable-media-applet, bluetooth-applet all declarative via the new `mkDoorwaydeService` helper in `flake.nix`. waybar refactored to use the helper too (the entire "DOORwayDE service template" now lives in one place). Slice corrected from `app.slice` (launch-unit.sh default) to `app-graphical.slice` for all 5 (per the Pass 2 lesson — these are graphical-session-dependent).
- [x] **Pass 4 — Notifications + battery + wallpaper (3 services)** — `doorwayde-notifications` (dunst), `doorwayde-battery-notify` (batterynotify.sh), `doorwayde-wallpaper` (wallpaper.sh --start --global) all declarative via `mkDoorwaydeService`. battery-notify reclassified into `app-graphical.slice` (Pass 2/3 reflection was wrong to call it non-graphical — it routes through notify-send → dunst). dunst uses `${pkgs.dunst}/bin/dunst`; the two DOORwayDE scripts use `%h/.local/lib/doorwayde/*.sh` absolute paths.
- [x] **Pass 5 — Idle + blue-light (2 services)** — `doorwayde-idle` (hypridle), `doorwayde-blue-light-filter` (hyprsunset). Cleanest pass yet: no scripts, no PATH dependencies, vanilla daemons with `${pkgs.X}/bin/X` ExecStart. Both `app-graphical.slice` via `mkDoorwaydeService` defaults. **Latent bug flagged for Pass 6**: `startup.lua:30` references `unt` which is `local` in variables.lua (not exported), so the doorwayde-config service unit name has been `nil-doorwayde-config.service` at runtime. Pass 6's declarative-oneshot migration removes this line entirely.
- [x] **Pass 6 — Session-bootstrap units (declarative oneshots + polkit daemon)** — 3 new units: `doorwayde-xdg-portal-reset` (oneshot, restarts xdg-desktop-portal services via `systemctl --user restart`), `doorwayde-polkit-auth` (daemon, `${pkgs.polkit_gnome}/libexec/...`), `doorwayde-config-bootstrap` (oneshot, runs `doorwayde-config --no-startup`). New `mkDoorwaydeOneshot` helper sibling to `mkDoorwaydeService`. `polkit_gnome` added to `doorwaydeDeps`. Latent `unt`-undefined bug from Pass 5 deleted with its containing line. **gnome-keyring deferred** to a future cross-flake step (see end of Phase 9). **Env imports stay in startup.lua** because UWSM (which HALLway uses) also performs them — they're defensive duplication, scheduled for removal in Pass 6.5.
- [x] **Pass 6.5 — UWSM-redundancy cleanup (audit-driven removal pass)** — Explore-agent audit (2026-06-02) confirmed UWSM performs env-import before Hyprland starts. Four removals landed, all reversible: (1) deleted `doorwayde-xdg-portal-reset` oneshot from `flake.nix` — portals already start with correct env via `After=graphical-session.target` + `ConditionEnvironment=WAYLAND_DISPLAY`; (2) deleted `dbus-update-activation-environment --systemd --all` and `hl.exec_cmd(vars.start.SYSTEMD_SHARE_PICKER)` from `startup.lua`; (3) deleted `SYSTEMD_SHARE_PICKER` from `variables.lua`'s `start` table plus the now-unused `list_environment` local; (4) deleted the stale "Workaround for env-propagation race" comment in `flake.nix`. Bonus cleanup: deleted dead-code `local home = os.getenv("HOME")` in `startup.lua` (unused since Pass 6 removed its consumer).
- [x] **Pass 7 — Delete `launch-unit.sh` and `app()` helper** — `Configs/.local/lib/doorwayde/launch-unit.sh` deleted (zero callers after Passes 2-6 declarative migrations). `app()` function, supporting locals (`session_desktop`, `unt`, `home`, `scrPath`), and the orphaned `scrPath` export in the M table all removed from `variables.lua`. `CLIPBOARD_PERSIST` entry deleted (was commented-out in startup.lua anyway; last remaining `app()` consumer). The `start` table now contains only `GNOME_KEYRING` (cross-flake deferred — see Pass 7+ section). Bonus: `variables.lua` shrunk from 95 lines to ~70 lines.
- [x] **Pass 8 — waybar.py runtime writes audit + icon-sizes regression fix** — full audit of runtime writes in `waybar.py`. `update_icon_size()` was writing icon-size-enriched data back to `includes.json` (now a Nix store symlink → EROFS regression introduced in Pass 1). Fixed: output redirected to new `icon-sizes.json`; all 19 layout files updated to include `icon-sizes.json` alongside `includes.json` + `position.json`. All other writes (`config.jsonc`, `style.css`, `theme.css`, `global.css`, `global.css`, `staterc`, `user-style.css` stub, `position.json`) confirmed correctly runtime-owned.
- [x] **Pass 9 — `doorwayde-shell` audit + HyDE-naming cleanup** — audited wrapper; renamed `HYDE_SCRIPTS_PATH` → `DOORWAYDE_SCRIPTS_PATH` (self-contained in `doorwayde-shell`; 0 external consumers); updated `hyprshutdown` label from HyDE branding to DOORwayDE. Documented Nix-store-resolving mechanism and the `DOORWAYDE_SHELL_INIT` guard pattern.
- [ ] **Pass 10 — Final sweep** — update README + CLAUDE.md to reflect declarative model; remove vestigial HyDE references in docs; archive the Phase 9 entry. *(Partial — script cleanup done; HyDE refs in macos.jsonc + custom-doorwayde-menu.jsonc + legacy hyprlang templates + docs sweep deferred.)*
- [x] **Pass 11 — Declarative GTK/cursor/font/env lift** — lifted static theme settings (GTK theme name, icon theme, cursor, fonts) from `theme.switch.sh` + `color/dconf.sh` (imperative HyDE pipeline) to `flake.nix` Home Manager declarations. Moved Qt/Wayland toolkit env vars from `env.lua` to `home.sessionVariables`. Deleted `color/dconf.sh` (its dconf nuclear-reset workflow was incompatible with `dconf.settings`; its `hyprctl setcursor` call was already in `startup.lua`). *(See Pass 11 section below.)*

### Pass 1 — completed work

- [x] **Khing hygiene** — `dunstrc` (6 lines, `/home/khing/` → `~/`), `cava.sh` (shellcheck directive → `/dev/null`), `wallbash.conf` (drop user path from line 4 comment).
- [x] **`includes.json` declarative** — flake.nix gains `xdg.configFile."waybar/includes/includes.json".text` generator using `builtins.readDir` over `${configDir}/.local/share/waybar/modules`. Source file at `Configs/.config/waybar/includes/includes.json` deleted. `waybar.py::generate_includes()` rewritten to write only `~/.config/waybar/includes/position.json` (the dynamic position delta). Every layout under `Configs/.local/share/waybar/layouts/` gets `$XDG_CONFIG_HOME/waybar/includes/position.json` added to its include array so the dynamic file gets picked up alongside the static Nix-managed one.
- [x] **Memory** — audit closed; `feedback_startup_debugging.md` tightened (absolute-paths rule scoped to `hl.exec_cmd()` startup context only — does NOT apply to keybinding dispatch or `setkw`-style metadata; counter-example: `variables.lua:39-42`); new memories for the roadmap pointer and the declarative-includes pattern; `MEMORY.md` index updated.

### Pass 2 — completed work

- [x] **Declarative `systemd.user.services.doorwayde-waybar`** in `flake.nix` with the full property set preserved from the imperative `systemd-run` call: `Type=exec`, `ExitType=cgroup`, `Slice=app-graphical.slice`, `Restart=always`, `RestartSec=1`, `After=PartOf=WantedBy=graphical-session.target`. `ExecStartPre=%h/.local/lib/doorwayde/waybar.py --watch` runs the state-file / `config.jsonc` / `position.json` prep; `ExecStart=${pkgs.waybar}/bin/waybar` runs the actual bar. The `%h` specifier and `${pkgs.waybar}` reference make the unit portable across users and tied to the flake's pinned waybar version.
- [x] **Removed imperative entry points** — `BAR = app("bar", "scope") .. "waybar.py --watch"` deleted from `Configs/.local/share/hypr/variables.lua`; `hl.exec_cmd(vars.start.BAR)` deleted from `Configs/.local/share/hypr/startup.lua`. Both replaced with `-- BAR: declarative (flake.nix)` breadcrumbs so future readers know where waybar lives now.
- [x] **`waybar.py::watch_waybar()` gutted** — was 24 lines doing `systemd-run` + duplicate-unit detection; now 4 lines doing just `generate_includes()`. Function kept so `waybar.py --watch` remains a valid invocation (it's the `ExecStartPre` command).
- [x] **The scope/service double-wrap is gone**: was `doorwayde-Hyprland-bar.scope` (Python supervisor) wrapping `doorwayde-Hyprland-bar.service` (waybar); now a single `doorwayde-waybar.service`.

### Pass 2 — design decisions inherited by future passes

- **Slice choice is per-service, not one-size-fits-all.** The old `launch-unit.sh` defaulted to `app.slice`; the old imperative `systemd-run` inside `waybar.py` used `app-graphical.slice`. The right answer depends on whether the service is genuinely graphical-session-dependent. Bar, notifications, wallpaper, tray applets → `app-graphical.slice`. Clipboard watchers, battery-notify → `app.slice` (no graphical dependency). When designing units in Passes 3-6, check whether the service needs the X/Wayland session for anything beyond `dbus` env import. *(Refined in Pass 3: clipboard watchers are graphical-session-dependent too — they consume Wayland clipboard data. Battery-notify and idle daemons are the remaining `app.slice` candidates.)*
- **`%h` over hardcoded `/home/$user/`.** systemd's `%h` specifier resolves per-user at activation time. Use it everywhere in declarative units that reference home-dir paths.
- **`${pkgs.X}/bin/X` for ExecStart binaries.** Pins the executable to the flake-evaluated package version and pulls it into the unit's Nix store closure. Don't rely on `home.packages` putting it on PATH and then PATH-resolving — that's the HyDE-runtime pattern we're moving away from.
- **`ExitType=cgroup` is load-bearing for forking processes.** Waybar, dunst, network-manager-applet all fork helpers. `ExitType=main` would treat "main pid exited but cgroup populated" as failure → restart loop. Preserve `cgroup`.

### Pass 3 — completed work

- [x] **`mkDoorwaydeService` helper** in `flake.nix`'s `let` block. Takes `{ description, execStart, execStartPre ? null, documentation ? null }`. Emits the full service definition with all Pass 2 design properties baked in (Type, ExitType, Slice, Restart, RestartSec, After, PartOf, WantedBy). Uses `lib.optionalAttrs` to omit `ExecStartPre`/`Documentation` when not supplied.
- [x] **5 new declarative services** via the helper: `doorwayde-text-clipboard`, `doorwayde-image-clipboard`, `doorwayde-network-manager-applet`, `doorwayde-removable-media-applet`, `doorwayde-bluetooth-applet`. ExecStart paths all use `${pkgs.X}/bin/X` form so the unit closure pins the binary versions.
- [x] **Existing `doorwayde-waybar` refactored** to use `mkDoorwaydeService` (was ~20 inline lines, now 5). Single source of truth for the service template.
- [x] **Removed imperative entries** — `TEXT_CLIPBOARD`, `IMAGE_CLIPBOARD`, `APPLET_NETWORK_MANAGER`, `APPLET_REMOVABLE_MEDIA`, `APPLET_BLUETOOTH` deleted from `variables.lua`'s `start` table; their `hl.exec_cmd` calls deleted from `startup.lua`. The disabled `CLIPBOARD_PERSIST` line stayed (not migrated; commented out in startup anyway).
- [x] **Hyprland exec-once chain shrunk further** — was 6 lines of `hl.exec_cmd(vars.start.X)` for the 5 daemons (plus battery-notify); now just `BATTERY_NOTIFY` remains in that block.

### Pass 3 — design decisions inherited by future passes

- **DRY threshold met at the helper.** Pre-Pass 3 there was 1 declarative service (waybar); Pass 3 added 5 more. Per CLAUDE.md "three similar lines is better than a premature abstraction" — once 6 services share the template, the abstraction earned its keep. Future passes (4, 5, 6) just call `mkDoorwaydeService` with description + execStart.
- **`lib.optionalAttrs` for optional unit properties.** When a service doesn't need `ExecStartPre` or `Documentation`, omit the attribute entirely rather than passing `null` or empty strings. systemd treats absent properties differently from empty ones (especially `Documentation`, which systemd parses for `systemctl status` output). Use `lib.optionalAttrs (cond) { Key = val; }`.
- **`wl-paste --watch <cmd>` works with absolute Nix store paths.** wl-paste `exec`s the command argument; passing `${pkgs.cliphist}/bin/cliphist` works regardless of the service's runtime PATH. Same pattern applies to anything `xargs`/`exec`-style that takes a command as an argument.

### Pass 4 — completed work

- [x] **3 new declarative services**: `doorwayde-notifications` (dunst), `doorwayde-battery-notify` (batterynotify.sh), `doorwayde-wallpaper` (wallpaper.sh --start --global).
- [x] **battery-notify slice corrected to `app-graphical.slice`.** The Pass 2/3 design notes wrongly classified it as non-graphical. It routes through `notify-send` → dbus → dunst (which IS graphical-session-only). The "would you want this running after logout?" test resolves cleanly: no.
- [x] **Removed imperative entries**: `NOTIFICATIONS`, `WALLPAPER`, `BATTERY_NOTIFY` deleted from `variables.lua`. `hl.exec_cmd(vars.start.{NOTIFICATIONS,WALLPAPER,BATTERY_NOTIFY})` deleted from `startup.lua`.
- [x] **Hyprland exec-once chain now contains only**: portal/dbus handoff (4 calls), auth dialogue, gnome-keyring, IDLE_DAEMON, BLUE_LIGHT_FILTER_DAEMON, doorwayde-config oneshot, hyprctl setcursor. Pass 5 takes idle + blue-light; Pass 6 takes the rest.

### Pass 4 — design decisions inherited by future passes

- **"Graphical-session-dependent" includes anything that talks to a graphical-session-only daemon.** battery-notify never opens a window, but it sends notifications through dbus to dunst, which is graphical-session-only. The dependency is transitive. Same logic applies to anything that uses `notify-send`, `dbus-send` (to UI services), `xdg-open`, etc.
- **PATH propagation chain is load-bearing fragility.** Both `batterynotify.sh` (sources globalcontrol.sh) and `wallpaper.sh` (does `eval $(doorwayde-shell init)`) require `~/.local/bin` on PATH. The current chain: `env.lua` sets Hyprland-child PATH → `systemctl --user import-environment PATH WAYLAND_DISPLAY XDG_*` (from `SYSTEMD_SHARE_PICKER`, line 19 of startup.lua) propagates it to the user manager → declarative services inherit it. **Updated 2026-06-02 (Pass 6)**: HALLway uses UWSM to launch Hyprland. UWSM activates `graphical-session.target` from the session script *with Hyprland's env*, so it already performs env-import before Hyprland starts. The `SYSTEMD_SHARE_PICKER` call in startup.lua is now defensive duplication, not load-bearing. Future cleanup pass can remove it once UWSM-only confidence is high.

### Pass 6 — completed work

- [x] **`mkDoorwaydeOneshot` helper** in flake.nix's `let` block — sibling to `mkDoorwaydeService`. `Type=oneshot`, `RemainAfterExit=true` (so graphical-session.target sees the unit as "active" after completion), `After/PartOf/WantedBy=graphical-session.target`, optional extra `after` deps. Used by all 2 new oneshots.
- [x] **3 new declarative units**: `doorwayde-polkit-auth` (daemon, `${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1` — replaces the polkitkdeauth.sh path-iteration script), `doorwayde-xdg-portal-reset` (oneshot, restarts xdg-desktop-portal-hyprland.service + xdg-desktop-portal.service after env propagation), `doorwayde-config-bootstrap` (oneshot, runs `~/.local/lib/doorwayde/doorwayde-config --no-startup`).
- [x] **`polkit_gnome` added to `doorwaydeDeps`** for closure self-containment. Previously it was being pulled in transitively from HALLway's system packages — now DOORwayDE declares its own.
- [x] **Removed imperative entries**: `DBUS_SHARE_PICKER` (redundant with `dbus-update-activation-environment --all` on the line above), `XDG_PORTAL_RESET`, `AUTH_DIALOGUE` deleted from variables.lua. Their `hl.exec_cmd` calls and the broken `unt`-referencing `launch-unit.sh doorwayde-config` line deleted from startup.lua. The `unt` latent bug from Pass 5 is resolved by deletion.
- [x] **`hl.on("hyprland.start", ...)` block now contains only 4 calls**: the broad `dbus-update-activation-environment --systemd --all`, `SYSTEMD_SHARE_PICKER` (env imports — can't be declarative), `GNOME_KEYRING` (cross-flake deferred), and `hyprctl setcursor`. From 13 lines down to 4 effective ones.

### Pass 6 — design decisions inherited by future passes

- **HALLway already uses UWSM.** This was discovered mid-Pass-6 and changes the picture: UWSM activates `graphical-session.target` from the session script (with Hyprland's env), which means it ALREADY performs `dbus-update-activation-environment` and `systemctl --user import-environment` before Hyprland is even running. The env-import calls in startup.lua are now **defensive duplication, not load-bearing**. They were left in place for this pass to avoid an aggressive change in a chunky migration — a future cleanup pass can remove them once we're confident UWSM is reliably the session entry point. This also explains why all prior passes' declarative `WantedBy=graphical-session.target` services started cleanly: UWSM is the missing piece that makes the target lifecycle work correctly.
- **`After=graphical-session.target` for oneshots** (not `Before=`). The env imports happen during target activation; oneshots that depend on them run after the target is "active." `Before=` would deadlock with `WantedBy=`. The current pattern is correct.
- **`%h/.local/lib/doorwayde/*` for repo-shipped scripts/binaries**; `${pkgs.X}/bin/X` for nixpkgs-provided binaries. Both forms appear in unit ExecStart lines; the distinction is "is this our code or upstream code?"

### Pass 6.5 — completed work

- [x] **3 source-of-rot removals** (one declarative unit + two startup.lua exec_cmd calls): `doorwayde-xdg-portal-reset` oneshot, `dbus-update-activation-environment --systemd --all`, `systemctl --user import-environment` (the SYSTEMD_SHARE_PICKER expansion). All confirmed-redundant under UWSM via Explore-agent audit citing `wayland-session-waitenv.service` timing and `xdg-desktop-portal-hyprland.service` `ConditionEnvironment=WAYLAND_DISPLAY` passing.
- [x] **Variable cleanup**: `list_environment` local (no consumers after SYSTEMD_SHARE_PICKER removal) and the dead `local home = os.getenv("HOME")` in `startup.lua` (no consumers after Pass 6 removed its launch-unit.sh call).
- [x] **Comment hygiene**: removed the stale "Workaround for the env-propagation race" preamble in `flake.nix`; collapsed startup.lua's hl.on body comment to one line referencing TODO Phase 9; renamed the `Pass 6 → 7 deferred: gnome-keyring` section to `Pass 7+ deferred` to avoid colliding with this newly-defined Pass 6.5.
- [x] **`hl.on("hyprland.start", ...)` block is now 2 effective calls**: gnome-keyring (cross-flake deferred) and `hyprctl setcursor` (IPC-dependent, stays). Down from 13 calls at Pass 1 start, 4 at Pass 6 end.

### Pass 6.5 — design decisions inherited by future passes

- **UWSM is the canonical session entry. Defensive duplication of UWSM-provided env propagation has no value.** Before adding session-init logic to `startup.lua` (env imports, portal resets, etc.), check whether UWSM already does it — it probably does. See `memory/feedback_uwsm_session_entry.md` for the rule.
- **Hooks fire per-Edit, not per-batch.** When deleting a symbol and its consumers across separate Edits, delete consumers FIRST, declaration SECOND, to avoid intermediate-broken-state hook errors. (Caught during Pass 6.5: deleting `list_environment` before removing `SYSTEMD_SHARE_PICKER` tripped `verify-config`. Final state was correct; intermediate state was broken.)

### Pass 7 — completed work

- [x] **Script file deletion**: `Configs/.local/lib/doorwayde/launch-unit.sh` (37 lines, the wrapper around `systemd-run` that the HyDE-era `app()` helper used to create transient units at session start).
- [x] **`variables.lua` shrinkage**: removed `app()` function (5 lines), supporting locals `home`/`scrPath`/`session_desktop`/`unt` (5 lines), `scrPath` export from the `M` table, and the `CLIPBOARD_PERSIST` entry from the `start` table. Three consumer-first Edits to avoid the Pass 6.5 hook-state issue.
- [x] **`flake.nix` comment refresh**: the "Declarative replacement for..." block updated to reflect that launch-unit.sh + app() are now deleted, not merely replaced — Pass 7 closes that historical arc.
- [x] **The `start` table now contains ONE entry**: `GNOME_KEYRING`. Once the cross-flake migration lands, the table disappears entirely and `variables.lua` becomes a pure data module.

### Pass 7 — what's left in the Hyprland-side runtime surface

`Configs/.local/share/hypr/startup.lua` `hl.on("hyprland.start", ...)` body now contains exactly **2 calls**:
- `hl.exec_cmd(vars.start.GNOME_KEYRING)` — cross-flake deferred (Pass 7+)
- `hl.exec_cmd("hyprctl setcursor ...")` — genuinely IPC-dependent, stays forever

Pass 7+ (gnome-keyring cross-flake) is the only remaining task on the de-HyDE migration ledger. After it lands, startup.lua becomes a 4-line file: just the cursor call inside the `hl.on` hook.

### Pass 7+ — CLOSED 2026-06-02: gnome-keyring cross-flake migration completed

User confirmed HALLway has `services.gnome.gnome-keyring.enable = true` and `security.pam.services.greetd.enableGnomeKeyring = true`. With the system-side declarative keyring + PAM auto-unlock in place, DOORwayDE removed:

- [x] `GNOME_KEYRING` entry from `variables.lua` `start` table.
- [x] **The entire `start` table** — now had zero remaining entries (last commented-out vestige removed). `variables.lua` is now a pure data module.
- [x] `hl.exec_cmd(vars.start.GNOME_KEYRING)` call from `startup.lua`.
- [x] `gnome-keyring` from `doorwaydeDeps` in `flake.nix` (HALLway provides it system-level; closure self-containment principle inverted here — keyring is a system concern, not a per-user-DE concern).

`hl.on("hyprland.start", ...)` body is now exactly **1 call**: `hl.exec_cmd("hyprctl setcursor ...")`. The genuinely-IPC-dependent cursor theme set is the only remaining runtime-imperative entry in the entire Hyprland-side startup chain. Migration ledger is functionally complete for the unit/exec surface — only documentation work (Passes 8-10) remains.

**Critical**: HALLway change must land FIRST. Otherwise there's a window where keyring isn't running.

### Pass 8 — completed work (2026-06-02)

**Audit findings**: `waybar.py` makes 8 distinct file writes at runtime.

| File | Location | Category | Rationale |
|---|---|---|---|
| `config.jsonc` | `~/.config/waybar/` | runtime | layout-derived; copied from user-selected layout file |
| `style.css` | `~/.config/waybar/` | runtime | theme/layout-derived; `write_style_file()` embeds @imports + wallbash colors |
| `theme.css` | `~/.config/waybar/` | runtime | wallbash-generated with live color values |
| `global.css` | `~/.config/waybar/includes/` | runtime | font family/size from user config + theme + state |
| `border-radius.css` | `~/.config/waybar/includes/` | runtime | Hyprland decoration:rounding via IPC or theme |
| `user-style.css` | `~/.config/waybar/` | runtime / seed | "create if absent" guard — user-editable stub, must NOT be Nix-managed |
| `position.json` | `~/.config/waybar/includes/` | runtime | waybar position from user config (`WAYBAR_POSITION`) |
| `icon-sizes.json` | `~/.config/waybar/includes/` | runtime (**NEW**) | icon-size overrides from module JSON files; was incorrectly targeting `includes.json` |

**Regression identified and fixed**: `update_icon_size()` was reading `includes.json` (now a Nix store symlink since Pass 1's declarative lift) and writing the icon-size-enriched data back to that same path → silent EROFS failure; icon sizes were never applied. Fixed by redirecting output to `icon-sizes.json` (new writable file). All 19 layout `.jsonc` files updated to `@include` it alongside `includes.json` and `position.json`.

- [x] `waybar.py::update_icon_size()` redirected from `includes.json` (Nix store symlink) to `icon-sizes.json` (new writable file).
- [x] All 19 layout files under `Configs/.local/share/waybar/layouts/` updated with `$XDG_CONFIG_HOME/waybar/includes/icon-sizes.json` in their include arrays.
- [x] `flake.nix` comment updated: waybar runtime-owned files list now correctly names `icon-sizes.json` and `position.json` as dynamic deltas; `user-style.css` correctly described as user-editable seed.

### Pass 9 — completed work (2026-06-02)

**`doorwayde-shell` audit findings:**

**Load-bearing mechanisms (keep):**
- Nix-store-resolving path: `BIN_DIR=$(dirname "$(which "${EXECUTABLE:-doorwayde-shell}")")` + `realpath ../lib` — `which` resolves through PATH to the actual Nix store path; `realpath` then navigates `../lib` and `../share` within the closure. Works without hardcoded paths.
- `DOORWAYDE_SHELL_INIT=1` guard — set on init, tested by 30+ lib scripts via `[[ $DOORWAYDE_SHELL_INIT -ne 1 ]] && eval "$(doorwayde-shell init)"`. Prevents double-sourcing of globalcontrol.sh.
- `DOORWAYDE_SCRIPTS_PATH` (formerly `HYDE_SCRIPTS_PATH`) — colon-separated search path for script dispatch in `run_command()`, `list_script*()`, and `list_scripts_pretty()`.

**Vestigial HyDE references cleaned:**
- [x] `HYDE_SCRIPTS_PATH` → `DOORWAYDE_SCRIPTS_PATH` (rename_all; 7 occurrences, all within `doorwayde-shell` itself — no external consumers in lib scripts).
- [x] `hyprshutdown --top-label "Stay HyDErated!🫧"` → `"Stay DOORway-ready! 🚪"` (cosmetic; `hyprshutdown` is a HyDE-era binary, behind an `if command -v hyprshutdown` guard, with `hyprctl dispatch exit 0` fallback).

### Pass 10 — in progress (2026-06-02)

**Script cleanup (done):**
- [x] `theme.import.py` deleted — dead code; pointed to `HyDE-Project/doorwayde-gallery.git` (URL clobbered by batch rename; no callers; not a DOORwayDE priority).
- [x] `dontkillsteam.sh` deleted — deprecated; referenced only in legacy hyprlang template files (`Configs/.local/share/doorwayde/keybindings.conf`, `templates/hypr/keybindings.conf`) which predate the Lua migration and are no longer the active config.
- [x] `doorwayde-launch.sh` deleted — deprecated wrapper whose only content was a `notify-send` telling callers to use `doorwayde-shell open` instead. No external callers.

**Remaining HyDE references found during audit (not yet fixed):**
- `Configs/.local/share/waybar/layouts/macos.jsonc` + `Configs/.local/share/waybar/modules/custom-doorwayde-menu.jsonc` — both contain `"theme-import": "hyde-shell app -T -- hydectl theme import"`. Neither `hyde-shell` nor `hydectl` exist in DOORwayDE; the menu button is already broken.
- `Configs/.local/share/doorwayde/keybindings.conf` + `templates/hypr/keybindings.conf` — legacy hyprlang format, reference `doorwayde-shell dontkillsteam` (now deleted). These files are vestigial (superseded by `Configs/.config/hypr/keybindings.lua`).

**Deferred to a future quality pass:**
- ~170 lib scripts audited for purpose (see script inventory above). Multiple duplicate name pairs found (`themeselect.sh`/`theme.select.sh`, `themeswitch.sh`/`theme.switch.sh`, `systemupdate.sh`/`system.update.sh`) — deferring pending a broader quality and intention review of the lib layer.
- README and CLAUDE.md updates for the declarative model (docs sweep proper).

### Pass 11 — completed (2026-06-02)

**Context:** DOORwayDE ships exactly one theme (Wallbash). The multi-theme gallery (`~/.config/doorwayde/themes/`) never existed in the repo — the HyDE imperative pipeline (`theme.switch.sh` + `color/dconf.sh`) was running on an empty directory. Pass 11 separates static settings (GTK theme name, icon theme, cursor, fonts — same on every session) from the genuinely runtime-dynamic part (wallbash colors extracted from the current wallpaper → CSS/Hyprland config).

**Static → declarative (flake.nix additions):**
- `home.sessionVariables` — Qt/Wayland toolkit vars (`QT_QPA_PLATFORM`, `QT_AUTO_SCREEN_SCALE_FACTOR`, `QT_WAYLAND_DISABLE_WINDOWDECORATION`, `QT_QPA_PLATFORMTHEME`, `MOZ_ENABLE_WAYLAND`, `GDK_SCALE`, `ELECTRON_OZONE_PLATFORM_HINT`). These were duplicated across `env.lua` (Hyprland-scoped) and the UWSM `env-hyprland.d` script; now single-source at session level.
- `gtk.enable = true` + `gtk.theme.name = "Wallbash-Gtk"` + `gtk.iconTheme.name = "Tela-circle-dracula"` + `gtk.font.*` — Home Manager generates `~/.config/gtk-3.0/settings.ini`, `~/.config/gtk-4.0/settings.ini`, and `~/.gtkrc-2.0` automatically. Replaces `theme.switch.sh`'s manual sed-writes to these files.
- `home.pointerCursor` (`Bibata-Modern-Ice`, size 24, `pkgs.bibata-cursors`) — sets `XCURSOR_THEME`/`XCURSOR_SIZE` session-wide, writes `~/.local/share/icons/default/index.theme`. Replaces the icon-symlink + Xresources cursor writes in `theme.switch.sh`.
- `dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark"` — static default. Previously `dconf.sh` computed `prefer-$dcol_mode` dynamically; that behavior is deferred (single-theme focus).

**Removed:**
- `color/dconf.sh` — deleted. The `dconf reset -f /` → `dconf load -f /` nuclear workflow was incompatible with `dconf.settings` (would overwrite HM-managed keys on every wallpaper change). Its `hyprctl setcursor` call was already in `startup.lua`. Its GTK/cursor/font variable exports were `env-theme` defaults anyway (hyq queries to the non-existent theme gallery were failing silently).
- `source "$LIB_DIR/doorwayde/color/dconf.sh"` call in `color.set.sh` — removed.

**Trimmed:**
- `env.lua` — Qt/Wayland toolkit vars removed (now in `home.sessionVariables`). XDG desktop identity vars + PATH kept as defensive layer for Hyprland-child processes.

**What stays runtime (NOT changed by Pass 11):**
- `wallpaper.sh` — wallpaper selection and swww backend.
- `color.set.sh` → `color/hypr.sh` — wallbash color extraction (dcol files) → CSS template substitution → `wallbash.conf` (Hyprland border colors). These are genuinely runtime (depend on the live wallpaper's color palette).
- `hyprctl setcursor` in `startup.lua` — requires a running Hyprland session; stays.
- `variables.lua` — still read by `color/hypr.sh` and other runtime scripts via `get_hyprConf()`. Untouched.
- `globalcontrol.sh` — still load-bearing for 30+ lib scripts. Untouched.

**Deprecated (target deletion in Pass 12, after soak):**
- `theme.switch.sh` — multi-theme orchestrator; dead for single Wallbash theme.
- `theme.select.sh` / `themeselect.sh` — rofi theme selector UI; dead (no theme gallery).
- `themeswitch.sh` — deprecated wrapper calling `theme.switch.sh`.

### Caveats / risk-control

- The desktop must be left working between passes. Any pass that breaks it gets reverted, root-caused, and re-attempted with tighter scope. Hyprland working is the load-bearing baseline.
- DOORwayDE → HALLway deploy is non-negotiable: `git commit && git push` in DOORwayDE *first*, then `nix flake update doorwayde` in HALLway, then `sudo nixos-rebuild switch`. Local DOORwayDE changes are invisible to the Nix evaluator. (See `feedback-flake-deploy-workflow` memory.)

---

# Initiative II: DOORwayDE Shell & Visual Redesign (Phases 10–16)

> **Goal**: Replace the inherited HyDE UI surface (waybar + dunst + wlogout) with a single coherent **QuickShell**-based shell. Drive theming declaratively via **matugen** (Material You from wallpaper). Build a productivity left sidebar (notes, workspace overview, todo/pomodoro, scratchpad-window manager) and a system-controls right sidebar (sliders, toggles, calendar, notifications, session). Visually stunning, readable, minimal — and finally *ours* rather than inherited-and-broken.

**Strategic decisions** (from 2026-06-04 planning session — full plan in `.claude/plans/https-github-com-richen604-hydenix-today-adaptive-turing.md`):

| Question | Choice |
|---|---|
| Widget framework | **QuickShell** (QML/Qt6, `pkgs.quickshell` 0.2.1) over AGS/eww/waybar-extension. Future-proof, Wayland-native, what end-4 migrated to. |
| Color theming | **matugen** (`pkgs.matugen` 3.1.0) — Material You from wallpaper, replaces blocked wallbash → Hyprland path. |
| AI tool | **Deferred to Phase 17+** — left sidebar focuses on productivity first. |
| Left sidebar | 4 tabs: Notes / Workspace Overview / Tasks (todo + pomodoro) / Scratchpad-Window Manager. |
| Waybar fate | **Replaced entirely** — QuickShell owns the top bar. waybar source tree deleted in Phase 16. |
| Reference architecture | **Fork end-4** `dots/.config/quickshell/ii/` (GPLv3, attribution); strip AI/weeb/anime; rebrand to `doorwaydeShell`. |

**Hydenix learning to adopt**: their `mutable.nix` Home Manager extension solves the EROFS-on-runtime-writes class once. Files marked `mutable = true; force = true;` are *copied* instead of symlinked, becoming writable. Inline in Phase 11 as `lib.mkMutableHomeFile`.

---

## Phase 10: De-HyDE Final Cleanup ✓ DONE (2026-06-04)

> **Goal**: Clear the last cosmetic / dead-code remnants from the HyDE inheritance before the QuickShell work lands. Low-risk; blocks nothing.

- [x] Delete `Configs/.local/lib/doorwayde/theme.switch.sh` (Pass 11 marked dead post-soak)
- [x] Delete `Configs/.local/lib/doorwayde/theme.select.sh`
- [x] Delete `Configs/.local/lib/doorwayde/themeselect.sh` (duplicate name pair)
- [x] Delete `Configs/.local/lib/doorwayde/themeswitch.sh` (duplicate name pair)
- [x] Delete broken waybar files: `layouts/macos.jsonc` (not active layout; full of hyde-shell refs) + `modules/custom-doorwayde-menu.jsonc` (only referenced by macos.jsonc + khing.jsonc — both inactive). Whole waybar tree gone in Phase 16 anyway.
- [x] Delete legacy hyprlang `Configs/.local/share/doorwayde/keybindings.conf` (superseded by `Configs/.config/hypr/keybindings.lua`)
- [x] `templates/hypr/keybindings.conf` — already absent; no action needed
- [x] Bonus: delete `Configs/.local/lib/doorwayde/theme.patch.sh` (no callers; called deleted theme.switch.sh)
- [x] Bonus: remove `SUPER+SHIFT+T` (themeselect) + `SUPER+SHIFT+R` (wallbashtoggle) keybinds from `keybindings.lua` — both depended on deleted scripts; themeselect had no theme gallery; wallbash mode selector moves to QuickShell Phase 13.
- [x] `Hyprland --verify-config` post-deletions — **config ok** (verified twice)

---

## Phase 11: Foundation (matugen + mutable.nix + QuickShell scaffold) ✓ DONE (2026-06-04)

> **Goal**: Stand up the runway. After this phase, all subsequent phases have a working substrate: matugen converts the current wallpaper to a Material You palette and writes it to durable paths; QuickShell starts as a systemd user service and renders an empty session; `mutable.nix` is available for any future runtime-writable file.

### flake.nix additions

- [x] Add `pkgs.matugen`, `pkgs.quickshell`, `pkgs.inotify-tools` to `doorwaydeDeps`
- [x] New `options.doorwayde.shell.enable` (default `false` until Phase 12 cutover)
- [x] `systemd.user.services.doorwayde-matugen-watcher` — `pkgs.writeShellScript` watches `~/.cache/doorwayde/wall.set` via `inotifywait -e moved_to,create`; runs `matugen image <wallpaper>` + `hyprctl reload` on each change; initial run at service start
- [x] `systemd.user.services.doorwayde-quickshell` — `ExecStart = "${pkgs.quickshell}/bin/quickshell -c %h/.config/quickshell/doorwayde"`, gated by `lib.mkIf cfg.shell.enable`, uses `mkDoorwaydeService`
- [x] `mkMutableHomeFile` helper inlined into flake `let` block — takes `{ path, source, mode }`, returns `home.activation` entry that `install -Dm` copies (not symlinks) the file, making it writable at runtime

### Source tree

- [x] Create `Configs/.config/quickshell/doorwayde/shell.qml` (Phase 11 scaffold — empty `ShellRoot {}`)
- [x] Wire in flake: `xdg.configFile."quickshell/doorwayde".source = ...` (whole-dir)
- [x] Create `Configs/.config/matugen/config.toml` — templates for `hyprland-colors.lua` (border colors via `dofile()`) and `Colors.qml` (QuickShell singleton, Phase 12)
- [x] Create `Configs/.config/matugen/templates/hyprland-colors.lua` — Tera template writing `hl.config({ general = { col = { active_border = "rgba({{hex_stripped}}ee)", ... } } })`
- [x] Create `Configs/.config/matugen/templates/Colors.qml` — Tera template writing a `pragma Singleton QtObject` with 26 Material You color properties
- [x] Wire matugen config in flake: `xdg.configFile."matugen/config.toml"` + `"matugen/templates"`
- [x] `dynamic.lua` updated: replaced no-op `try_source` placeholder block with live `io.open` + `pcall(dofile, ...)` for `~/.local/share/matugen/hyprland-colors.lua`; removed 3 dead `.conf` sourcing calls + stale header comment + 2 now-unused locals (`xdg_state`, `hypr_config`)

### Verification

- [ ] `systemctl --user status doorwayde-matugen-watcher` returns `active` (post nixos-rebuild)
- [ ] Changing wallpaper via `wallpaper.sh` triggers matugen run; `~/.local/share/matugen/hyprland-colors.lua` updated and border colors change
- [ ] `systemctl --user status doorwayde-quickshell` is inactive/disabled (shell.enable = false)
- [ ] `nix run nixpkgs#quickshell -- --help` returns (smoke-test the binary exists)

**Note**: template variable syntax (`{{colors.primary.default.hex_stripped}}`) should be verified against the installed matugen 4.0.0 with `matugen --dry-run` or by inspecting the first generated output. The 3.x format may differ from 4.x.

---

## Phase 12: Top Bar (the waybar replacement) ✓ DONE (2026-06-04)

> **Goal**: Achieve module parity with the current waybar's top-bar functionality in QuickShell, then disable the waybar service. Soft cutover: source files stay for rollback during soak.

### Fork & rebrand

- [ ] `git remote add upstream https://github.com/end-4/dots-hyprland.git` in a scratch clone; cherry-pick the `dots/.config/quickshell/ii/bar/` subtree
- [ ] Copy into `Configs/.config/quickshell/doorwayde/bar/`, rebrand string occurrences of `illogical-impulse` / `ii` → `doorwaydeShell`
- [ ] Copy `dots/.config/quickshell/ii/modules/common/` (Appearance, GlobalStates, Loader patterns) and `dots/.config/quickshell/ii/modules/services/` (Network, Bluetooth, MPRIS, Brightness reactive state)

### Module parity (priority order — daily-driver modules first)

- [ ] Workspaces (Hyprland IPC subscribe to workspace events)
- [ ] Active window title
- [ ] Clock + calendar pop-out
- [ ] System tray (StatusNotifierItem — must show nm-applet, blueman-applet, udiskie, clipboard watchers)
- [ ] Volume indicator (PipeWire / WirePlumber via QuickShell `PwAudio`)
- [ ] Battery + power profile (`powerprofilesctl`)
- [ ] Network indicator (NetworkManager via D-Bus)
- [ ] Bluetooth indicator
- [ ] CPU / GPU / temp (lower priority — implement only if missed)

### Cutover

- [ ] `config.doorwayde.shell.enable = true` in flake.nix
- [ ] Disable `systemd.user.services.doorwayde-waybar` in flake.nix (do NOT delete waybar source files yet — rollback safety for soak window)
- [ ] Update `Configs/.config/hypr/keybindings.lua` — remove waybar-toggle binds; redirect to QuickShell bar toggle if any user keybind used it
- [ ] Reduce `Configs/.local/share/hypr/variables.lua` waybar references; do not delete (Phase 16)

### Verification

- [ ] Top bar renders on each monitor
- [ ] Workspaces update on Hyprland workspace change
- [ ] Tray icons appear (all five applet services)
- [ ] Volume slider responds to media keys; mute toggle works
- [ ] `systemctl --user stop doorwayde-waybar` (or `pkill waybar`) does not break desktop
- [ ] Battery percentage matches `upower -i $(upower -e | grep BAT)`

---

## Phase 13: Right Sidebar (system controls) ✓ DONE (2026-06-04)

> **Goal**: Build the persistent system-controls surface. Hotkey-toggled (Super+SPACE) slide-in panel from the right edge with sliders for volume/brightness/mic, toggles + list dialogs for network/bluetooth, calendar, notification history, session menu.

### Fork

- [ ] Copy `dots/.config/quickshell/ii/sidebarRight/` into `Configs/.config/quickshell/doorwayde/sidebarRight/`; rebrand
- [ ] Drop any `AiChat.qml` / `Anime.qml` / `Translator.qml` imports if present in the sidebarRight tree (they live in sidebarLeft in end-4's structure; just confirm the right-side tree is AI-free)

### Components (port from end-4 fork)

- [ ] Volume slider + per-stream mixer + device picker (PipeWire)
- [ ] Brightness slider (`brightnessctl`)
- [ ] Mic slider (PipeWire input)
- [ ] Network toggle + WiFi list dialog (NetworkManager)
- [ ] Bluetooth toggle + device list dialog
- [ ] Night light toggle — wraps existing `hyprsunset` (already a declarative service in flake.nix)
- [ ] Power profile selector (`powerprofilesctl`)
- [ ] Calendar widget
- [ ] Notification history (panel placeholder; Phase 15 backs it with QuickShell `NotificationServer`)
- [ ] Session/power menu — **replaces wlogout** at Phase 16 cutover

### Wiring

- [ ] Add layer rule in `Configs/.config/hypr/windowrules.lua`:
  ```lua
  hl.layer_rule({ namespace = "^(quickshell:sidebarRight)$", rules = {"blur", "ignorezero"} })
  ```
- [ ] Slide-in/out via Hyprland layer animation curve (`layer = slide` style)
- [ ] Add keybind in `Configs/.config/hypr/keybindings.lua`:
  ```lua
  hl.bind("SUPER", "SPACE", hl.dsp.exec_cmd("qs-ipc doorwayde sidebarRight.toggle"))
  ```
  (or whatever IPC convention QuickShell offers — check the `qs ipc` docs)

### Verification

- [ ] Super+SPACE toggles sidebar in <100ms
- [ ] Volume slider change verified with `wpctl get-volume @DEFAULT_AUDIO_SINK@`
- [ ] Brightness slider change verified with `brightnessctl get`
- [ ] WiFi list shows real APs; click connects
- [ ] Bluetooth list shows paired devices; toggle connects
- [ ] Power profile change verified with `powerprofilesctl get`
- [ ] Calendar correctly shows current date

---

## Phase 14: Left Sidebar (productivity) ✓ DONE (2026-06-04)

> **Goal**: Build the greenfield productivity panel. Tabbed: Notes / Overview / Tasks / Scratchpads. Hotkey-toggled (Super+Shift+SPACE) slide-in panel from the left edge. All four tabs new QML code (no end-4 equivalents we're keeping).

### Container

- [ ] `Configs/.config/quickshell/doorwayde/sidebarLeft/SidebarLeft.qml` — tab container; persist last-active tab to `$XDG_STATE_HOME/doorwayde/sidebar.json`

### Notes tab

- [ ] `Notes.qml` — QML `TextEdit` with markdown preview pane (Qt RichText is sufficient; cmark-gfm subprocess only if RichText quality lacks)
- [ ] Persist to `$XDG_DATA_HOME/doorwayde/notes/scratchpad.md` (debounced 500ms save)
- [ ] "Save as…" button → `$XDG_DATA_HOME/doorwayde/notes/<timestamp>.md`

### Overview tab

- [ ] `Overview.qml` — possibly reuse end-4's `overview/` tree if it adapts cleanly (live window previews via Wayland screencopy + Hyprland IPC)
- [ ] Search bar filters by window title/class; Enter focuses the matching window via `hyprctl dispatch focuswindow address:0x...`

### Tasks tab

- [ ] `Tasks.qml` — todo list with text input + scrollable list of checkboxes
- [ ] Persist to `$XDG_DATA_HOME/doorwayde/tasks/tasks.json`
- [ ] Pomodoro: 25/5/15 timer; transition fires `notify-send` (or in-shell notification once Phase 15 lands)

### Scratchpads tab

- [ ] `Scratchpads.qml` — lists Hyprland `special:` workspace windows (`hyprctl clients -j` filtered)
- [ ] Row click → `hyprctl dispatch togglespecialworkspace <name>` to focus
- [ ] "Add focused window to scratchpad" button → `hyprctl dispatch movetoworkspacesilent special:<name>`

### Wiring

- [ ] Layer rule in `Configs/.config/hypr/windowrules.lua`:
  ```lua
  hl.layer_rule({ namespace = "^(quickshell:sidebarLeft)$", rules = {"blur"} })
  ```
- [ ] Keybind in `keybindings.lua`:
  ```lua
  hl.bind("SUPER SHIFT", "SPACE", hl.dsp.exec_cmd("qs-ipc doorwayde sidebarLeft.toggle"))
  ```
- [ ] Per-tab quick-jump binds (optional): `SUPER+N` notes, `SUPER+O` overview, `SUPER+CTRL+T` tasks

### Verification

- [ ] All four tabs render without QML errors
- [ ] Notes content survives a logout/login cycle (file written on close)
- [ ] Overview matches `hyprctl clients -j | jq '.[].title'`
- [ ] Pomodoro timer fires notification at 25-min mark
- [ ] Scratchpads list matches `hyprctl clients -j | jq '[.[] | select(.workspace.name | startswith("special:"))]'`

---

## Phase 15: OSD & Notification Daemon ✓ DONE (2026-06-04)

> **Goal**: Replace dunst with a QuickShell notification daemon. Add an OSD overlay for volume/brightness feedback. Surface notification history in the right sidebar widget from Phase 13.

- [ ] Fork end-4's `osd/` subtree for volume/brightness on-screen indicators
- [ ] Register a QuickShell `NotificationServer` on the session bus (`org.freedesktop.Notifications`)
- [ ] Wire notification history into the right sidebar's notification panel (Phase 13 placeholder)
- [ ] Disable `systemd.user.services.dunst` in flake.nix (keep `Configs/.config/dunst/` for rollback)
- [ ] Layer rules in `windowrules.lua`:
  ```lua
  hl.layer_rule({ namespace = "^(quickshell:osd)$", rules = {"blur"} })
  hl.layer_rule({ namespace = "^(quickshell:notification)$", rules = {"blur"} })
  ```
- [ ] Verify: `notify-send "test"` produces a QuickShell notification (not dunst), `notify-send -u critical "test"` is styled distinctly, volume keys produce OSD, brightness keys produce OSD
- [ ] Verify: notifications accumulate in the right sidebar history pane

---

## Phase 16: Polish & Decommission ✓ DONE (2026-06-04)

> **Goal**: Final cleanup after the new shell has soaked for ~1–2 weeks of daily-driver use. Delete the waybar / dunst / wlogout source trees. Final visual polish.

### Delete (after soak) — DONE

- [x] `Configs/.local/share/waybar/` (whole tree)
- [x] `Configs/.config/waybar/` (whole tree)
- [x] `Configs/.local/lib/doorwayde/waybar.py`
- [x] `Configs/.config/dunst/` (whole tree)
- [x] `Configs/.config/wlogout/` (whole tree)
- [x] `Configs/.local/lib/doorwayde/color/hypr.sh` (wallbash → Hyprland border colors — matugen owns this now)
- [x] Remove `systemd.user.services.doorwayde-waybar`, dunst, wlogout entries from `flake.nix`
- [x] Drop `pkgs.waybar`, `pkgs.wlogout` from `doorwaydeDeps` (dunst removed in Phase 15; waybar + wlogout removed in Phase 16)

### Polish — DEFERRED to Phase 17 soak window

- [ ] Slide-in animation curve tuning (Hyprland layer animation params)
- [ ] Final blur strength + rounding values across all `quickshell:*` layers
- [ ] Sidebar widget spacing audit — make the "minimal/readable" promise concrete

### Documentation — DONE

- [x] Update `CLAUDE.md` — "QuickShell shell architecture" section added (surface ownership, matugen flow, IPC workaround, runtime writes)
- [x] Update `README.md` — component table updated; waybar/dunst/wlogout removed; QuickShell/matugen described; keybindings updated; old HyDE screenshots replaced with placeholder
- [x] Mark Phases 10–16 done in this TODO.md
- [x] Add Phase 17 placeholder below

---

## Phase 17: Stretch Goals (post-soak)

> **Goal**: Enhancements after the Phase 16 shell has proven stable in daily-driver use. No timeline — add to this list as ideas crystallize.

### Visual polish (carried from Phase 16 deferred)

- [ ] Slide-in animation curve tuning — evaluate `Easing.BezierSpline` with `expressiveEffects` curve for sidebar slide vs. Hyprland layer animation override
- [ ] Final blur strength + rounding values per `quickshell:*` namespace — audit in motion vs. static screenshots
- [ ] Sidebar widget spacing audit — verify `minimal/readable` promise on a 1080p display

### Shell extensions

- [ ] QuickShell lockscreen — replace hyprlock with a QML lockscreen surface (`WlrLayershell.layer: WlrLayer.Overlay`, `WlrKeyboardFocus.Exclusive`); hyprlock config stays as fallback
- [ ] AI integration in left sidebar — deferred since Phase 14 planning; revisit once productivity tabs have had soak time
- [ ] Theme variant switcher — `matugen` owns the base palette; a secondary accent override (Tokyo Night / Catppuccin tones) could be applied as a CSS filter or color matrix on top without abandoning Material You structure

### Infrastructure

- [ ] GitHub Actions CI for `Hyprland --verify-config` (Phase 8 open item) — run on every PR touching `Configs/.config/hypr/` or `Configs/.local/share/hypr/`
- [ ] Wiki articles (Phase 8 open item): Architecture-Overview, Theming-and-Wallbash, Keybindings-Reference, Scripting-API, Lua-Migration-Notes

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

### 2026-06-04
- [x] **Hyprdots inspiration survey** — examined hydenix (Nix port), end-4/dots-hyprland (QuickShell gold standard), ArchEclipse, Caelestia, JaKooLit, Colorshell, sh1zicus, R7rainz. Identified three-zone layout + matugen color sync + QuickShell as the modern Hyprland convention. Full notes in `.claude/plans/https-github-com-richen604-hydenix-today-adaptive-turing.md`.
- [x] **Phase 8 recoded** — wallbash → Hyprland Lua port moved from "blocked on missing upstream API" to "superseded by Phase 11 matugen." Architecture no longer depends on `hl.source()`; QuickShell `FileView` will own color subscription.
- [x] **Initiative II added** — Phases 10–16 (DOORwayDE Shell & Visual Redesign) inserted between Phase 9's "Caveats / risk-control" and "Files to Keep as hyprlang." Design decisions: QuickShell (QML/Qt6) over AGS/eww; matugen Material You over wallbash port; AI tool deferred to Phase 17+; left sidebar = Notes / Overview / Tasks / Scratchpads; waybar replaced entirely; end-4's `ii` shell as fork target (GPLv3, attribution).
- [x] **Hydenix's `mutable.nix`** — flagged for adoption in Phase 11 as `lib.mkMutableHomeFile`; resolves the EROFS-on-runtime-writes class once for all future passes.

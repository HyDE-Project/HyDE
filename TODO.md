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
- [x] **Pass 2 — Waybar declarative service** — added `systemd.user.services.doorwayde-waybar` to flake.nix; `waybar.py --watch` repurposed as `ExecStartPre` (preps state-file / config.jsonc / position.json then exits); `waybar` itself runs as `ExecStart`. Removed `BAR` line from `variables.lua` and the `hl.exec_cmd(vars.start.BAR)` from `startup.lua`. `watch_waybar()` gutted to just `generate_includes()`. The double-wrap (`bar.scope` wrapping `bar.service`) is gone — there's now a single declarative `doorwayde-waybar.service`.
- [x] **Pass 3 — Low-risk daemons (5 services)** — text-clipboard, image-clipboard, network-manager-applet, removable-media-applet, bluetooth-applet all declarative via the new `mkDoorwaydeService` helper in `flake.nix`. waybar refactored to use the helper too (the entire "DOORwayDE service template" now lives in one place). Slice corrected from `app.slice` (launch-unit.sh default) to `app-graphical.slice` for all 5 (per the Pass 2 lesson — these are graphical-session-dependent).
- [x] **Pass 4 — Notifications + battery + wallpaper (3 services)** — `doorwayde-notifications` (dunst), `doorwayde-battery-notify` (batterynotify.sh), `doorwayde-wallpaper` (wallpaper.sh --start --global) all declarative via `mkDoorwaydeService`. battery-notify reclassified into `app-graphical.slice` (Pass 2/3 reflection was wrong to call it non-graphical — it routes through notify-send → dunst). dunst uses `${pkgs.dunst}/bin/dunst`; the two DOORwayDE scripts use `%h/.local/lib/doorwayde/*.sh` absolute paths.
- [x] **Pass 5 — Idle + blue-light (2 services)** — `doorwayde-idle` (hypridle), `doorwayde-blue-light-filter` (hyprsunset). Cleanest pass yet: no scripts, no PATH dependencies, vanilla daemons with `${pkgs.X}/bin/X` ExecStart. Both `app-graphical.slice` via `mkDoorwaydeService` defaults. **Latent bug flagged for Pass 6**: `startup.lua:30` references `unt` which is `local` in variables.lua (not exported), so the doorwayde-config service unit name has been `nil-doorwayde-config.service` at runtime. Pass 6's declarative-oneshot migration removes this line entirely.
- [x] **Pass 6 — Session-bootstrap units (declarative oneshots + polkit daemon)** — 3 new units: `doorwayde-xdg-portal-reset` (oneshot, restarts xdg-desktop-portal services via `systemctl --user restart`), `doorwayde-polkit-auth` (daemon, `${pkgs.polkit_gnome}/libexec/...`), `doorwayde-config-bootstrap` (oneshot, runs `doorwayde-config --no-startup`). New `mkDoorwaydeOneshot` helper sibling to `mkDoorwaydeService`. `polkit_gnome` added to `doorwaydeDeps`. Latent `unt`-undefined bug from Pass 5 deleted with its containing line. **gnome-keyring deferred** to a future cross-flake step (see end of Phase 9). **Env imports stay in startup.lua** because UWSM (which HALLway uses) also performs them — they're defensive duplication, scheduled for removal in Pass 6.5.
- [x] **Pass 6.5 — UWSM-redundancy cleanup (audit-driven removal pass)** — Explore-agent audit (2026-06-02) confirmed UWSM performs env-import before Hyprland starts. Four removals landed, all reversible: (1) deleted `doorwayde-xdg-portal-reset` oneshot from `flake.nix` — portals already start with correct env via `After=graphical-session.target` + `ConditionEnvironment=WAYLAND_DISPLAY`; (2) deleted `dbus-update-activation-environment --systemd --all` and `hl.exec_cmd(vars.start.SYSTEMD_SHARE_PICKER)` from `startup.lua`; (3) deleted `SYSTEMD_SHARE_PICKER` from `variables.lua`'s `start` table plus the now-unused `list_environment` local; (4) deleted the stale "Workaround for env-propagation race" comment in `flake.nix`. Bonus cleanup: deleted dead-code `local home = os.getenv("HOME")` in `startup.lua` (unused since Pass 6 removed its consumer).
- [ ] **Pass 7 — Delete `launch-unit.sh` and `app()` helper** — once all units are declarative, the wrapper has zero callers. Remove `Configs/.local/lib/doorwayde/launch-unit.sh`, the `app()` function, and the `start` table from `variables.lua`. Strip `startup.lua`'s `hl.on("hyprland.start", ...)` to just `hyprctl setcursor` (the IPC-dependent call that genuinely needs to run from Hyprland's lifecycle).
- [ ] **Pass 8 — waybar.py runtime writes audit + lift** — audit each runtime write (`config.jsonc`, `style.css`, `theme.css`, `global.css`, `user-style.css`, `staterc`). Categorize lift-able (Nix-eval-time) vs runtime (theme-state-derived). Result: waybar.py shrinks to theme-delta-only responsibilities.
- [ ] **Pass 9 — `doorwayde-shell` audit** — document current Nix-store-resolving wrapper shape; identify load-bearing vs vestigial HyDE inheritance. Mostly documentation pass.
- [ ] **Pass 10 — Final sweep** — update README + CLAUDE.md to reflect declarative model; remove vestigial HyDE references in docs; archive the Phase 9 entry.

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

### Pass 7+ deferred: gnome-keyring cross-flake migration

**Status**: DOORwayDE-side keyring launch is still imperative (variables.lua + startup.lua) because the declarative replacement requires a coordinated HALLway change.

**HALLway-side change needed** (add to HALLway's NixOS config):

```nix
{
  services.gnome.gnome-keyring.enable = true;
  # PAM auto-unlock through greetd (or whichever DM you use):
  security.pam.services.greetd.enableGnomeKeyring = true;
  # If using TUI login as well:
  security.pam.services.login.enableGnomeKeyring = true;
}
```

This enables the system-level gnome-keyring user service AND wires it into PAM so the keyring unlocks with your login password (functional improvement, not just a refactor — the current daemonized-launch pattern starts the keyring locked).

**Once HALLway has this**, DOORwayDE-side cleanup (fold into Pass 7 or later):
1. Remove `GNOME_KEYRING = ...` line from `variables.lua`
2. Remove `hl.exec_cmd(vars.start.GNOME_KEYRING)` from `startup.lua`
3. Optionally remove `gnome-keyring` from `doorwaydeDeps` (HALLway provides it system-level)

**Critical**: HALLway change must land FIRST. Otherwise there's a window where keyring isn't running.

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

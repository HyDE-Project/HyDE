# Troubleshooting Hyprland

When Hyprland loads the emergency fallback, refuses to start, or starts with weird minimal behavior, the symptom is rarely descriptive. This article walks you from "something's broken" to a root cause without guessing.

The single most important thing to internalize: **a lua parse error and a backend crash look identical from the outside, but the fixes live in completely different places.** Most of this page is about telling them apart fast.

---

## Quick reference

| Error pattern | Category | Fast fix |
|---|---|---|
| `unexpected symbol near 'repeat'` | Lua syntax | Rename to `repeating = true` (upstream renamed the field) |
| `attempt to call a nil value (field 'X')` | API mismatch | `hl.X` doesn't exist on this version; consult the [upstream lua example](https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.lua) |
| `... expects string, got table` | API mismatch | Convert table to expected string form (e.g. `opacity = "0.9 0.9 1.0"`) |
| `Unknown keysym: "X"` | Bind syntax | Use the xkb keysym name (e.g. `Control_R`, not `CTRL_R`) |
| `module 'X' not found` | require() | Check `package.path`; possibly `dofile(absolute_path)` |
| `CBackend::create() failed!` | **Backend** | NixOS/HALLway problem — not DOORwayDE; see [Backend errors](#backend--system-errors) below |

---

## Validation workflow

Hyprland ships with a parse-only mode that exits cleanly without touching the GPU or compositor backend. It is the **only** practical way to test changes on hosts where the compositor itself can't actually start (e.g. running under XFCE-on-X11, where Aquamarine — Hyprland's backend layer — has no X11 backend at all).

### Basic check (installed config)

```bash
Hyprland --verify-config
echo $?    # 0 = clean, 1 = errors
```

This reads `~/.config/hypr/hyprland.lua` and follows every `require()` and `dofile()` chain. The output looks like:

```
======== Config parsing result:

/path/to/keybindings.lua:42: hl.bind: failed to parse key string: Unknown keysym: "CTRL_R"
require("defaults"): /path/to/defaults.lua:95: attempt to call a nil value (field 'keyword')
```

Each line is independent — the parser keeps going after the first failure so you see every issue in one run.

### Checking unactivated repo changes (NixOS / Home Manager)

On NixOS, `~/.config/hypr/` and `~/.local/share/hypr/` are read-only nix-store symlinks. Editing files in the repo doesn't change what `--verify-config` sees until `home-manager switch` re-activates the profile. To verify changes *before* rebuilding, point Hyprland at the repo path and override `XDG_DATA_HOME` so `require()` resolves modules from your working tree:

```bash
XDG_DATA_HOME=$PWD/Configs/.local/share \
  Hyprland --verify-config -c $PWD/Configs/.config/hypr/hyprland.lua
echo $?
```

This works because DOORwayDE's orchestrator (at `Configs/.local/share/doorwayde/hyprland.lua`) does:

```lua
local xdg_data = os.getenv("XDG_DATA_HOME") or (home .. "/.local/share")
package.path = xdg_data .. "/hypr/?.lua;" .. package.path
```

So overriding `XDG_DATA_HOME` redirects every `require("defaults")`, `require("dynamic")`, etc. into your working tree.

---

## Error category 1: Lua syntax errors

These show up as `unexpected symbol near 'X'` or `'='/'/'<eof>' expected near 'X'`. They're typically table-key collisions with [Lua's reserved keywords](https://www.lua.org/manual/5.4/manual.html#3.1):

```
and       break     do        else      elseif    end       false
for       function  goto      if        in        local     nil
not       or        repeat    return    then      true      until     while
```

If you write `{ repeat = true }`, Lua sees the bare token `repeat` and tries to parse it as a `repeat ... until` loop. You can quote it: `{ ["repeat"] = true }` — but in Hyprland's case, the API was renamed to `repeating`, and the **correct** fix is to use the new field name. Same logic applies to any future field that collides.

### Real example: the `repeat = true` bug

`keybindings.lua` used to contain:

```lua
hl.bind(mainMod .. " + SHIFT + Right",
    hl.dsp.window.resize({ x = 30, y = 0 }),
    { description = "...", repeat = true })   -- ❌
```

…which produced `keybindings.lua:57: unexpected symbol near 'repeat'`. The fix:

```lua
    { description = "...", repeating = true })  -- ✅
```

### Gotcha: line numbers can be off by one

Lua reports the line where parsing *failed*, which is often one line after the actual mistake. If you see "unexpected `<eof>`" on the last line, look at the preceding lines for an unbalanced `{` or `end`.

---

## Error category 2: API-shape mismatches

These come in three flavors:

### 2a. Calling a nil value

```
attempt to call a nil value (field 'keyword')
attempt to call a nil value (field 'source')
```

Means the function doesn't exist on this Hyprland version. Lua doesn't have static types, so a typo or missing function won't be caught until runtime.

**Cross-reference the [upstream lua example](https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.lua)** — it's the authoritative API surface. If a call isn't documented there, it probably doesn't exist.

#### The wallbash gap

On Hyprland 0.55.1, **`hl.source` does not exist**. There is no equivalent in the lua API — none of `hl.source`, `hl.include`, `hl.load`, `hl.parse` are defined. The wallbash colour pipeline currently writes a hyprlang `colors.conf` file (`~/.config/hypr/themes/colors.conf`), and `Configs/.local/share/hypr/dynamic.lua` contains placeholder `try_source(...)` calls that are intentionally pcall-wrapped no-ops:

```lua
local function try_source(path)
    if hl.source then pcall(function() hl.source(path) end) end
end
```

Until the wallbash pipeline is refactored to emit `colors.lua` (a lua module returning a color table that `hl.config()` can consume), wallbash-driven dynamic theming is on pause. The groupbar therefore uses Hyprland defaults. See `TODO.md` for the tracking entry.

### 2b. Type errors

```
field 'opacity': expects string, got table
```

The lua API is fairly opinionated about field shapes. The cheat:

- **`opacity`** is a space-separated string: `"0.9 0.9 1.0"` (active inactive fullscreen), **not** a table.
- **`tag`** is a single string per call: `tag = "+name"`. If you want to set two tags, write two `hl.window_rule({...})` calls.
- **`hl.monitor`** wants `mode`, `position`, `scale` as separate string fields.

When in doubt: the upstream example shows the canonical shape for every field.

### 2c. Unknown keysym

```
hl.bind: failed to parse key string: Unknown keysym: "CTRL_R"
```

`hl.bind` splits the bind string on the **last** `+`, treating everything before as modifiers and the trailing token as the key. The trailing token must be a valid xkb keysym, **not** Hyprland's modifier shorthand:

| Wrong | Right | Reason |
|---|---|---|
| `"ALT_R + CTRL_R"` | `"ALT_R + Control_R"` | `Control_R` is the xkb keysym; `CTRL_R` is only valid as a *modifier* prefix |
| `"SUPER + Return"` | `"SUPER + Return"` | (already correct — `Return` is the xkb name for Enter) |

Run `xkbcli interactive-evdev` if you need to figure out the keysym name for a specific physical key.

---

## Error category 3: Module resolution

```
module 'env' not found:
    no field package.preload['env']
    no file './env.lua'
    ...
```

Lua's `require(name)` searches `package.path`. DOORwayDE's orchestrator (`Configs/.local/share/doorwayde/hyprland.lua` lines 11-18) prepends `$XDG_DATA_HOME/hypr/?.lua` so `require("env")` resolves to `~/.local/share/hypr/env.lua` (or the repo equivalent when `XDG_DATA_HOME` is overridden).

If `require()` fails:

1. Check that the file exists at the expected location.
2. Check the orchestrator's `package.path` setup hasn't drifted.
3. If you're loading a one-off path, use `dofile("/absolute/path.lua")` instead — it bypasses `package.path` entirely.

---

## Distinguishing config errors from backend errors

This decision tree is the most useful part of this page. Run through it before you spend hours debugging the wrong layer.

```
                 ┌────────────────────────────────────┐
                 │  Hyprland --verify-config exit 0?  │
                 └─────────────┬──────────────────────┘
                  yes ◀────────┴────────▶ no
                   │                       │
                   ▼                       ▼
   ┌────────────────────────┐    ┌────────────────────────────┐
   │  start-hyprland still  │    │ Lua / API error.           │
   │  crashes?              │    │ Fix the config; ignore     │
   └──────────┬─────────────┘    │ any crash logs from the    │
              │                  │ compositor — Hyprland      │
       yes◀───┴───▶ no           │ never reached the backend. │
        │           │            └────────────────────────────┘
        ▼           ▼
  Backend /     Hyprland actually started.
  seat issue.   If you got the emergency-fallback
  See below.    banner anyway, run
                `hyprctl configerrors` inside
                the session to see the
                latest parse state.
```

---

## Backend / system errors

If `--verify-config` is clean but `start-hyprland` still dies, the failure is below DOORwayDE's layer. The characteristic signature:

```
[ERR] Aquamarine: Couldn't open device at /dev/dri/card1: Permission denied
[ERR] CBackend::create() failed!
[FATAL] Hyprland was not able to start. (couldn't create a backend)
```

This means Aquamarine (Hyprland's backend abstraction) tried in order:

1. **DRM** — failed because `libseat` couldn't grab the GPU seat (often: Xorg already owns it, or `seatd` isn't running, or your session doesn't have the right PAM session module loaded).
2. **Wayland** — failed because there's no parent Wayland compositor to nest under.
3. **X11** — **does not exist in Aquamarine.** Hyprland 0.55+ dropped nested-X11 entirely. If you read older HyDE docs about running Hyprland inside Xephyr or as an X11 window, those instructions no longer work on this version.

### Diagnosis commands

```bash
journalctl -u greetd --since today        # display-manager / session log
ls /dev/dri/                              # list GPU device nodes
loginctl list-sessions                    # find your active session
loginctl show-session <id> -p Type        # x11 / wayland / tty
pgrep -a Xorg                             # is X11 holding the GPU seat?
systemctl status seatd                    # seatd running?
```

### **These are not DOORwayDE bugs.**

`libseat`, `seatd`, PAM session modules, GPU seat ownership, and which display-manager owns the login flow are all NixOS / HALLway concerns. DOORwayDE is a payload of dotfiles and scripts — it has zero influence over `/dev/dri` permissions or the seat-control daemon. Filing these issues against this repo wastes everyone's time. File them against HALLway (the NixOS flake) or the upstream component (`seatd`, `greetd`, etc.).

---

## Log locations

| File | What it captures |
|---|---|
| `~/.cache/hyprland/hyprlandCrashReport*.txt` | Backend crashes, one file per crash, sorted by mtime |
| `/tmp/hypr/<HYPRLAND_INSTANCE_SIGNATURE>/hyprland.log` | Per-session runtime log (only exists while a session is running) |
| `journalctl -u greetd` | Display-manager / session-manager output |
| `journalctl --user -t Hyprland` | Hyprland's user-journal output |
| `hyprctl configerrors` | Only inside a running session — shows the current config's parse errors |

Crashes from emergency-fallback runs are useful because the fallback config does load, so `/tmp/hypr/...` exists. Inspect it for the line range where the parser bailed.

---

## Worked example: chasing an emergency fallback

This actually happened during the lua migration. Annotated walkthrough:

1. **Symptom.** Logging in via greetd, DOORwayDE shows the bright-yellow "EMERGENCY FALLBACK CONFIG ACTIVE" banner instead of the usual desktop.

2. **First instinct: backend?** Ran `journalctl -u greetd --since "2 minutes ago"` — no `CBackend::create()` lines, no libseat errors. Backend was fine.

3. **Therefore: parse error.** Ran `Hyprland --verify-config`. Output:

   ```
   /home/user/.config/hypr/keybindings.lua:57: unexpected symbol near 'repeat'
   ```

4. **Identified the cause.** Line 57 was `{ description = "...", repeat = true }`. `repeat` is a Lua reserved keyword.

5. **Fix.** Renamed to `repeating = true` (the actual upstream API field name; the rename happened in a Hyprland release that overlapped our migration). Re-ran `--verify-config` — exit 0.

6. **Activation.** On NixOS, this required `home-manager switch` for the working-tree change to reach `~/.config/hypr/`. Without that, the next login still loads the stale config from the previous generation.

Total time from symptom to root cause: about 90 seconds, mostly thanks to `--verify-config`. Without it, this would have meant tail-ing crash logs and bisecting binds by hand.

---

## When to file what against where

| Symptom | File against |
|---|---|
| Wrong keybind, wrong window rule, broken theme, wrong rofi launcher | DOORwayDE |
| `CBackend::create() failed!`, libseat errors, regreet "XFCE (Wayland)" missing | HALLway |
| Hyprland crashes mid-session with a stack trace including `hyprland::CCompositor` | hyprwm/Hyprland upstream |
| `seatd` socket missing, `/dev/dri/cardN` permissions | NixOS module / `seatd` upstream |
| `greetd` fails to start a session | HALLway (greetd is configured at the NixOS module layer) |

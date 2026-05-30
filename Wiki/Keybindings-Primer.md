# Keybindings Primer

This article is a curated, by-use-case tour of DOORwayDE's keyboard shortcuts. The goal is *learning* — the binds most users press most often, grouped so you can build muscle memory. If you want an exhaustive auto-generated index of every single binding (including the obscure ones), watch for the planned `Keybindings-Reference.md`; for now, the source of truth is `Configs/.config/hypr/keybindings.lua`.

For everything *visible* you'd want to interact with (panels, menus, the waybar, dunst, theme switching), see [Interface-Tour.md](Interface-Tour.md). The two articles complement each other.

---

## Reading the notation

DOORwayDE uses the standard modifier vocabulary:

| Token | What it means |
|---|---|
| `SUPER` | The Windows / Command / Meta key — this is the **primary modifier**, used for almost everything |
| `SHIFT` | Shift |
| `CTRL` | Control |
| `ALT` | Alt / Option |
| `ALT_R`, `Control_R` | Right Alt, Right Control — distinguished from their left-side counterparts for the waybar toggle |

A binding like `SUPER + SHIFT + Q` means "hold SUPER and SHIFT, then press Q." Modifiers go in any order; the trailing key is the actual action key.

**Note on the live keybinds:** if you forget any of these, press `SUPER + /` at any time to open a searchable rofi-driven keybindings hint — that menu reflects the current config exactly, so it won't drift if you customize the bindings.

---

## The essentials

If you only learn ten bindings, learn these. They cover ~80% of daily desktop use:

| Key | Action |
|---|---|
| `SUPER + T` | Open terminal (Kitty) |
| `SUPER + A` | Application launcher (rofi) |
| `SUPER + Tab` | Window switcher (rofi) |
| `SUPER + Q` | Close focused window |
| `SUPER + W` | Toggle floating mode on the focused window |
| `SUPER + 1`..`SUPER + 0` | Switch to workspace 1–10 |
| `SUPER + ←/→/↑/↓` | Focus the window in that direction |
| `SUPER + L` | Lock the screen |
| `SUPER + /` | Show the searchable keybindings menu (use this whenever you forget anything) |
| `CTRL + ALT + Delete` | Open the logout menu |

If you internalize just `SUPER + T`, `SUPER + A`, `SUPER + Q`, and `SUPER + /`, you can navigate by discovery — `SUPER + /` lists every other binding, searchable.

---

## Window management

### Focus and movement

| Key | Action |
|---|---|
| `SUPER + ←/→/↑/↓` | Move keyboard focus to the window in that direction |
| `ALT + Tab` | Cycle keyboard focus to the next window (and raise it) |
| `SUPER + CTRL + H` / `SUPER + CTRL + L` | Cycle backwards / forwards through the active window group |

### Resize, move, layout

| Key | Action |
|---|---|
| `SUPER + SHIFT + ←/→/↑/↓` | Resize the focused window by 30px in that direction (repeats while held) |
| `SUPER + SHIFT + CTRL + ←/→/↑/↓` | Move the focused window across the workspace by 30px (or to the adjacent tile if it's tiled; repeats while held) |
| `SUPER + J` | Toggle the split direction of the current tile |
| `SHIFT + F11` | Toggle fullscreen on the focused window |
| `SUPER + W` | Toggle floating mode |
| `SUPER + SHIFT + F` | Toggle "pin" (window stays visible across workspace switches) |
| `SUPER + G` | Toggle grouping (tabs the windows together so they share a tile) |

### Close, kill, reload

| Key | Action |
|---|---|
| `SUPER + Q` | Close the focused window (sends `killactive`) |
| `ALT + F4` | Same as `SUPER + Q` — close the focused window |
| `SUPER + F5` | Reload the Hyprland config (picks up changes to `~/.config/hypr/*.lua` without logout) |
| `SUPER + Delete` | Kill the entire Hyprland session (drops you back to your display manager) |

### Mouse-modifier window manipulation

These let you drag and resize windows with the mouse while holding a modifier — useful for floating windows or for quick adjustments:

| Hold + drag | Action |
|---|---|
| `SUPER + Left mouse` (or `SUPER + Z`) | Drag-move the window under the cursor |
| `SUPER + Right mouse` (or `SUPER + X`) | Drag-resize the window under the cursor |

---

## Workspaces

DOORwayDE supports 10 numbered workspaces plus one special "scratchpad."

### Navigation

| Key | Action |
|---|---|
| `SUPER + 1`..`9` | Switch to workspace N |
| `SUPER + 0` | Switch to workspace 10 |
| `SUPER + CTRL + →` / `SUPER + CTRL + ←` | Switch to the next / previous workspace relative to the current one |
| `SUPER + CTRL + ↓` | Jump to the nearest empty workspace |
| `SUPER + mouse scroll up/down` | Cycle workspaces with the scroll wheel |

### Moving windows to workspaces

| Key | Action |
|---|---|
| `SUPER + SHIFT + 1`..`9` | Move the focused window to workspace N (and follow it) |
| `SUPER + SHIFT + 0` | Move the focused window to workspace 10 |
| `SUPER + ALT + 1`..`0` | Move the focused window to workspace N **silently** (stay on the current workspace) |
| `SUPER + CTRL + ALT + →` / `SUPER + CTRL + ALT + ←` | Move the focused window to the next / previous relative workspace |

### Scratchpad

The scratchpad is a special workspace you can toggle in and out of view — useful for tucking away a terminal, music player, or notes window:

| Key | Action |
|---|---|
| `SUPER + S` | Toggle the scratchpad on/off |
| `SUPER + SHIFT + S` | Move the focused window into the scratchpad |
| `SUPER + ALT + S` | Move the focused window into the scratchpad silently (without switching to it) |

---

## Launchers and apps

### Direct app launches

These open specific apps directly, bypassing the launcher menu:

| Key | App | Notes |
|---|---|---|
| `SUPER + T` | Terminal (Kitty) | Honors `$TERMINAL` if set; falls back to kitty |
| `SUPER + ALT + T` | Dropdown terminal (pypr) | Quake-style drop-down |
| `SUPER + E` | File manager (Dolphin) | Honors `$EXPLORER` |
| `SUPER + C` | Text editor (VS Code) | Honors `$EDITOR`; falls back to `code` |
| `SUPER + B` | Web browser (Firefox) | Honors `$BROWSER` |
| `CTRL + SHIFT + Escape` | System monitor | Doorwayde's wrapper picks an installed monitor (Mission Center, htop, etc.) |

### Rofi menus

Each of these opens a rofi-driven menu. **Pressing the same keybind a second time closes an open rofi instance** (every rofi launcher is `pkill -x rofi || …`):

| Key | Menu |
|---|---|
| `SUPER + A` | Application launcher (search + launch desktop entries) |
| `SUPER + Tab` | Window switcher (jump to any open window) |
| `SUPER + SHIFT + E` | File finder |
| `SUPER + /` | Keybindings hint (searchable, auto-generated from `keybindings.lua` descriptions) |
| `SUPER + ,` | Emoji picker |
| `SUPER + .` | Glyph picker (Unicode symbols) |
| `SUPER + V` | Clipboard (quick pick — last N entries) |
| `SUPER + SHIFT + V` | Clipboard manager (full history, with delete/pin) |
| `SUPER + SHIFT + A` | Rofi launcher style selector (switch which rofi theme drives `SUPER + A`) |

---

## Screenshots and color picker

DOORwayDE uses `grim` + `slurp` for capture and `satty` for annotation. The screenshot pipeline is in `screenshot.sh`.

| Key | Action |
|---|---|
| `SUPER + P` | Screenshot a region (slurp selection) and copy + save |
| `SUPER + CTRL + P` | Freeze the screen and then snip a region (lets you capture menus that would normally close) |
| `SUPER + ALT + P` | Screenshot the active monitor only |
| `Print` | Screenshot all monitors |
| `SUPER + SHIFT + P` | Color picker (`hyprpicker -an`) — pick a pixel color, copies hex to clipboard |

Output paths: by default `~/Pictures/Screenshots/`. See `screenshot.sh` if you want to change the destination.

---

## Audio, media, and brightness

### Volume

| Key | Action |
|---|---|
| `F12` / `XF86AudioRaiseVolume` | Volume up (repeats while held) |
| `F11` / `XF86AudioLowerVolume` | Volume down (repeats while held) |
| `F10` / `XF86AudioMute` | Toggle output mute |
| `XF86AudioMicMute` | Toggle microphone mute |
| `SUPER + CTRL + M` | Mute / unmute the focused window only (per-app via PipeWire) |

### Media playback

These work with anything that exposes MPRIS (Spotify, mpv, Firefox, browser-based players):

| Key | Action |
|---|---|
| `XF86AudioPlay` / `XF86AudioPause` | Play / pause |
| `XF86AudioNext` | Next track |
| `XF86AudioPrev` | Previous track |

### Brightness

| Key | Action |
|---|---|
| `XF86MonBrightnessUp` | Increase screen brightness (repeats while held) |
| `XF86MonBrightnessDown` | Decrease screen brightness (repeats while held) |

The volume / brightness keys are bound with `locked = true`, which means they keep working while the screen is locked (so you can adjust audio without unlocking).

---

## Theme, wallpaper, and appearance

The whole appearance customization surface is keyboard-driven through rofi menus:

| Key | Menu |
|---|---|
| `SUPER + SHIFT + T` | Theme selector (palette + wallpaper set + bar style + cursor) |
| `SUPER + SHIFT + W` | Wallpaper selector (pick from the active theme's wallpaper set) |
| `SUPER + ALT + →` | Next wallpaper (cycle within the current theme) |
| `SUPER + ALT + ←` | Previous wallpaper |
| `SUPER + ALT + ↑` | Next waybar layout |
| `SUPER + ALT + ↓` | Previous waybar layout |
| `SUPER + SHIFT + R` | Wallbash mode selector (which color extraction algorithm to use; subject to the wallbash-lua gap, see [Interface-Tour § What doesn't work today](Interface-Tour.md#what-doesnt-work-today-wallbash-dynamic-recoloring)) |
| `SUPER + SHIFT + Y` | Animation preset selector |
| `SUPER + SHIFT + U` | Hyprlock layout selector |

---

## Utilities

### Game mode

DOORwayDE has a "game mode" that disables animations and certain compositor effects for lower-latency play:

| Key | Action |
|---|---|
| `SUPER + ALT + G` | Toggle game mode |
| `SUPER + SHIFT + G` | Open game launcher |

### Keyboard layout

If you have multiple keyboard layouts configured:

| Key | Action |
|---|---|
| `SUPER + K` | Cycle to the next layout |

---

## System

### Waybar control

| Key | Action |
|---|---|
| `ALT_R + Control_R` (right Alt + right Ctrl) | Toggle waybar visibility |

### Session control

| Key | Action |
|---|---|
| `SUPER + L` | Lock the screen (hyprlock) |
| `CTRL + ALT + Delete` | Open the logout menu (wlogout) |
| `SUPER + Delete` | Kill the Hyprland session immediately |
| `SUPER + F5` | Live-reload the Hyprland config |

---

## Mouse-only bindings

For completeness — bindings that are mouse-driven rather than keyboard-driven:

| Hold + click/drag | Action |
|---|---|
| `SUPER + Left mouse` | Drag the window under the cursor |
| `SUPER + Right mouse` | Resize the window under the cursor |
| `SUPER + mouse scroll wheel up` | Cycle to next workspace |
| `SUPER + mouse scroll wheel down` | Cycle to previous workspace |

---

## Where this list comes from

Every binding above lives in `Configs/.config/hypr/keybindings.lua`. The keybinds are written using the `hl.bind(key, dispatcher, opts)` API; opts include a `description` field that follows the `[Group|Subgroup] description` format. That format isn't decorative — it's structured input for `keybinds/hint-hyprland.py`, which is what powers the `SUPER + /` rofi keybindings menu. If you customize bindings and want them to appear in the hint menu, follow the same `[Group|Subgroup] description` convention.

Bindings not listed here (because they're rarely-pressed or are duplicate hardware keys):

- The numeric `XF86Audio*` and `XF86MonBrightness*` versions are listed under media/brightness, but DOORwayDE also binds `F10`/`F11`/`F12` to the same actions for laptops whose function-key row is the audio control.
- `mouse:272` and `mouse:273` are the raw button codes for left/right mouse, bound alongside `SUPER + Z` / `SUPER + X` for keyboard-only redundancy.

The complete authoritative list is always `keybindings.lua` itself — under 250 lines, all grouped and commented.

---

## What to read next

- **You want to see the bindings in their visual UI context** → [Interface-Tour.md](Interface-Tour.md)
- **A binding doesn't seem to work** → [Troubleshooting-Hyprland.md](Troubleshooting-Hyprland.md) (binds with nil dispatchers or unknown keysyms surface in `Hyprland --verify-config` output)
- **You want to add a new binding** → edit `Configs/.config/hypr/keybindings.lua` in the repo, then rebuild. See [Using-DOORwayDE-with-Nix.md § Editing DOORwayDE](Using-DOORwayDE-with-Nix.md#editing-doorwayde) for why you can't edit the deployed copy directly.

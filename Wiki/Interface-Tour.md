# Interface Tour

You just logged into DOORwayDE for the first time. This article tells you what you're looking at, what's clickable, and how to find every menu and panel without having to memorize keybindings yet.

For the *keyboard* side of the interface (which keys do what), see [Keybindings-Primer.md](Keybindings-Primer.md). The two articles are designed to be read together.

---

## What you see on first login

A wallpaper, a thin status bar at the top of the screen, and a cursor. Nothing else.

That's deliberate — Hyprland is a tiling window manager, not a launcher-on-the-desktop environment. There's no "Start" button to click in the conventional sense; the entire interaction model is "press a key to open something." The status bar is the only persistent visible UI element.

What happened invisibly during the second or two between login and your desktop appearing, in this order (defined in `Configs/.local/share/hypr/startup.lua`):

1. **D-Bus + portals** got the right environment exported so XDG portals (file pickers, screen capture permissions) work.
2. **Polkit auth dialog** started, so graphical password prompts can appear when you `sudo` or unlock secrets.
3. **gnome-keyring** started as your Secret Service backend (Firefox, VSCodium, etc. store passwords here).
4. **Waybar** launched (you see it at the top).
5. **Dunst** launched (notifications now work).
6. **Wallpaper** loaded (you see it).
7. **Clipboard daemons** started recording text and image clipboard history.
8. **System tray applets** appeared in the bar: NetworkManager, removable-media, Bluetooth, battery.
9. **Hypridle** started watching for idle (will lock the screen after the configured timeout).
10. **Hyprsunset** started — blue-light filter (optional; can be toggled off).
11. **Cursor theme** was applied (Bibata Modern Ice, 24px).

If any of these is missing — no bar, no wallpaper, no tray — that's not a configuration question, that's a debug question. Go to [Troubleshooting-Hyprland.md](Troubleshooting-Hyprland.md).

---

## The waybar (top panel)

Waybar is the bar at the top. DOORwayDE ships with **17 different layouts** out of the box (in `~/.local/share/waybar/layouts/hyprdots/`) — plus alternative layout sets (`khing.jsonc`, `macos.jsonc`). What you see right now is whichever layout was active in the last session.

### How to think about it

Three regions, left to right:

- **Left** — workspace indicator and active window/taskbar
- **Center** — clock, sometimes keyboard layout, sometimes status indicators
- **Right** — system tray, audio/network/Bluetooth, battery, notifications, DOORwayDE menu

The exact module set depends on the layout. Some are minimal (clock + tray); some are loaded (CPU/GPU/temperature/network bytes/cava audio visualizer). All are templated from JSONC files under `~/.local/share/waybar/modules/` — over 40 module definitions exist, including custom ones (`custom-doorwayde-menu`, `custom-cava`, `custom-cpuinfo`, `custom-gpuinfo` with brand-specific variants, `custom-gamemode`, `custom-clipboard`, etc.).

### Switching layouts

| Action | How |
|---|---|
| Cycle to next layout | `SUPER + ALT + ↑` |
| Cycle to previous layout | `SUPER + ALT + ↓` |
| Hide / show waybar (toggle) | `RightAlt + RightCtrl` |

This works at runtime because `waybar.py` *generates* `~/.config/waybar/{config.jsonc, style.css, includes/}` on the fly from the templates — your `~/.config/waybar/` is session state, not Nix-managed config. See [Introduction § The bar is its own thing](Introduction.md#3-the-bar-is-its-own-thing-owned-by-waybarpy) for why this is set up the way it is.

### Clicking things in the bar

Most modules respond to mouse interaction:

| Module | Left click | Right click | Other |
|---|---|---|---|
| Clock | Open calendar popup | (varies by layout) | — |
| Audio | Toggle mute output | Open `pavucontrol` if available | Scroll: change volume |
| Microphone | Toggle mic mute | — | — |
| Network | Open `nm-applet` connection editor | — | — |
| Bluetooth | Open Bluetooth applet | — | — |
| Battery | Open power profile menu | — | — |
| Notifications | Open notification history (dunstctl) | Clear all | — |
| **DOORwayDE menu** (rightmost) | Open DOORwayDE control menu | — | — |

If your layout has a CPU/GPU/temp module and you click it, you'll typically get a rofi popup with a process list. If it has cava (audio visualizer), it's purely visual — no click action.

The "DOORwayDE menu" button on the far right is the closest thing to a Start menu: it opens a rofi pane with shortcuts to common settings (theme, wallpaper, waybar layout, animations, etc.) for users who haven't memorized the keybindings yet.

---

## Rofi menus

Rofi is the universal menu primitive. DOORwayDE has a *lot* of rofi menus — each one is opened by a keybinding, and most can also be reached through the DOORwayDE menu button on the waybar.

### Inventory

| Menu | Keybind | What it does |
|---|---|---|
| **Application launcher** | `SUPER + A` | Search + launch installed `.desktop` apps |
| **Window switcher** | `SUPER + Tab` | Jump to any open window across all workspaces |
| **File finder** | `SUPER + SHIFT + E` | Search + open files (uses `fd`/`fzf`-style fuzzy match) |
| **Keybindings hint** | `SUPER + /` | Searchable, scrollable index of every keybinding (generated from `keybindings.lua` descriptions) |
| **Emoji picker** | `SUPER + ,` | Search emojis, paste on selection |
| **Glyph picker** | `SUPER + .` | Search Unicode glyphs (arrows, symbols, etc.) |
| **Clipboard (quick)** | `SUPER + V` | Pick from recent clipboard entries |
| **Clipboard manager** | `SUPER + SHIFT + V` | Full clipboard history with delete + pin options |
| **Rofi launcher selector** | `SUPER + SHIFT + A` | Switch between rofi launcher styles |
| **Theme selector** | `SUPER + SHIFT + T` | Switch the active theme |
| **Wallpaper selector** | `SUPER + SHIFT + W` | Pick a wallpaper from the theme's set |
| **Wallbash mode** | `SUPER + SHIFT + R` | Toggle/select wallbash color extraction mode |
| **Animations** | `SUPER + SHIFT + Y` | Pick from animation presets |
| **Hyprlock layout** | `SUPER + SHIFT + U` | Pick which lockscreen layout to use |

### Conventions across all rofi menus

- **Type to filter** — fuzzy match
- **Enter** — accept the selected item
- **Escape** — close without selecting
- **Mouse click** — also works for selection
- **Alt + 1..9** — jump to the Nth result

### Killing a stuck rofi

Every rofi-launching keybind in DOORwayDE is wrapped as `pkill -x rofi || <launch>`, which means pressing the same keybind a second time *closes* an already-open rofi instance instead of erroring. So if a menu seems unresponsive, press the keybind again to dismiss it.

---

## Notifications (dunst)

Notifications appear in the top-right corner. DOORwayDE's dunst is configured with a 300px notification width and follow-mouse behavior (notifications appear on the monitor with your cursor).

### Click semantics

| Click | Action |
|---|---|
| **Left** | Open the notification (executes its default action, or closes if no action) |
| **Middle** | Trigger the notification's default action explicitly |
| **Right** | Dismiss the notification |
| **Right (on stack)** | Dismiss *all* notifications |

### Urgency tiers

Dunst groups notifications by urgency:

- **Low** — short timeout, less visually prominent
- **Normal** — default
- **Critical** — sticky (no auto-dismiss), more prominent styling

Apps choose their own urgency. DOORwayDE's volume / brightness / lock-imminent notifications use normal urgency; battery-critical and security-relevant ones use critical.

### History

`SUPER + Shift + N` (if your active waybar layout exposes the indicator) or clicking the notification icon on the bar opens the dunst history pane — a list of dismissed notifications you can re-read.

---

## The logout menu (wlogout)

Press `CTRL + ALT + Delete` (or `SUPER + Delete` — both work).

A full-screen visual menu of six tiles appears:

| Tile | Action | Keyboard letter |
|---|---|---|
| **Lock** | Lock the screen via hyprlock | `L` |
| **Logout** | End the Hyprland session | `E` |
| **Suspend** | Suspend to RAM | `U` |
| **Shutdown** | Power off | `S` |
| **Hibernate** | Suspend to disk | `H` |
| **Reboot** | Restart | `R` |

Click a tile or press its underlined letter. Press `Escape` to cancel.

---

## Theme switching

This is the part of the interface most users want to play with first. Here's what works today and what doesn't, plainly.

### What works

| Action | How |
|---|---|
| Switch the active theme (palette + wallpaper + bar style + cursor) | `SUPER + SHIFT + T`, pick from the rofi list |
| Switch wallpaper within the current theme | `SUPER + SHIFT + W` |
| Cycle wallpapers forward / backward | `SUPER + ALT + →` / `SUPER + ALT + ←` |
| Cycle waybar layouts forward / backward | `SUPER + ALT + ↑` / `SUPER + ALT + ↓` |
| Pick an animation preset | `SUPER + SHIFT + Y` |
| Pick a hyprlock layout | `SUPER + SHIFT + U` |

Themes ship in the form of palette files, wallpaper sets, GTK/icon theme settings, and waybar styles. DOORwayDE comes with a handful of themes pre-installed (Catppuccin variants, Decay-Green, Tokyo-Night, Gruvbox-Retro, Rosé-Pine, Nordic-Blue, Synth-Wave) and is compatible with anything from [HyDE-Project/hyde-themes](https://github.com/HyDE-Project/hyde-themes).

### What doesn't work today: wallbash dynamic recoloring

Wallbash is HyDE's "extract palette from current wallpaper → recolor everything live" pipeline. On DOORwayDE today, **the Hyprland side of wallbash is on pause.**

Why: Hyprland 0.55.1's lua config API doesn't expose `hl.source()`, `hl.include()`, or any equivalent function for sourcing external config files at runtime. The wallbash pipeline writes a hyprlang-format `colors.conf`, which lua-based DOORwayDE has no way to consume. The placeholder `try_source(...)` calls in `Configs/.local/share/hypr/dynamic.lua` are intentionally pcall-wrapped no-ops, waiting for the wallbash pipeline to be refactored to emit `colors.lua` (a lua module returning a color table).

What this means in practice: the **rofi/waybar/dunst** sides of wallbash still recolor when you switch themes (those tools read static colors from the theme files directly), but **the groupbar, window borders, and other Hyprland-rendered chrome** use the Hyprland defaults until wallbash-lua lands.

If full dynamic recoloring is essential to you today, this is the one piece of DOORwayDE that isn't at parity with upstream HyDE. Track progress in `TODO.md`.

---

## Where state lives

When you take a screenshot, swap themes, or generate a clipboard entry — where does it end up? Quick reference:

| What | Where |
|---|---|
| **Screenshots** | `~/Pictures/Screenshots/` (by default; `screenshot.sh` is the source of truth) |
| **Wallpapers (current)** | `$XDG_CACHE_HOME/doorwayde/wallpaper.set` (the symlink the wallpaper daemon reads) |
| **Wallpaper sources** | Theme-specific directories under `$XDG_DATA_HOME/doorwayde/themes/<Theme-Name>/wallpapers/` |
| **Active theme name** | `$XDG_STATE_HOME/doorwayde/staterc` |
| **Active waybar layout** | `$XDG_STATE_HOME/doorwayde/staterc` (key controlled by `wbarconfgen`) |
| **Live waybar config** | `~/.config/waybar/{config.jsonc, style.css}` (session state, written by `waybar.py`) |
| **Clipboard history** | `~/.cache/cliphist/db` (cliphist's own database) |
| **Recent dunst notifications** | In-memory, not persisted |
| **Hyprland session log (live)** | `/run/user/$(id -u)/hypr/<INSTANCE_SIG>/hyprland.log` |
| **Hyprland crash reports** | `~/.cache/hyprland/hyprlandCrashReport*.txt` |
| **Wallbash cache** | `$XDG_CACHE_HOME/doorwayde/wallbash/` |

`XDG_CACHE_HOME` is `~/.cache`, `XDG_DATA_HOME` is `~/.local/share`, `XDG_STATE_HOME` is `~/.local/state` (DOORwayDE exports all of these via `env.lua`).

If a script seems to have lost your state, check `$XDG_STATE_HOME/doorwayde/` — `staterc` is the closest thing DOORwayDE has to a session-state registry.

---

## What to read next

- **You want to memorize the keyboard shortcuts** → [Keybindings-Primer.md](Keybindings-Primer.md)
- **A panel didn't appear or a menu isn't working** → [Troubleshooting-Hyprland.md](Troubleshooting-Hyprland.md)
- **You want to customize what's in the waybar or add a new module** → the layout/module templates live in `Configs/.local/share/waybar/`; editing-and-rebuilding is the workflow (see [Using-DOORwayDE-with-Nix.md § Editing DOORwayDE](Using-DOORwayDE-with-Nix.md#editing-doorwayde))
- **You want to write a new rofi menu or doorwayde-shell subcommand** → the script library is in `Configs/.local/lib/doorwayde/`; the planned `Scripting-API.md` article will document the conventions

# Introduction to DOORwayDE

DOORwayDE is a complete Hyprland desktop environment, packaged as a Home Manager module for NixOS. You install it the way you install any other flake input — `inputs.doorwayde.url = "github:MarkusBitterman/DOORwayDE";`, set `doorwayde.enable = true;` — and on the next rebuild you have an animated tiling Wayland desktop with a status bar, launcher, lock screen, notifications, and a theme switcher, all configured to talk to each other.

This article exists so you can decide whether DOORwayDE is the desktop you want before you spend any time installing it. It is opinionated about what it does and doesn't try to be.

---

## What you actually get

A working session, not a parts list. After enabling the module and rebuilding, logging into the Hyprland session gives you all of this at once:

| Layer | Component | What it does for you |
|---|---|---|
| Compositor | **Hyprland** (lua-config era, 0.55+) | Animated tiling Wayland compositor with workspaces, scratchpad, groups |
| Status bar | **Waybar** | Top-of-screen bar with workspace indicator, clock, network/audio/battery, tray, custom DOORwayDE menu |
| Launcher | **Rofi** | App launcher, window switcher, file finder, emoji/glyph pickers, clipboard history, theme selector |
| Notifications | **Dunst** | Top-right popups with action support |
| Lock | **Hyprlock** + **Hypridle** | Idle-triggered screen lock with customizable layouts |
| Logout | **Wlogout** | Visual logout/shutdown/reboot/suspend tile menu |
| Wallpaper | **Hyprpaper** + `wallpaper.sh` | Wallpaper rotation tied to themes |
| Terminal | **Kitty** | Default terminal with GPU acceleration |
| Screenshots | **grim** + **slurp** + **satty** | Region/window/full capture, freeze-and-shoot, annotation |
| Clipboard | **cliphist** + **wl-paste** | Persistent clipboard history with rofi UI |
| Color | **hyprpicker** | Pixel color picker |
| Display tone | **hyprsunset** | Optional blue-light filter |
| Auth UI | **polkit-kde-agent** | Graphical password prompts for sudo/admin actions |
| Secrets | **gnome-keyring** | Secret Service API for VSCodium, Firefox, etc. |

Plus the DOORwayDE-specific layer:

| Tool | Purpose |
|---|---|
| `doorwayde-shell` | Front-end script that dispatches to every utility in `~/.local/lib/doorwayde/` (themes, screenshots, wallpapers, brightness, volume, gamemode, etc.) |
| `doorwaydectl` | IPC control utility for interacting with the running session |
| `doorwayde-ipc` | Direct IPC communication primitive |
| ~80 scripts in `~/.local/lib/doorwayde/` | The actual work — `wallpaper.sh`, `theme.switch.sh`, `screenshot.sh`, `volumecontrol.sh`, etc. |

You don't have to glue these together yourself. The keybindings in `Configs/.config/hypr/keybindings.lua` already call them, the waybar already shows their output, and the rofi menus are already styled.

---

## Who this is for

- **NixOS users who want a curated Hyprland setup** without assembling one from a dozen separate dotfiles repos. You add one flake input and you're done.
- **Users of [HALLway OS](https://github.com/MarkusBitterman/HALLway)**, which consumes DOORwayDE as its desktop layer. If you're on HALLway, you already have this — see [Using-DOORwayDE-with-Nix.md](Using-DOORwayDE-with-Nix.md) for the integration details.
- **People who like HyDE's aesthetic and tooling** but want declarative deployment, reproducibility, and the ability to roll back desktop changes the way you roll back any other NixOS generation.
- **Anyone planning to customize.** The whole `Configs/` tree is a thin payload — keybindings are one lua file, themes are a directory, waybar layouts are templated. You can fork and edit without reverse-engineering an installer.

## Who this isn't for

- **Arch / Fedora / non-NixOS users.** Use [upstream HyDE](https://github.com/HyDE-Project/HyDE) instead. DOORwayDE's deployment story is Nix-shaped end-to-end; there is no equivalent on imperative distros and we don't try to provide one.
- **Anyone wanting hyprlang configs.** DOORwayDE migrated to Hyprland 0.55+'s lua config format. The `*.conf` files are gone (with the exception of a few daemon configs that still use hyprlang — `hypridle.conf`, `hyprlock.conf`). If you have a strong preference for hyprlang, you'll be fighting the codebase.
- **Anyone counting on full wallbash dynamic recoloring today.** The wallbash pipeline (extract palette from wallpaper → recolor everything live) is currently on pause; see [the wallbash gap](Troubleshooting-Hyprland.md#the-wallbash-gap) for the technical reason. Static theme switching via the rofi selector works fine — you can still change themes and the colors update — but the per-wallpaper auto-derived palette path doesn't apply to Hyprland itself yet.
- **People who want a minimal i3-style setup.** DOORwayDE is loaded: animations, blur, gradients, a fairly busy waybar, a theme system. It's HyDE-flavored, not bare-bones. You can strip features but the defaults aren't minimal.

---

## Lineage and how this differs from upstream HyDE

DOORwayDE started as a fork of [HyDE](https://github.com/HyDE-Project/HyDE), which itself continues the lineage of [prasanthrangan/hyprdots](https://github.com/prasanthrangan/hyprdots). The visual identity, theme catalog, and keybinding philosophy come from that upstream.

What's specifically DOORwayDE:

| Concern | Upstream HyDE | DOORwayDE |
|---|---|---|
| **Target OS** | Distro-agnostic, primarily Arch | NixOS-native |
| **Deployment** | Imperative installer shell scripts | Home Manager module via flake input |
| **Config format** | Mostly hyprlang (`.conf`) | Hyprland 0.55+ lua (`.lua`) |
| **Branding prefix** | `HYDE_`, `hyde-shell`, `hydectl` | `DOORWAYDE_`, `doorwayde-shell`, `doorwaydectl` |
| **Edit workflow** | Edit `~/.config/hypr/*` directly | Edit `Configs/.config/hypr/*` in repo, then `nixos-rebuild switch` (the deployed paths are read-only Nix store symlinks) |

The lua migration is the largest semantic divergence. It's documented in detail in `HyDE-to-DOORwayDE.md` and (eventually) in the planned `Lua-Migration-Notes.md` wiki article.

DOORwayDE is then consumed by [HALLway](https://github.com/MarkusBitterman/HALLway), the full NixOS flake that bundles a complete operating system. HALLway treats DOORwayDE as one of its inputs — the same pattern any other NixOS user would use. You can run DOORwayDE outside HALLway just fine; HALLway is the largest consumer, not the only one.

---

## How DOORwayDE thinks about your machine

Three load-bearing ideas shape the design. Worth knowing up front because they explain a lot of "wait, why is it like that?" later:

### 1. The repo is the source of truth, the deployed paths are read-only.

Every file under `~/.config/hypr/`, `~/.config/rofi/`, `~/.local/lib/doorwayde/`, etc. is either a symlink into the Nix store (root-owned, read-only) or a file Home Manager generated at activation. **You don't edit them directly.** You edit the corresponding file in this repo's `Configs/` tree, then `sudo nixos-rebuild switch --flake ...` to redeploy.

This is the single biggest mental shift for users coming from imperative distros. For the full story (including the runtime-write story for scripts that need to save state somewhere), see [CLAUDE.md's Nix Store Workflow section](../CLAUDE.md#nix-store-workflow--critical).

### 2. The lua config is event-driven, not declarative everywhere.

Hyprland 0.55+ kept the declarative `hl.config({...})` table but moved a lot of behavior into the lua scripting layer. Keybindings are function calls (`hl.bind(...)`), exec-once is a lifecycle event (`hl.on("hyprland.start", function() ... end)`), env vars are direct calls (`hl.env(K, V)`). DOORwayDE's `Configs/.local/share/hypr/` directory holds the scripts that wire it all up.

What this means for you: most "I want it to do X on startup" or "I want a new shortcut for Y" changes are simple lua additions, not config-file edits. The full chain is documented (eventually) in the planned `Architecture-Overview.md`.

### 3. The bar is its own thing, owned by `waybar.py`.

Most Nix-managed desktop setups treat `~/.config/waybar/` as a static config directory. DOORwayDE doesn't — `waybar.py` generates the active config, layout, and stylesheet at runtime, picking modules and styles from templates that live in `~/.local/share/waybar/` (Nix-managed) and writing the live config into `~/.config/waybar/` (session state, *not* Nix-managed). This is why you can switch waybar layouts at runtime (`SUPER + ALT + ↑/↓`) without rebuilding NixOS.

If you find yourself trying to edit `~/.config/waybar/config.jsonc` and watching your changes vanish on next reload, this is why. Edit the templates in `Configs/.local/share/waybar/` instead.

---

## Where to go next

Pick the article that matches your moment:

| You want to… | Read |
|---|---|
| Install DOORwayDE on your NixOS system | [Using-DOORwayDE-with-Nix.md](Using-DOORwayDE-with-Nix.md) |
| Learn the desktop after first login | [Interface-Tour.md](Interface-Tour.md) |
| Memorize the daily-use keyboard shortcuts | [Keybindings-Primer.md](Keybindings-Primer.md) |
| Diagnose a session that won't start or shows the emergency banner | [Troubleshooting-Hyprland.md](Troubleshooting-Hyprland.md) |
| Understand the lua orchestrator, IPC topology, and script chain | *Architecture-Overview.md* (planned, not yet written) |
| Read the contributor manual | [CLAUDE.md](../CLAUDE.md) in the repo root |

If you came here from the top-level [README](../README.md), that's the front-porch overview; this wiki is for once you're past the welcome mat and want depth.

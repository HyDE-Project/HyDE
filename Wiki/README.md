# DOORwayDE Wiki

Long-form documentation for DOORwayDE. The repository [README](../README.md) covers what most users need to install and run the desktop. This wiki is for when you're going deeper — troubleshooting, internals, the scripting API, and the design decisions behind the lua migration.

## Current Articles

Listed in the order a new reader would consume them:

- [**Introduction**](Introduction.md) — what DOORwayDE is, who it's for, what's in the box, how it relates to upstream HyDE and HALLway, the three load-bearing design ideas.
- [**Using DOORwayDE with Nix**](Using-DOORwayDE-with-Nix.md) — a 60-second flakes intro, the full flake integration walkthrough, the module options reference, what gets deployed at activation, the manual setup script for non-flake users.
- [**Interface Tour**](Interface-Tour.md) — what you see after first login: the waybar, rofi menus, dunst notifications, the logout menu, theme switching (with an honest note on the wallbash-lua gap), and where state files live.
- [**Keybindings Primer**](Keybindings-Primer.md) — a by-use-case tour of the keyboard shortcuts: essentials, window management, workspaces, launchers, screenshots, media, theming, system control, and mouse bindings.
- [**Troubleshooting Hyprland**](Troubleshooting-Hyprland.md) — diagnosing lua config errors, backend / seat crashes, distinguishing DOORwayDE bugs from HALLway / NixOS bugs, log paths, worked examples.

## Planned Articles

These pages have a defined scope but aren't written yet. Open a PR if you want to take one on.

- [TODO] **Architecture-Overview.md** — the orchestrator chain (`~/.config/hypr/hyprland.lua` → `~/.local/share/doorwayde/hyprland.lua` → `env`, `variables`, `defaults`, `windowrules`, `dynamic`, `startup`, `workflows`, `finale`), how `doorwayde-shell` and `doorwaydectl` fit into the runtime, the IPC topology.
- [TODO] **Theming-and-Wallbash.md** — how the wallbash color pipeline works end-to-end, where the `colors.conf` artifacts come from, why dynamic colour theming is currently in a transitional state on lua-only Hyprland (see the `try_source` no-ops in `dynamic.lua`).
- [TODO] **Keybindings-Reference.md** — auto-generated index of every bind. `keybindings.lua` descriptions already follow the `[Section|Sub] desc` format — perfect input for a generator (`hint-hyprland.py` is the closest existing precedent).
- [TODO] **Scripting-API.md** — the `doorwayde-shell`, `doorwaydectl`, and `doorwayde-ipc` surface: subcommand inventory, exit code contracts, environment dependencies.
- [TODO] **Lua-Migration-Notes.md** — why the lua migration happened, what changed semantically (not just syntactically), which APIs renamed (`repeat` → `repeating`, dispatcher namespacing), gotchas to expect when porting upstream HyDE PRs onto our lua-based fork.
- [TODO] **Hyprland-Lua-API-Cheatsheet.md** — every `hl.*` call used in this repo, what it does, what shape it expects. Useful for both writing new config and reading the lua example upstream.

## Contributing to the Wiki

- One topic per file. Cross-link liberally.
- Aim for self-contained articles — readers should be able to land on a single page from a search engine and get a useful answer.
- Real examples beat abstract description. If you can paste a real diagnostic output and walk through it, do that.
- Verify any command you reference still works on the pinned Hyprland version (see `flake.nix`).

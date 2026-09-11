# Upgrading to the Lua configuration

Hyprland 0.56 warns against the old `hyprlang` config format, so HyDE moved its
entire Hyprland configuration to Lua. If you installed HyDE before that release,
this page covers what changed, what breaks, and what to do about it.

> [!NOTE]
> For the most comprehensive guide on migration, it is highly recommended to check the HyDE wiki first: [Lua for the User & Migration](https://hydeproject.pages.dev/en/help/lua/)

## What changed

| Before | Now |
| :--- | :--- |
| `~/.config/hypr/hyprland.conf` and the files it sourced | `~/.local/share/hypr/hyde.lua` |
| `~/.config/hypr/keybindings.conf` | `~/.local/share/hypr/lua/key_binds.lua` |
| `~/.config/hypr/userprefs.conf` — your own settings | `~/.config/hypr/hyprland.lua` |
| `~/.config/hypr/windowrules.conf`, `monitors.conf`, `nvidia.conf` | your own `hyprland.lua`, or HyDE's `lua/` modules |
| `~/.config/hypr/animations.conf`, `workflows.conf` | `hyde-shell animations --select`, `hyde-shell workflows --select` |

Hyprland is started against `~/.local/share/hypr/hyde.lua`. That file loads
HyDE's modules, then HyDE's own keybinds, then yours, and last the workflow you
selected. Everything under `~/.local/share/hypr/` is overwritten on every
update; `~/.config/hypr/hyprland.lua` is never touched.

**None of the old `.conf` files are read any more.** They are not parsed, not
sourced, and not migrated. Whatever you had in `userprefs.conf` has to be
rewritten in Lua — see [KEYBINDINGS.md](KEYBINDINGS.md#custom-keybindings) for
the bind syntax.

## Upgrading

```bash
cd ~/HyDE/Scripts   # wherever you cloned it
git pull
./install.sh -r
```

Two things worth knowing before you run it:

- `git pull` on its own changes nothing on your machine. The deployment and the
  migration step both live in `install.sh -r`.
- `install.sh -r` refreshes the Python environment before it deploys anything,
  so the dot deployment runs the dependency revisions this checkout pins rather
  than whatever was installed last time.

## The failures are silent

`hyprctl configerrors` stays empty for every problem below. Nothing warns you,
so match your symptom here rather than looking for an error.

| What you see | What it is |
| :--- | :--- |
| A bare session or a black screen with just a cursor when starting from a TTY | You are pointing Hyprland at the wrong file. Use `Hyprland -c ${XDG_DATA_HOME:-$HOME/.local/share}/hypr/hyde.lua`, or start through `start-hyprland`. `~/.config/hypr/hyprland.lua` is loaded *by* HyDE, it is not the entry point |
| The session refuses to start, `No valid HyDE configuration found` | The Lua runtime is missing. Install `lua` and `luarocks` |
| A red overlay: `Hyprland does not detect colors! Run: hyde-shell reload` | Theme colours were never generated for the Lua state. Run `hyde-shell reload` |
| Shader, animation, workflow or theme selectors report success and change nothing | An old shell script from the previous release is still answering in place of its replacement. The migration in `install.sh -r` moves those aside; if it warned that it left some in place, deal with the named files and run `install.sh -r` again |
| Keybinds you added yourself are gone | They were in `userprefs.conf`, which is no longer read. Rewrite them in `~/.config/hypr/hyprland.lua` |
| A keybind exists twice, or your override did not take | Your bind did not copy the flags of the one you meant to replace. See the flag note in [KEYBINDINGS.md](KEYBINDINGS.md#custom-keybindings) |
| <kbd>SUPER</kbd> + <kbd>/</kbd> says the hint failed to initialise | A stale hint cache. Run `hyde-shell keybinds_hint --reload` |
| An unexpected yellow tint, or workspace 1 on the wrong monitor | Old state carried over. Check `hyde-shell shaders --select` and your monitor settings in `~/.config/hypr/hyprland.lua` |

## Files left behind

Deployment overwrites files but does not delete the ones that disappeared
upstream, so an upgraded machine keeps a full set of orphans that nothing reads:

```
~/.config/hypr/{hyprland,keybindings,userprefs,windowrules,monitors,nvidia}.conf
~/.config/hypr/{animations,workflows,shaders}.conf
~/.config/hypr/animations/  ~/.config/hypr/workflows/
~/.local/share/hypr/*.conf
~/.local/share/hyde/{hyprland,keybindings}.conf
```

They are harmless as long as nothing points at them, and the migration step does
not remove them. Keep them until you have finished porting your settings across,
then delete them — they are the only copy of your old configuration.

Two orphans are not harmless:

- `~/.config/systemd/user/hyde-config.service` and `hyde-ipc.service` no longer
  exist upstream. If you enabled them, they will keep failing:
  `systemctl --user disable --now hyde-config.service hyde-ipc.service`
- `~/.config/fish/completions/hyde-shell.fish` and
  `~/.config/zsh/completions/hyde-shell.zsh` moved into HyDE's library
  directory. The old copies shadow the new ones; delete them.

## Where your settings go now

Everything you used to keep in `userprefs.conf` goes in
`~/.config/hypr/hyprland.lua`:

```lua
hl.monitor({ output = "HDMI-A-1", mode = "3840x2160@60", position = "0x0", scale = 1 })

hl.config({
    input = { kb_layout = "us,ru" },
    general = { allow_tearing = true },
})

hl.window_rule({
    name = "my_terminal_opacity",
    match = { class = "^(kitty)$" },
    opacity = "0.9 0.9 1",
})

hl.bind("SUPER + SPACE", hl.dsp.exec_cmd(hyde.sh.gamelauncher()), {
    description = "[Utilities] game launcher",
})
```

The Hyprland side of this — dispatchers, window rules, monitors — is documented
in the [Hyprland wiki](https://wiki.hypr.land/Configuring/). The HyDE side —
`hyde.sh`, the command map and the bind flags — is in
[KEYBINDINGS.md](KEYBINDINGS.md#custom-keybindings).

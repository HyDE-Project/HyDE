# Tests

Structural checks over the shipped configuration and scripts. They read the
tree, never the machine: no Hyprland session, no installed HyDE, nothing
outside the repository is touched.

## Running

```sh
sh tests/run.sh          # every case
sh tests/run.sh binds    # only cases whose name contains "binds"
```

Each case is an executable `tests/test_*.sh` that prints its own diagnostics
and exits non-zero on failure. `tests/run.sh` discovers them, so adding a case
is adding a file.

## Cases

| Case | Checks |
| --- | --- |
| `test_app_wrapper.sh` | Launching through either `app.sh` execution path does not leak an unrelated non-boolean `DEBUG` value into app2unit or xdg-terminal-exec |
| `test_binds.sh` | Loads the Lua keybinds against a stubbed Hyprland API: no two binds share a combination once modifiers are folded to what Hyprland matches on, no keysym sits in a modifier position, no bind uses the `code:NN` form the Lua parser rejects, every bind has a description, every `hyde-shell` command it runs exists. Touchpad gestures are checked in the same pass: a valid finger count, a direction and action Hyprland accepts, and no two gestures on the same finger count and direction |
| `test_git.sh` | The tree holds no gitlink without a matching `.gitmodules` entry, which would break `git submodule` and anything walking submodules |
| `test_dots.sh` | Every installer metafile under `Scripts/dots` parses, declares the keys the installer needs, uses a known action, and points at a source directory and source paths that exist. It also keeps Grimblast on the fixed official source |
| `test_lua_syntax.sh` | Every shipped Lua file parses |
| `test_schema.sh` | Generated schema artifacts use the current Lua battery notification daemon rather than the removed shell implementation |
| `test_screenshot_wrapper.sh` | Satty receives a compatible default GTK renderer while preserving explicit renderer overrides |
| `test_shell.sh` | Every shipped shell script parses, and shellcheck finds no error-severity problem |

## Dependencies

| Tool | Used by | Missing |
| --- | --- | --- |
| `lua`, `luac` | bind and Lua syntax checks | case is skipped |
| `python3` 3.11+ | metafile check | case is skipped |
| `shellcheck` | shell check | only the parse half runs |

A skipped case is reported as such and does not fail the run, so the suite
stays usable on a machine without the full toolchain. CI installs everything,
so nothing is skipped there.

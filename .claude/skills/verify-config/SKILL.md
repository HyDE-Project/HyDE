---
name: verify-config
description: Validate Hyprland Lua configs against source files without requiring a nixos-rebuild. Temporarily redirects ~/.local/share/hypr and ~/.local/share/doorwayde symlinks to the repo's Configs/ tree so --verify-config reads source files instead of the Nix store. Useful after editing any .lua file in Configs/.
---

Validate the Hyprland config from source:

```bash
orig_hypr=$(readlink ~/.local/share/hypr)
orig_dw=$(readlink ~/.local/share/doorwayde)
ln -sfn "$HOME/Developments/DOORwayDE/Configs/.local/share/hypr" ~/.local/share/hypr
ln -sfn "$HOME/Developments/DOORwayDE/Configs/.local/share/doorwayde" ~/.local/share/doorwayde
Hyprland --verify-config 2>&1
ln -sfn "$orig_hypr" ~/.local/share/hypr
ln -sfn "$orig_dw" ~/.local/share/doorwayde
```

Check output for `ERR`, `nil`, `attempt to call`, or `config` errors. Clean output (no error lines) means the config parses correctly.

Common error patterns:
- `attempt to call a nil value` — called an `hl.*` function that doesn't exist in this Hyprland version
- `ERR: ...` — syntax error or invalid value type in a config block
- `"on"/"off" where bool expected` — use `true`/`false` in Lua, not string literals

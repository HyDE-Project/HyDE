---
name: nix-deploy
description: Deploy DOORwayDE changes to HALLway. Commit and push in this repo, then update the flake lock and rebuild NixOS in HALLway. Always commit+push BEFORE nix flake update — the Nix evaluator fetches the latest pushed commit; local changes are invisible to it.
disable-model-invocation: true
---

Deploy DOORwayDE changes to the live NixOS system:

1. In ~/Developments/DOORwayDE:
   ```bash
   git status
   ```
   Confirm there are no untracked sensitive files before staging.

2. If there are uncommitted changes, commit them:
   ```bash
   git add -p   # stage selectively
   git commit
   ```

3. Push — REQUIRED before the next step:
   ```bash
   git push
   ```
   If you skip this, `nix flake update` silently reuses the previous commit.

4. In ~/Developments/HALLway, update the flake lock to the latest DOORwayDE commit:
   ```bash
   cd ~/Developments/HALLway
   nix flake update doorwayde
   ```
   Verify it picked up the right commit:
   ```bash
   grep -A2 '"doorwayde"' flake.lock | grep '"rev"'
   ```

5. Rebuild:
   ```bash
   sudo nixos-rebuild switch --flake ~/Developments/HALLway/#2600AD
   ```

6. Smoke-test the deployment:
   ```bash
   Hyprland --verify-config
   journalctl --user -b -n 20 --no-pager | grep -iE "(waybar|dunst|doorwayde)"
   ```

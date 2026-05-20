# Release Policy

DOORwayDE follows a rolling release model aligned with the HALLway ecosystem.

## Rolling Releases

There are no scheduled release cycles. Changes are committed to `master` when ready:

- **Ship when ready** — Features and fixes land as they're completed
- **Iterate continuously** — Small, frequent commits over big releases
- **Master is the release** — The `master` branch is always the current version

## Versioning with Nix Flakes

DOORwayDE uses Nix flakes for reproducible versioning:

```bash
# Lock to a specific commit
nix flake lock --update-input doorwayde

# Pin a known-good state
git rev-parse HEAD  # This is your "version"
```

The `flake.lock` file pins exact dependencies. To reproduce a specific state, check out that commit and run `nix build`.

## HALLway Ecosystem Alignment

DOORwayDE is a component of HALLway OS. Its release cadence follows the parent project:

- **Coordinated updates** — Major changes sync with HALLway releases when practical
- **Independent iteration** — Bug fixes and improvements don't wait for HALLway

## Commit Conventions

Use [Conventional Commits](https://www.conventionalcommits.org/) for clear history:

```
feat: add new wallpaper selector
fix: resolve waybar crash on monitor hotplug
chore: update flake inputs
docs: clarify keybinding documentation
```

This enables automatic changelog generation and makes history searchable.

## Stability Expectations

- **Master should work** — Don't commit broken code to master
- **Test before pushing** — Use `nix build` or symlink testing
- **Breaking changes get docs** — Update README or migration notes when needed

## For Contributors

1. Fork the repo
2. Make changes on a feature branch
3. Test with `nix build` or the symlink method
4. Submit a PR to `master`
5. Changes merge when reviewed and passing

No dev/rc branches. No freeze periods. Just working code.

# Contributing to DOORwayDE

Thank you for your interest in contributing to DOORwayDE. This project is part of the HALLway ecosystem and welcomes contributions including bug fixes, feature enhancements, documentation improvements, and general improvements.

## Getting Started

1. **Fork the repository**

   Click the **Fork** button at [github.com/MarkusBitterman/DOORwayDE](https://github.com/MarkusBitterman/DOORwayDE/fork).

2. **Clone your fork**

   ```bash
   git clone https://github.com/YOUR-USERNAME/DOORwayDE.git
   cd DOORwayDE
   ```

3. **Create a branch for your changes**

   ```bash
   git checkout -b your-branch-name
   ```

4. **Make your changes**

   Follow the [commit message guidelines](COMMIT_MESSAGE_GUIDELINES.md):

   ```bash
   git commit -m "feat: add a new feature"
   ```

5. **Test your changes**

   - **Nix build:** `nix build` (if you have flakes enabled)
   - **Symlink testing:** See [CLAUDE.md](CLAUDE.md) for quick test instructions
   - **VM testing:** Use [doorwaydevm](Scripts/doorwaydevm/README.md) for isolated testing

6. **Push and submit a PR**

   ```bash
   git push origin your-branch-name
   ```

   Then open a pull request against the `master` branch.

## Guidelines

- **Follow the code style** — Use `shellcheck` for shell scripts
- **Update documentation** if your change affects user-facing behavior
- **Keep PRs focused** — Avoid unrelated changes in the same PR
- **Test before submitting** — Make sure your changes work

## Changelog

Changes that affect users should be documented in `CHANGELOG.md`:

- Use existing entries as a style guide
- Focus on user impact, not technical details
- Follow [Keep a Changelog](https://keepachangelog.com/) format

## Issue Templates

When opening issues, use the appropriate template:

- **Bug reports** — For things that are broken
- **Feature requests** — For new functionality
- **Documentation updates** — For docs improvements

## Code Style

- **Shell scripts:** `shellcheck` compatible, prefer `[[ ]]` over `[ ]`
- **Nix:** Use `nixfmt` or `alejandra`
- **Configs:** Follow existing patterns for consistency

## Questions?

Open a [GitHub Discussion](https://github.com/MarkusBitterman/DOORwayDE/discussions) or file an issue.

# Dotfiles

[![](https://img.shields.io/github/license/muhlba91/dotfiles?style=for-the-badge)](LICENSE.md)
[![](https://img.shields.io/github/actions/workflow/status/muhlba91/dotfiles/verify.yml?style=for-the-badge)](https://github.com/muhlba91/dotfiles/actions/workflows/verify.yml)
[![](https://api.scorecard.dev/projects/github.com/muhlba91/dotfiles/badge?style=for-the-badge)](https://scorecard.dev/viewer/?uri=github.com/muhlba91/dotfiles)

This repository contains my macOS (Apple Silicon) configuration, managed with [chezmoi](https://www.chezmoi.io): shell, git, GPG/SSH, editors, terminal, Homebrew packages, and VS Code extensions.

---

## Requirements

- macOS on Apple Silicon
- [Homebrew](https://brew.sh)
- [chezmoi](https://www.chezmoi.io/install/)

## Bootstrap

On a fresh machine, follow [`docs/RESTORE.md`](docs/RESTORE.md). The core step is:

```bash
chezmoi init --apply muhlba91/dotfiles
```

This clones the repository (over https, no credentials needed) into chezmoi's default source directory, applies all files, and runs the setup scripts. To clone it somewhere else, add `--source <directory>`; the location is remembered in chezmoi's configuration.

## Structure

[`.chezmoiroot`](.chezmoiroot) points chezmoi to [`home/`](home/); everything outside of it is repository tooling.

- [`home/`](home/): the files that are applied to `$HOME`, named by chezmoi's [source state conventions](https://www.chezmoi.io/reference/source-state-attributes/) (`dot_zshrc` becomes `~/.zshrc`).
- [`home/.chezmoi.toml.tmpl`](home/.chezmoi.toml.tmpl): remembers the repository's location as chezmoi's source directory.
- [`home/.chezmoiignore`](home/.chezmoiignore): paths that must never be picked up (credentials, caches, agent sockets).
- [`home/.chezmoiexternal.toml`](home/.chezmoiexternal.toml): pinned archives of oh-my-zsh, its theme and plugins, and vim-airline.
- [`home/.chezmoidata/packages.yaml`](home/.chezmoidata/packages.yaml): Homebrew taps, formulae, casks, and VS Code extensions.
- [`home/.chezmoiscripts/`](home/.chezmoiscripts/): scripts that install the packages, set up the Rust toolchain, and write macOS defaults.
- [`docs/`](docs/): documentation.

## Scripts

The scripts in [`home/.chezmoiscripts/`](home/.chezmoiscripts/) run during `chezmoi apply`:

- `run_onchange_before_10-brew-bundle.sh.tmpl`: installs everything in `packages.yaml` via `brew bundle`; re-runs when the lists change.
- `run_onchange_after_20-vscode-extensions.sh.tmpl`: installs the VS Code (Insiders) extensions; re-runs when the list changes.
- `run_onchange_after_25-rust.sh.tmpl`: sets up the stable Rust toolchain via `rustup`.
- `run_once_after_30-defaults.sh`: writes a short list of macOS preferences, and restarts Dock and Finder.

## Daily Usage

Apps rewrite some managed files themselves (VS Code and Claude Code `settings.json`). Always check before applying:

```bash
chezmoi diff
```

Keep a change made on the machine:

```bash
chezmoi re-add
```

Edit a file in the repository, then apply it:

```bash
chezmoi edit ~/.zshrc
chezmoi apply
```

Start managing a new file:

```bash
chezmoi add ~/.some-config
```

**Attention**: `chezmoi add` refuses files that look like they contain a secret. If a file only contains a public identifier, review it and use `--secrets ignore` (this is the case for `~/.gitconfig`).

### Packages

Add or remove a package in [`home/.chezmoidata/packages.yaml`](home/.chezmoidata/packages.yaml), then run `chezmoi apply`. The installation scripts run again because their rendered content changed.

### External Dependencies

The archives in [`home/.chezmoiexternal.toml`](home/.chezmoiexternal.toml) are pinned to a tag or a commit and are updated by [Renovate](https://docs.renovatebot.com). The pinned archives contain no `.git`, so oh-my-zsh's own update mechanism is disabled.

## Secrets

This repository is public, so no secrets are stored in it.

- Environment secrets live in `~/.config/zsh/secrets.zsh`, which is sourced by `.zshrc` and is not managed.
- Keys, tokens, and cloud credentials are never added; [`.chezmoiignore`](home/.chezmoiignore), [`.gitignore`](.gitignore), and the `forbid secret-like files` hook guard against it.
- [gitleaks](https://github.com/gitleaks/gitleaks) scans every commit; its configuration is in [`.gitleaks.toml`](.gitleaks.toml).

## Development

[pre-commit](https://pre-commit.com) runs the checks locally (commit message format, whitespace, secret detection, syntax checks):

```bash
pre-commit install --install-hooks -t pre-commit -t commit-msg
pre-commit run --all-files
```

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org), configured in [`.conform.yaml`](.conform.yaml).

# Restore

How to rebuild a machine from this repository. The steps are in order; the repository is public, so nothing before step 3 requires credentials.

## 1. Command Line Tools

```bash
xcode-select --install
```

## 2. Homebrew and chezmoi

Install [Homebrew](https://brew.sh) with its official installer, then chezmoi:

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
brew install chezmoi
```

Clone and apply the repository (to use a different location than chezmoi's default, add `--source <directory>`):

```bash
chezmoi init --apply muhlba91/dotfiles
```

The apply does the following:

- writes all dotfiles and configuration into `$HOME`,
- extracts oh-my-zsh, powerlevel10k, the zsh plugins, and vim-airline,
- installs all Homebrew taps, formulae, and casks (`brew bundle`), and fixes the permissions of the zsh completion directories,
- installs the VS Code (Insiders) extensions,
- installs the stable Rust toolchain,
- writes the macOS defaults, and restarts Dock and Finder.

The first run takes a while, because of the number of packages. If a step fails, fix the cause and run `chezmoi apply` again; the scripts only run again when they failed or their input changed.

**Attention**: if `~/.oh-my-zsh` or `~/.vim/pack/plugins/start/vim-airline` already exist as git clones (an existing machine, not a fresh one), move them away before the first apply.

## 3. Java

Homebrew's `openjdk` is not visible to macOS tools until it is linked. This needs `sudo` and is not part of the apply:

```bash
sudo ln -sfn /opt/homebrew/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk
```

The VS Code Java extension expects it there.

## 4. GPG and YubiKey

1. Import the public key, for example from a keyserver or a backup.
2. Insert the YubiKey and let GnuPG learn the card:

   ```bash
   gpg --card-status
   yk-learn
   ```

3. Verify signing and SSH authentication through the agent:

   ```bash
   echo test | gpg --clearsign
   ssh-add -L
   ```

The configuration (`gpg.conf`, `gpg-agent.conf`, `scdaemon.conf`, SSH config) is already in place from step 2. Key material is never stored in this repository.

## 5. Secrets

Recreate `~/.config/zsh/secrets.zsh` (mode `600`) from the password manager. It is sourced by `.zshrc` and deliberately not managed.

## 6. Sign-ins

- `gh auth login`
- `aws sso login`
- `gcloud auth login`
- the Kubernetes configuration (`kubectl`, `talosctl`)

Then sign in to the applications: Raycast (import its export file), the cloud drive applications, Kiro, and Claude.

## 7. Optional

Restore `~/gpg/` from the backup, if it is needed.

## 8. Verify

```bash
chezmoi status
chezmoi doctor
```

Open a new terminal: the prompt should load without errors, and `brew doctor` should report that the system is ready to brew.

#!/bin/bash
# Exercises the chezmoi source state without touching the real home directory.
# Needs: chezmoi, zsh, shellcheck, jq, python3 (3.11+), curl. Run from the repository root.
# DESTINATION and SCRATCH must point to (non-existing or empty) throwaway directories.
set -euo pipefail

: "${DESTINATION:?must be set}"
: "${SCRATCH:?must be set}"

source_dir="$(pwd)"
mkdir -p "$DESTINATION" "$SCRATCH"

# the real config is not used: it only holds the machine's source directory
chezmoi_cmd=(chezmoi --source "$source_dir" --destination "$DESTINATION" --config "$SCRATCH/chezmoi.toml" --persistent-state "$SCRATCH/state.boltdb")

echo "::group::chezmoi doctor"
"${chezmoi_cmd[@]}" doctor || true
echo "::endgroup::"

echo "::group::render templates"
while IFS= read -r -d '' tmpl; do
  echo "rendering ${tmpl}"
  rendered="$SCRATCH/rendered/${tmpl#home/}"
  mkdir -p "$(dirname "$rendered")"
  "${chezmoi_cmd[@]}" execute-template < "$tmpl" > "$rendered"
  case "$tmpl" in
    *.sh.tmpl)
      bash -n "$rendered"
      shellcheck "$rendered"
      ;;
  esac
done < <(find home -type f -name '*.tmpl' -print0)
echo "::endgroup::"

echo "::group::apply (without scripts and externals)"
"${chezmoi_cmd[@]}" apply --exclude=scripts,externals
"${chezmoi_cmd[@]}" verify --exclude=scripts,externals
echo "::endgroup::"

echo "::group::check applied files"
for f in .zshrc .zprofile .zshenv; do
  zsh -n "$DESTINATION/$f"
done
git config --file "$DESTINATION/.gitconfig" --list > /dev/null

mode() { stat -c '%a' "$1" 2> /dev/null || stat -f '%Lp' "$1"; }
if [[ "$(uname)" == Darwin ]]; then
  jq empty "$DESTINATION/.claude/settings.json"
  jq empty "$DESTINATION/Library/Application Support/Code - Insiders/User/settings.json"
  # private files must stay private
  test "$(mode "$DESTINATION/.ssh")" = "700"
  test "$(mode "$DESTINATION/.gnupg")" = "700"
  test "$(mode "$DESTINATION/.ssh/config")" = "600"
  git config --file "$DESTINATION/.config/git/gpg-signing" --get user.signingkey > /dev/null
else
  # Linux (the dev VMs): only the shell, git, tmux, vim and mise; the host's own config signs the commits
  for f in Library .gnupg .ssh .config/fnox .config/git/gpg-signing .claude; do
    test ! -e "$DESTINATION/$f" || { echo "$f must not be applied on Linux" >&2; exit 1; }
  done
  if git config --file "$DESTINATION/.gitconfig" --get user.signingkey; then
    echo ".gitconfig must not set a signing key on Linux" >&2
    exit 1
  fi
  test "$(git config --file "$DESTINATION/.gitconfig" --get commit.gpgsign)" = "true"
fi
echo "::endgroup::"

echo "::group::external archives resolve"
urls="$(python3 -c '
import sys, tomllib
with open("home/.chezmoiexternal.toml", "rb") as f:
    for entry in tomllib.load(f).values():
        print(entry["url"])
')"
test -n "$urls"
while IFS= read -r url; do
  echo "checking ${url}"
  curl -fsSIL -o /dev/null "$url"
done <<< "$urls"
echo "::endgroup::"

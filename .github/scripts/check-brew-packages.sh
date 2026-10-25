#!/bin/bash
# Verifies that every tap, formula and cask in packages.yaml exists, without installing anything.
# Core packages are checked against Homebrew's public JSON API, third-party ones against the tap repository on GitHub.
set -euo pipefail

file="${1:-home/.chezmoidata/packages.yaml}"
failed=0
cache="$(mktemp -d)"
trap 'rm -rf "$cache"' EXIT

auth=""
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  auth="Authorization: Bearer ${GITHUB_TOKEN}"
fi

fail() {
  echo "::error::$1"
  failed=1
}

# prints the file list of a tap repository (cached); fails if the repository does not exist
tap_tree() {
  local tap="$1" listing="${cache}/${1//\//__}"
  local owner="${tap%%/*}" repo="${tap##*/}"
  if [[ ! -e "$listing" && ! -e "${listing}.missing" ]]; then
    if ! curl -fsSL ${auth:+-H "$auth"} "https://api.github.com/repos/${owner}/homebrew-${repo}/git/trees/HEAD?recursive=1" | jq -r '.tree[].path' > "$listing"; then
      rm -f "$listing"
      : > "${listing}.missing"
    fi
  fi
  [[ -e "$listing" ]] && cat "$listing"
}

check() {
  local kind="$1" name="$2"
  if [[ "$name" == */*/* ]]; then
    local tap="${name%/*}" pkg="${name##*/}"
    if ! tap_tree "$tap" > /dev/null; then
      fail "tap repository for ${name} not found"
    elif ! tap_tree "$tap" | grep -Eq "(^|/)${pkg}\.rb$"; then
      fail "${kind} ${name} not found in its tap"
    fi
  elif ! curl -fsSL -o /dev/null "https://formulae.brew.sh/api/${kind}/${name}.json"; then
    fail "${kind} ${name} not found in Homebrew"
  fi
}

while read -r tap; do
  tap_tree "$tap" > /dev/null || fail "tap ${tap} not found"
done < <(yq -r '.brew.taps[]' "$file")

while read -r name; do check formula "$name"; done < <(yq -r '.brew.formulae[]' "$file")
while read -r name; do check cask "$name"; done < <(yq -r '.brew.casks[]' "$file")

exit "$failed"

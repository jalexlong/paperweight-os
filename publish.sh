#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAGES_DIR="$REPO_ROOT/gh-pages"
APT_CONF="$REPO_ROOT/apt-repo/conf"

# ---------------------------------------------------------------------------
# Ensure gh-pages worktree exists
# ---------------------------------------------------------------------------
if [[ ! -d "$PAGES_DIR" ]]; then
    echo "Setting up gh-pages worktree..."
    if ! git -C "$REPO_ROOT" show-ref --quiet refs/heads/gh-pages; then
        git -C "$REPO_ROOT" checkout --orphan gh-pages
        git -C "$REPO_ROOT" reset --hard
        git -C "$REPO_ROOT" commit --allow-empty -m "Initialize gh-pages"
        git -C "$REPO_ROOT" checkout -
    fi
    git -C "$REPO_ROOT" worktree add "$PAGES_DIR" gh-pages
fi

# ---------------------------------------------------------------------------
# Build all source packages (clean old artifacts first to avoid hash conflicts)
# ---------------------------------------------------------------------------
echo "Cleaning old build artifacts..."
rm -f "$REPO_ROOT"/packaging/*.deb \
      "$REPO_ROOT"/packaging/*.buildinfo \
      "$REPO_ROOT"/packaging/*.changes

echo "Building packages..."
for pkg_dir in "$REPO_ROOT"/packaging/*/; do
    [[ -f "$pkg_dir/debian/control" ]] || continue
    pkg_name="$(basename "$pkg_dir")"
    echo "  Building $pkg_name..."
    (cd "$pkg_dir" && dpkg-buildpackage -us -uc -b 2>&1 | tail -3)
done

# ---------------------------------------------------------------------------
# Publish .debs into the reprepro tree
# ---------------------------------------------------------------------------
echo "Publishing to apt repo..."
mkdir -p "$PAGES_DIR"

# Copy reprepro conf into the pages tree (reprepro needs conf/ next to its basedir)
mkdir -p "$PAGES_DIR/conf"
cp "$APT_CONF"/* "$PAGES_DIR/conf/"

for deb in "$REPO_ROOT"/packaging/*.deb; do
    [[ -f "$deb" ]] || continue
    echo "  Including $(basename "$deb")..."
    reprepro --basedir "$PAGES_DIR" includedeb trixie "$deb"
done

# ---------------------------------------------------------------------------
# Export public key for users to add
# ---------------------------------------------------------------------------
GPG_KEY_ID="$(grep '^SignWith:' "$APT_CONF/distributions" | awk '{print $2}')"
if [[ "$GPG_KEY_ID" != "PAPERWEIGHT_GPG_KEY_ID" ]]; then
    gpg --export "$GPG_KEY_ID" > "$PAGES_DIR/pubkey.gpg"
    echo "Exported GPG public key to gh-pages/pubkey.gpg"
else
    echo "WARNING: GPG key not configured — skipping pubkey export."
    echo "         Run setup-gpg.sh first, then re-run this script."
fi

# ---------------------------------------------------------------------------
# Commit and push gh-pages
# ---------------------------------------------------------------------------
echo "Pushing gh-pages..."
git -C "$PAGES_DIR" add -A
git -C "$PAGES_DIR" commit -m "Publish packages $(date -u +%Y-%m-%dT%H:%M:%SZ)" || echo "(nothing changed)"
git -C "$PAGES_DIR" push origin gh-pages

echo ""
echo "Done. Users can add your repo with:"
echo "  wget -O - https://jalexlong.github.io/paperweight-os/pubkey.gpg | sudo tee /etc/apt/trusted.gpg.d/paperweight.gpg"
echo "  echo 'deb https://jalexlong.github.io/paperweight-os trixie main' | sudo tee /etc/apt/sources.list.d/paperweight.list"
echo "  sudo apt update"

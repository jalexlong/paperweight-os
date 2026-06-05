#!/usr/bin/env bash
# Run this once to generate your package-signing GPG key and wire it into reprepro.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISTRIBUTIONS="$REPO_ROOT/apt-repo/conf/distributions"

echo "Generating GPG signing key for PaperweightOS..."
echo "(Choose: RSA and RSA, 4096 bits, no expiry, name/email you want on the key)"
echo ""
gpg --full-generate-key

echo ""
echo "Your secret keys:"
gpg --list-secret-keys --keyid-format long

echo ""
read -rp "Paste the key ID from the 'sec' line above (the part after 'rsa4096/'): " KEY_ID

# Substitute placeholder in distributions file
sed -i "s/PAPERWEIGHT_GPG_KEY_ID/$KEY_ID/" "$DISTRIBUTIONS"

echo ""
echo "Key ID $KEY_ID written to apt-repo/conf/distributions."
echo ""
echo "Back up your key now:"
echo "  gpg --armor --export-secret-keys $KEY_ID > paperweight-signing-key.asc"
echo "  # Store paperweight-signing-key.asc somewhere safe (NOT in this repo)"

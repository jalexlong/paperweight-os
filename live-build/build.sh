#!/bin/sh
set -e

# Requires Debian's live-build (20250505+deb13u1 or newer).
# Ubuntu ships an ancient 3.x fork that is incompatible with this config.
# Install the correct version with:
#
#   LB_VER="20250505+deb13u1"
#   wget "http://deb.debian.org/debian/pool/main/l/live-build/live-build_${LB_VER}_all.deb"
#   sudo dpkg -i "live-build_${LB_VER}_all.deb"

LB_VERSION=$(lb --version 2>/dev/null || echo "0")
case "$LB_VERSION" in
    3.*|"0")
        echo "ERROR: requires Debian live-build >= 20230612, found: $LB_VERSION" >&2
        echo "Install from: http://deb.debian.org/debian/pool/main/l/live-build/" >&2
        exit 1
        ;;
esac

cd "$(dirname "$0")"
sudo lb clean --all
sudo lb config
sudo lb build
echo "ISO: $(ls *.iso 2>/dev/null || echo 'not found — check build output')"

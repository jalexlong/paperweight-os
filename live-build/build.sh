#!/bin/sh
set -e
cd "$(dirname "$0")/live-build"
sudo lb clean
sudo lb config
sudo lb build
echo "ISO: $(ls *.iso 2>/dev/null || echo 'not found — check build output')"

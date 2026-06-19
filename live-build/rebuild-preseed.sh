#!/bin/sh
# Rebuild the ISO after editing preseed/paperweight.cfg.
#
# lb places the preseed via the installer stage (lb installer), not lb binary.
# Removing only binary stage files is insufficient — binary/install/preseed.cfg
# won't be updated. This script removes the right stage files and reruns only
# what's needed, leaving the chroot and d-i download cache intact.
#
# For full installer rebuild (e.g. after lb clean --binary wiped binary/install/):
#   sudo rm -f .build/installer_debian-installer .build/installer_preseed
#   sudo lb installer
#   sudo rm -f .build/binary_checksums .build/binary_iso && sudo lb binary

set -e
cd "$(dirname "$0")"

sudo rm -f .build/installer_preseed
sudo lb installer
sudo rm -f .build/binary_checksums .build/binary_iso
sudo lb binary

echo "ISO: $(ls live-image-amd64.hybrid.iso 2>/dev/null || echo 'not found — check build output')"
echo "Preseed in ISO:"
grep -E "debian_chroot|bashrc\.d|late_command" binary/install/preseed.cfg | head -5

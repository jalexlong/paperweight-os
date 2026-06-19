#!/bin/sh
# Rebuild the ISO after editing preseed/paperweight.cfg.
#
# The preseed is placed into binary/install/ by a binary hook
# (config/hooks/normal/0100-install-preseed.hook.binary), which runs
# during lb binary. Clearing the binary_hooks stage file forces lb
# to re-run the hook and pick up preseed changes.
#
# Requires a prior full build (chroot/ must exist).
# For a full build from scratch: sudo bash build.sh

set -e
cd "$(dirname "$0")"

echo "Repacking ISO with updated preseed..."
sudo rm -f .build/binary_hooks .build/binary_checksums .build/binary_iso
sudo lb binary

echo "ISO: $(ls live-image-amd64.hybrid.iso 2>/dev/null || echo 'not found — check build output')"
echo "Preseed in ISO:"
grep -E "late_command|paperweight-grub|debian_chroot|bashrc\.d" binary/install/preseed.cfg | head -5

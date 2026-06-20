#!/usr/bin/env bash
# Sync paperweight-skel configs to the current user's home directory,
# then reload sway and restart waybar if running in a sway session.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$(realpath "$0")")" && pwd)"
SKEL="$REPO_DIR/packaging/paperweight-skel/etc/skel/.config"

if [ ! -d "$SKEL" ]; then
    echo "error: skel .config directory not found at $SKEL" >&2
    exit 1
fi

echo "Syncing skel configs from: $SKEL"
echo "Destination: $HOME/.config"
echo

# foot/colors.ini is written by paperweight-theme — don't clobber it
rsync -av --exclude='foot/colors.ini' \
    "$SKEL/" "$HOME/.config/"

echo

if [ -n "${SWAYSOCK:-}" ]; then
    echo "Reloading sway config..."
    swaymsg reload

    echo "Restarting waybar..."
    pkill -x waybar || true
    waybar &
    disown

    echo
    echo "Done. Sway reloaded, waybar restarted."
else
    echo "Not in a sway session — skipping reload."
fi

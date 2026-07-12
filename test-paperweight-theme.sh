#!/usr/bin/env bash
# Exercise paperweight-theme end-to-end (file validation, per-surface swaps,
# active-theme bookkeeping) without a running Sway session — useful in CI,
# on a headless/display-less dev box, or in a sandboxed agent session.
#
# Builds a scratch $HOME under mktemp, seeds it from the packaging tree's
# skel configs, and stubs out every external command paperweight-theme
# shells out to (notify-send, swaymsg, pkill, pgrep, waybar, swaync-client,
# swaync, id — each just fails/no-ops, simulating "no Sway session, not in
# the sudo group"). Then runs paperweight-theme against each theme and
# diffs the resulting "active" file for every surface against its
# themes/<name>.* source, so a broken theme file or a paperweight-theme
# regression shows up without needing a real desktop session to catch it.
#
# Note: sh's `export -f` doesn't exist, so stubs are written as real
# executable scripts on a prepended PATH rather than shell functions.
#
# Usage:
#   ./test-paperweight-theme.sh              # test every theme
#   ./test-paperweight-theme.sh macchiato     # test one theme
#   ./test-paperweight-theme.sh --keep        # leave the scratch $HOME on disk for inspection
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$(realpath "$0")")" && pwd)"
SKEL="$REPO_DIR/packaging/paperweight-skel/etc/skel/.config"
THEME_SCRIPT="$REPO_DIR/packaging/paperweight-skel/usr/bin/paperweight-theme"

if [ ! -f "$THEME_SCRIPT" ]; then
    echo "error: paperweight-theme not found at $THEME_SCRIPT" >&2
    exit 1
fi

KEEP=0
THEMES=()
for arg in "$@"; do
    case "$arg" in
        --keep) KEEP=1 ;;
        *) THEMES+=("$arg") ;;
    esac
done
if [ ${#THEMES[@]} -eq 0 ]; then
    for f in "$SKEL/sway/themes"/*.conf; do
        THEMES+=("$(basename "$f" .conf)")
    done
fi

SCRATCH="$(mktemp -d /tmp/paperweight-theme-test.XXXXXX)"
cleanup() {
    if [ "$KEEP" -eq 1 ]; then
        echo "Scratch \$HOME left at: $SCRATCH"
    else
        rm -rf "$SCRATCH"
    fi
}
trap cleanup EXIT

STUBS="$SCRATCH/stubs"
mkdir -p "$STUBS"
for cmd in notify-send swaymsg pkill pgrep waybar swaync-client swaync; do
    cat > "$STUBS/$cmd" <<'EOF'
#!/bin/sh
exit 1
EOF
    chmod +x "$STUBS/$cmd"
done
# Reports no group memberships, so paperweight-theme skips the sudo-gated
# system-surface helpers (greeter/GRUB/Plymouth) — those need real sudo
# and are out of scope for this harness.
cat > "$STUBS/id" <<'EOF'
#!/bin/sh
echo "nogroup"
EOF
chmod +x "$STUBS/id"

HOME_DIR="$SCRATCH/home"
mkdir -p "$HOME_DIR/.config" "$HOME_DIR/.local/share/paperweight-os"
for dir in sway waybar swaync gtklock wofi foot wlogout fastfetch; do
    cp -r "$SKEL/$dir" "$HOME_DIR/.config/"
done

pass=0
fail=0

check_copy() {
    local label="$1" actual="$2" expected="$3"
    if [ ! -f "$actual" ]; then
        echo "  FAIL  $label — missing: $actual"
        fail=$((fail + 1))
    elif ! diff -q "$actual" "$expected" > /dev/null 2>&1; then
        echo "  FAIL  $label — differs from $expected"
        fail=$((fail + 1))
    else
        echo "  ok    $label"
        pass=$((pass + 1))
    fi
}

check_content() {
    local label="$1" actual="$2" expected="$3"
    if [ ! -f "$actual" ]; then
        echo "  FAIL  $label — missing: $actual"
        fail=$((fail + 1))
    elif [ "$(cat "$actual")" != "$expected" ]; then
        echo "  FAIL  $label — got '$(cat "$actual")', expected '$expected'"
        fail=$((fail + 1))
    else
        echo "  ok    $label"
        pass=$((pass + 1))
    fi
}

for theme in "${THEMES[@]}"; do
    echo "=== $theme ==="
    LOG="$SCRATCH/$theme.log"
    if ! PATH="$STUBS:$PATH" HOME="$HOME_DIR" bash "$THEME_SCRIPT" "$theme" > "$LOG" 2>&1; then
        echo "  FAIL  paperweight-theme exited non-zero — see $LOG"
        fail=$((fail + 1))
        continue
    fi

    check_content "active-theme marker" \
        "$HOME_DIR/.config/paperweight-os/active-theme" "$theme"
    check_copy "sway colors" \
        "$HOME_DIR/.config/sway/config.d/90-colors.conf" "$SKEL/sway/themes/$theme.conf"
    check_copy "swaync style" \
        "$HOME_DIR/.config/swaync/style.css" "$SKEL/swaync/themes/$theme.css"
    check_copy "gtklock style" \
        "$HOME_DIR/.config/gtklock/style.css" "$SKEL/gtklock/themes/$theme.css"
    check_copy "wofi style" \
        "$HOME_DIR/.config/wofi/style.css" "$SKEL/wofi/themes/$theme.css"
    check_copy "foot colors" \
        "$HOME_DIR/.config/foot/colors.ini" "$SKEL/foot/themes/$theme.ini"
    check_copy "wlogout style" \
        "$HOME_DIR/.config/wlogout/style.css" "$SKEL/wlogout/themes/$theme.css"
    check_copy "fastfetch config" \
        "$HOME_DIR/.config/fastfetch/config.jsonc" "$SKEL/fastfetch/themes/$theme.jsonc"

    waybar_style="$HOME_DIR/.config/waybar/style.css"
    if [ -f "$waybar_style" ] \
        && grep -q "$theme-palette.css" "$waybar_style" \
        && grep -q "$theme-waybar.css" "$waybar_style"; then
        echo "  ok    waybar style imports"
        pass=$((pass + 1))
    else
        echo "  FAIL  waybar style imports — $waybar_style doesn't reference $theme-{palette,waybar}.css"
        fail=$((fail + 1))
    fi
done

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]

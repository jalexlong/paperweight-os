# PaperweightOS — CLAUDE.md

## What This Is

A Debian Blend targeting resource-limited x86 laptops (any crappy laptop → usable dev machine).
Ships as metapackages + a personal apt repo, not a custom ISO (yet).
First real hardware target: Dell Chromebook 11 with coreboot ("Paperweight Pro").
Also well-suited for SSH-heavy server work out of the box.

Maintainer: Alex Long <johnalexanderlong@gmail.com>
GitHub: https://github.com/jalexlong/paperweight-os

---

## Architecture

```
paperweight-os/
├── packaging/
│   ├── paperweight-skel/        # Ships /etc/skel configs; no binary deps
│   ├── paperweight-desktop/     # Pure metapackage: Depends on full stack
│   └── paperweight-chromebook/  # (TODO) Hardware add-on for Chromebook/coreboot
├── apt-repo/
│   └── conf/                    # reprepro config (SignWith key must be set)
├── publish.sh                   # Build all .debs → sign → push gh-pages
├── setup-gpg.sh                 # One-time GPG key generation
└── CLAUDE.md                    # This file
```

### How packages relate

```
paperweight-desktop
  └── Depends: paperweight-skel + sway stack + fonts + tools

paperweight-chromebook  (optional add-on)
  └── Depends: paperweight-desktop + Chromebook-specific packages
```

### Config fragment philosophy

All configs use a `config.d/` drop-in model — no patching base files.
Same pattern as `/etc/apt/apt.conf.d/`. Hardware packages drop fragments into:

```
/etc/skel/.config/sway/config.d/10-chromebook-input.conf
```

The base sway config ends with `include ~/.config/sway/config.d/*.conf`, so
user-local fragments also work without modifying the skel defaults.

---

## Design Decisions (settled — don't revisit without good reason)

| Decision | Choice | Why |
|---|---|---|
| Base distro | Debian Stable (Trixie) | Stability over features |
| Compositor | Sway (Wayland) | Lightweight, keyboard-driven |
| Screen locker | gtklock | Better GTK CSS theming than swaylock |
| Notification daemon | sway-notification-center (swaync) | Notification center panel, more usable than mako |
| App launcher | wofi | Lightweight, Wayland-native |
| Terminal | kitty | Fast, GPU-accelerated |
| Audio | PipeWire + pipewire-pulse + WirePlumber | Modern stack, PulseAudio compat |
| Default theme | Catppuccin Macchiato | First theme; more + theme switcher planned |
| Font | JetBrains Mono Nerd Font | Monospace + icons in one font |
| Distribution model | Debian Blend (metapackages + apt repo) | No ISO until .debs are solid |
| Config target | General x86 laptop | Chromebook = optional module, not the default |

---

## Skel Config Structure

Files shipped in `paperweight-skel` land in `/etc/skel/.config/` and are
copied to new user home dirs automatically by `adduser`.

```
sway/config                    — base keybindings, bar, includes
sway/config.d/
  10-input.conf                — generic touchpad + keyboard tuning
  30-idle.conf                 — swayidle → gtklock (750s lock, 900s display off)
  50-desktop-session.conf      — exec swaync
  50-systemd-user.conf         — D-Bus / systemd user env import
  90-theme.conf                — full Catppuccin Macchiato palette + float rules
waybar/
  config.jsonc                 — modules: cpu+mem left, workspaces center, status right
  style.css                    — @import only; real styles in themes/
  themes/
    catppuccin-macchiato.css   — @define-color variables (the palette)
    macchiato-waybar.css       — actual module styles referencing those variables
swaync/
  config.json                  — notification center layout + widgets
  style.css                    — Macchiato-themed notification + panel CSS
wofi/style.css                 — launcher styles using @define-color variables
gtklock/style.css              — lock screen: Macchiato, clock, pill entry
```

### Adding a new theme

1. Add `themes/<name>-palette.css` with `@define-color` overrides
2. Add `themes/<name>-waybar.css` (or reuse `macchiato-waybar.css` if structure matches)
3. Update `waybar/style.css` imports
4. Add matching swaync and gtklock CSS
5. Update `90-theme.conf` color variables

The theme switcher (future) will automate steps 3–5.

---

## Sway Keybindings (base)

| Binding | Action |
|---|---|
| `$mod+Return` | Terminal (kitty) |
| `$mod+Shift+Return` | Floating terminal |
| `$mod+d` | App launcher (wofi) |
| `$mod+q` | Kill window |
| `$mod+m` | Fullscreen |
| `$mod+Ctrl+l` | Lock (gtklock) |
| `$mod+Shift+n` | Toggle notification center |
| `$mod+Shift+b` | Restart waybar |
| `$mod+Shift+c` | Reload sway config |
| `$mod+r` | Resize mode |
| `$mod+F5` | Toggle layout (tabbed / splith) |
| `Print` | Screenshot → ~/Pictures/ |
| `$mod+Print` | Region screenshot |

---

## Build Workflow

```bash
# One-time: generate GPG signing key
bash setup-gpg.sh

# Build a single package
cd packaging/paperweight-skel
dpkg-buildpackage -us -uc -b

# Build + sign + publish all packages to gh-pages apt repo
bash publish.sh
```

GitHub Pages must be enabled on the repo (Settings → Pages → gh-pages branch, root).

Users add the repo with:
```bash
wget -O - https://jalexlong.github.io/paperweight-os/pubkey.gpg \
  | sudo tee /etc/apt/trusted.gpg.d/paperweight.gpg
echo "deb https://jalexlong.github.io/paperweight-os trixie main" \
  | sudo tee /etc/apt/sources.list.d/paperweight.list
sudo apt update && sudo apt install paperweight-desktop
```

---

## Known Issues / Watchpoints

- **Nerd Font**: `fonts-jetbrains-mono` (Debian package) is NOT the Nerd Font variant.
  Waybar and terminal icons require JetBrainsMono Nerd Font. This needs to be
  packaged separately or installed via another source. Without it, icon glyphs
  show as blank boxes. **This is the #1 blocking issue for a working install.**

- **Wallpaper**: `sway/config` references `/usr/share/paperweight-os/wallpapers/default.jpg`.
  This path doesn't exist yet — needs a `paperweight-wallpapers` package.
  Until then, sway falls back to a solid color background.

- **brightnessctl**: Requires user to be in the `video` group, or a udev rule must
  grant access. Add a postinst script to `paperweight-skel` or document in setup.

- **gtklock in Trixie**: Confirm `apt-cache show gtklock` before building the
  final package. If unavailable, fall back to swaylock with the Macchiato config
  from `.dotfiles/chromebook/.config/swaylock/config`.

- **paperweight-chromebook package**: Stubbed in `paperweight-desktop` control file
  but not yet built as its own source package. Configs to pull from
  `.dotfiles` `chromebook-optimizations` branch: `20-keys.conf`, `40-workspaces.conf`,
  and a chromebook-specific output fragment.

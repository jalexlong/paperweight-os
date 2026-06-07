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
│   ├── paperweight-fonts/       # JetBrains Mono Nerd Font + Symbols NF
│   └── paperweight-chromebook/  # Hardware add-on for Chromebook/coreboot
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
/etc/skel/.config/sway/config.d/20-keys.conf
/etc/skel/.config/sway/config.d/50-chromebook-output.conf
```

The base sway config ends with `include ~/.config/sway/config.d/*.conf`, so
user-local fragments also work without modifying the skel defaults.

---

## Design Decisions (settled — don't revisit without good reason)

| Decision | Choice | Why |
|---|---|---|
| Base distro | Debian Stable (Trixie) | Stability over features |
| Compositor | Sway (Wayland) | Lightweight, keyboard-driven |
| Display manager | greetd + gtkgreet | Wayland-native, GTK4, CSS-themed; same pattern as gtklock |
| Screen locker | gtklock | Better GTK CSS theming than swaylock |
| Notification daemon | sway-notification-center (swaync) | Notification center panel, more usable than mako |
| Browser | Firefox ESR | GTK3, first-class Wayland support, reliable |
| App launcher | wofi | Lightweight, Wayland-native |
| Terminal | foot | Lightweight, Wayland-native, no GPU required |
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
  40-workspaces.conf           — workspace assignments + app-launch keybinds
  50-desktop-session.conf      — exec swaync; xdg-user-dirs-update on start
  50-systemd-user.conf         — D-Bus / systemd user env import
  90-theme.conf                — Catppuccin Macchiato palette, output bg, float rules
waybar/
  config.jsonc                 — modules: cava+cpu+mem left, workspaces center, status right
  style.css                    — @import only; real styles in themes/
  themes/
    catppuccin-macchiato.css   — @define-color variables (the palette)
    macchiato-waybar.css       — actual module styles referencing those variables
cava/
  waybar-config                — cava visualizer: 10 bars, raw 8-bit output via pulse
swaync/
  config.json                  — notification center layout + widgets
  style.css                    — Macchiato-themed notification + panel CSS
wofi/style.css                 — launcher styles using @define-color variables
gtklock/style.css              — lock screen: Macchiato, clock, pill entry
foot/foot.ini                  — terminal: Macchiato colors, JetBrainsMono NF 11pt
.local/bin/
  cava-waybar                  — Python3: pipes cava frames → waybar JSON (Unicode blocks)
```

### Adding a new theme

Per-theme files live in four directories under `~/.config/`:

| File | Purpose |
|---|---|
| `sway/themes/<name>.conf` | `set $var #hex` color variables for sway |
| `waybar/themes/<name>-palette.css` | `@define-color` CSS variables for waybar |
| `waybar/themes/<name>-waybar.css` | waybar module styles (can reuse `macchiato-waybar.css` for Catppuccin variants) |
| `swaync/themes/<name>.css` | swaync notification + panel CSS |
| `gtklock/themes/<name>.css` | gtklock screen-locker CSS |

To add a theme:
1. Create the five files above under `packaging/paperweight-skel/etc/skel/`
2. Run `paperweight-theme <name>` to activate it

`~/.local/bin/paperweight-theme` handles activation: copies palette to
`sway/config.d/90-colors.conf`, writes `waybar/style.css` imports, copies
swaync/gtklock CSS, then reloads sway, waybar, and swaync.
`$mod+p` opens the wofi theme picker.

---

## Sway Keybindings

App-launch bindings (from `40-workspaces.conf`) switch to the workspace and open the app.
`$mod+Shift+key` opens the same app as a floating window.

| Binding | Action |
|---|---|
| `$mod+t` | Terminal (foot) → workspace 1 |
| `$mod+Return` | Terminal (foot) — alias |
| `$mod+Shift+Return` | Floating terminal |
| `$mod+b` | Browser (firefox-esr) → workspace 2 |
| `$mod+e` | Editor (helix) → workspace 3 |
| `$mod+s` | Music (ncspot) → workspace 4 |
| `$mod+c` | Chat (discord/vesktop) → workspace 5 |
| `$mod+g` | Games → workspace 6 |
| `$mod+f` | Files (thunar) |
| `$mod+d` | App launcher (wofi) |
| `$mod+q` | Kill window |
| `$mod+space` | Toggle floating |
| `$mod+m` | Fullscreen |
| `$mod+F5` | Toggle layout (tabbed / splith) |
| `$mod+Ctrl+l` | Lock (gtklock) |
| `$mod+Shift+r` | Reload sway config |
| `$mod+Shift+n` | Toggle notification center |
| `$mod+Ctrl+w` | Restart waybar |
| `$mod+r` | Resize mode |
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

- **paperweight-wallpapers**: No wallpaper package yet. `90-theme.conf` sets
  `output * bg $base solid_color` as a fallback. A future `paperweight-wallpapers`
  package will provide `/usr/share/paperweight-os/wallpapers/` and override this.

- **ncspot / helix in Trixie**: These are added to `paperweight-desktop` Depends
  but haven't been verified in the Trixie repos yet. Run `apt-cache show ncspot helix`
  before publishing. If absent, they need a separate source or removal from Depends.

- **Discord / Vesktop**: Not in Debian repos — must be installed manually as a `.deb`
  from discord.com/download or vencord.dev. The `$mod+Shift+c` floating variant uses
  a `sleep 2` hack to wait for the window before floating it; timing may need tuning
  on slow hardware.

- **existing users and `video` group**: The postinst patches `/etc/adduser.conf` so
  new users land in the `video` group for brightnessctl. Users who already exist at
  install time need a manual `usermod -aG video $USER`.

- **gtkgreet / cage flags (Trixie)**: The gtkgreet package in Trixie has no `-f`
  (fullscreen) flag and no `--no-session-selector`. Use `-l` (`--layer-shell`) for
  fullscreen without CSD decorations, and `-c sway` to pre-fill the session command.
  The session-selector combobox is never populated from `/usr/share/wayland-sessions/`
  in this build — it is hidden via CSS instead. The cage package has no `-r` (rootless)
  flag; use `cage -s` (VT switching only).

- **gtkgreet CSS**: GTK4 does not support `display: none`. To hide widgets use
  `opacity: 0`, `min-height: 0`, `max-height: 0`, `padding: 0`, `font-size: 0`.
  To override the Adwaita headerbar color you must use both `@define-color headerbar_bg_color`
  (named color override) AND `headerbar { background-color: ... }` — one alone is
  insufficient. The `start-greeter` script must explicitly export `GDK_BACKEND=wayland`
  and `XDG_RUNTIME_DIR` (systemd-logind does not create it for system users with UID < 1000).

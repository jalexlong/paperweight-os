# PaperweightOS — CLAUDE.md

## What This Is

A Debian Blend targeting resource-limited x86 laptops (any crappy laptop → usable dev machine).
Ships as metapackages + a personal apt repo; live-build ISO available (see `live-build/`).
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
│   ├── paperweight-wallpapers/  # Per-theme wallpaper art (JPG) + solid-color PNG fallback + picker
│   ├── paperweight-grub/        # Catppuccin Macchiato GRUB2 theme
│   ├── paperweight-plymouth/    # Catppuccin Macchiato Plymouth boot splash
│   ├── paperweight-chromebook/  # Hardware add-on for Chromebook/coreboot
│   ├── paperweight-secrets/     # Secrets manager glue: PAM wiring, gpg-agent, passmenu
│   ├── pam-gnupg/                # Upstream source build: PAM module (not in Debian)
│   └── pass-secret-service/      # Upstream source build: Secret Service over pass (not in Debian)
├── live-build/                  # live-build ISO config
│   ├── auto/                    # lb config/build/clean scripts
│   ├── config/
│   │   ├── hooks/normal/0100-install-preseed.hook.binary  # copies preseed/paperweight.cfg → binary/install/
│   │   ├── bootloaders/grub-pc/ # grub.cfg with lb template markers
│   │   └── package-lists/       # chroot package lists
│   ├── build.sh                 # full build helper: sudo lb clean --all && lb config && lb build
│   └── rebuild-preseed.sh       # fast preseed-only rebuild (clears binary_hooks stage, reruns lb binary)
├── apt-repo/
│   └── conf/                    # reprepro config (SignWith key must be set)
├── manual_publish.sh             # Manual/local-only: build all .debs → sign → push gh-pages
│                                 # (CI does this automatically on push to main — see below)
├── setup-gpg.sh                 # One-time GPG key generation
├── sync-skel.sh                 # Rsync skel configs to $HOME for live-editing without a package build
├── fastfetch-theme-gen.py       # Generate a fastfetch theme .jsonc from a sway theme's palette
├── test-paperweight-theme.sh    # Headless paperweight-theme test harness (no Sway session needed)
└── CLAUDE.md                    # This file
```

### How packages relate

```
paperweight-desktop
  └── Depends: paperweight-skel + sway stack + fonts + tools
  └── Recommends: paperweight-grub, paperweight-plymouth, paperweight-secrets

paperweight-grub        (recommended, installed by default)
  └── Catppuccin Macchiato GRUB2 theme; sets GRUB_THEME in /etc/default/grub

paperweight-plymouth    (recommended, installed by default)
  └── Catppuccin Macchiato Plymouth splash; sets default theme + rebuilds initramfs

paperweight-chromebook  (optional add-on)
  └── Depends: paperweight-desktop + Chromebook-specific packages
  └── postinst sets GRUB_GFXMODE=1366x768,auto + GRUB_GFXPAYLOAD_LINUX=keep

paperweight-secrets     (recommended, installed by default)
  └── Depends: paperweight-skel, pass, pam-gnupg, pass-secret-service, pinentry-gtk2
  └── postinst patches /etc/pam.d/greetd + /etc/pam.d/gtklock to preset the
      gpg-agent passphrase cache at login/unlock using pam_gnupg.so; ships
      ~/.gnupg/gpg-agent.conf default, a $mod+p passmenu wofi picker, and
      paperweight-secrets-init(1) for guided first-run setup (never generates
      GPG key material itself — that's left to the user's own
      `gpg --full-generate-key`)
  └── CLI pass(1) entries and D-Bus/app-created secrets are two separate
      namespaces (pass-secret-service only scans what it created, once, at
      startup — see its pass_store.py). paperweight-secrets-sync bridges
      CLI → apps by mirroring pass(1) entries into pass-secret-service's
      store as symlinks (readable Label via a synthesized .properties
      sidecar), then restarts the D-Bus service; paperweight-passmenu
      already bridges apps → CLI by showing D-Bus-created secrets under
      their real Label instead of the internal id, no sync needed for that
      direction

pam-gnupg / pass-secret-service   (upstream source builds, not in Debian Trixie)
  └── pam-gnupg: autotools C build of github.com/cruegge/pam-gnupg v0.4
  └── pass-secret-service: pybuild of github.com/mdellweg/pass_secret_service
      (git snapshot — upstream has no tagged releases); implements
      org.freedesktop.secrets over D-Bus, backed by pass; auto-started via
      D-Bus session-bus activation, no exec line needed in sway config.d
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
| Display manager | greetd + gtkgreet | Wayland-native, GTK4, CSS-themed |
| Screen locker | gtklock | Better GTK CSS theming than swaylock; links GTK3, not GTK4 like gtkgreet — its CSS isn't subject to the GTK4 restrictions noted below |
| Notification daemon | sway-notification-center (swaync) | Notification center panel, more usable than mako |
| Browser | Firefox ESR | GTK3, first-class Wayland support, reliable |
| App launcher | wofi | Lightweight, Wayland-native |
| Terminal | foot | Lightweight, Wayland-native, no GPU required |
| Audio | PipeWire + pipewire-pulse + WirePlumber | Modern stack, PulseAudio compat |
| Default theme | Catppuccin Macchiato | First theme; more + theme switcher planned |
| Font | JetBrains Mono Nerd Font | Monospace + icons in one font |
| Distribution model | Debian Blend (metapackages + apt repo) | ISO via live-build/ (hybrid ISO, installs paperweight-desktop via late_command) |
| Config target | General x86 laptop | Chromebook = optional module, not the default |
| Distro version | Major.minor (e.g. `0.1`), bumped manually at milestones | Independent of per-package `.deb` versions — mirrors Debian's own release-vs-package version split (Debian "13" vs. each package's own version); not date-based (rejected Ubuntu-style `YY.MM`) |

---

## Skel Config Structure

Files shipped in `paperweight-skel` land in `/etc/skel/` and `/etc/skel/.config/`
and are copied to new user home dirs automatically by `adduser`.

**Important:** every file must be listed in `packaging/paperweight-skel/debian/install`
or `dh_install` will silently omit it from the built `.deb`.

```
.bashrc                        — color prompt + grep/ls aliases enabled (force_color_prompt=yes)
sway/config                    — base keybindings, bar, includes
sway/config.d/
  10-input.conf                — generic touchpad + keyboard tuning (repeat_delay 500, repeat_rate 35)
  30-idle.conf                 — swayidle → gtklock (750s lock, 900s display off)
  40-workspaces.conf           — workspace assignments + app-launch keybinds
  50-desktop-session.conf      — exec swaync; xdg-user-dirs-update on start
  50-systemd-user.conf         — D-Bus / systemd user env import
  90-theme.conf                — Catppuccin Macchiato palette, output bg, float rules
waybar/
  config.jsonc                 — modules: cava+cpu+mem left, workspaces center, status right;
                                  launcher is an `image#launcher` module (not `custom/`) since it
                                  shows the PaperweightOS rock logo, not a Nerd Font glyph — the
                                  image module's "path" key doesn't expand $HOME/~, so it uses
                                  "exec": "echo $HOME/..." instead, which does run through a shell
  paperweight-logo.png          — rock.png, 20px in the bar (fastfetch uses inline ASCII art
                                  instead, not this asset — see fastfetch/ below)
  style.css                    — @import only; real styles in themes/
  themes/
    macchiato-palette.css      — @define-color variables (the palette)
    macchiato-waybar.css       — actual module styles referencing those variables; launcher pill
                                  selector is `#launcher` (CSS id waybar assigns to `image#launcher`
                                  isn't documented, so the stylesheet also matches `#image.launcher`
                                  and `image#launcher` to be safe)
cava/
  waybar-config                — cava visualizer: 10 bars, raw 8-bit output via pulse
swaync/
  config.json                  — notification center layout + widgets
  style.css                    — Macchiato-themed notification + panel CSS
wofi/style.css                 — launcher styles using @define-color variables
gtklock/style.css              — lock screen: Macchiato, clock, pill entry, branded wallpaper
                                  (background-image, hardcoded per theme — see THEME-AUTHORING.md).
                                  gtklock links GTK3, not GTK4, so none of the gtkgreet GTK4
                                  CSS quirks below apply to it.
foot/foot.ini                  — terminal: JetBrainsMono NF 11pt; includes colors.ini then
                                  overrides alpha=0.88 + background=crust in a [colors] block
foot/colors.ini                — active theme's 16 ANSI colors + foreground (written by paperweight-theme)
foot/themes/<name>.ini         — per-theme color files; background = that theme's crust color
wlogout/
  layout                       — static button list (lock/logout/suspend/reboot/shutdown);
                                  Nerd Font glyph baked into each entry's "text" field
  style.css                    — active theme (Macchiato, Mocha, Latte, or Frappé)
  themes/<name>.css            — per-theme button styles, written by paperweight-theme
fastfetch/
  config.jsonc                  — active theme (Macchiato, Mocha, Latte, or Frappé), written by
                                   paperweight-theme; minimalist pfetch-style system info (`ff`
                                   alias): ~10 fields incl. LAN IPv4/battery, no colon separator
  themes/<name>.jsonc            — per-theme text colors + module list, generated by
                                   fastfetch-theme-gen.py (repo root) from the sway palette; logo
                                   is inline ASCII art (fastfetch's "data" logo type), not a
                                   rendered image, two-toned via $1/$2 placeholders — lavender for
                                   light facets, same hue darkened for dark facets/outline (see
                                   THEME-AUTHORING.md §9); theme-agnostic art, per-theme color
.local/bin/
  cava-waybar                  — Python3: pipes cava frames → waybar JSON (Unicode blocks)
```

### Adding a new theme

See **[THEME-AUTHORING.md](THEME-AUTHORING.md)** for the full guide.

Quick reference — nine files required per theme (all under
`packaging/paperweight-skel/etc/skel/.config/`):

| File | Format | Purpose |
|---|---|---|
| `sway/themes/<name>.conf` | `set $var #hex` | sway color variables |
| `waybar/themes/<name>-palette.css` | `@define-color` | waybar CSS palette |
| `waybar/themes/<name>-waybar.css` | CSS | waybar module styles |
| `swaync/themes/<name>.css` | CSS (hardcoded hex) | notification center |
| `gtklock/themes/<name>.css` | CSS (hardcoded hex) | screen locker |
| `wofi/themes/<name>.css` | `@define-color` + CSS | app launcher |
| `foot/themes/<name>.ini` | `[colors]` hex (no `#`) | terminal palette |
| `wlogout/themes/<name>.css` | `@define-color` + CSS | power/session dialog |
| `fastfetch/themes/<name>.jsonc` | JSONC, ANSI SGR colors | `ff` system info |

Also add `etc/greetd/themes/<name>.css` for the gtkgreet login screen.
`debian/install` uses directory globs — no manifest changes needed.
`$mod+t` opens the wofi theme picker.

`paperweight-set-greeter-theme` (called by `paperweight-theme` when the user
is in the `sudo` group) also resolves the theme's wallpaper and appends a
`window { background-image: ... }` rule straight into `/etc/greetd/gtkgreet.css`
— *not* gtkgreet's own `-b`/`--background` flag, which gtkgreet-1(1) itself
documents as anchoring the image to the upper-left corner at 1:1 and not
handling DPI scaling correctly (crops into the corner, hiding centered
artwork like the wordmark, on any scaled display). See THEME-AUTHORING.md's
Wallpaper section for the full priority order and why it differs from the
desktop's.

The fastfetch theme's colors must be ANSI SGR strings, not hex — generate
it with `./fastfetch-theme-gen.py <name>` (repo root) instead of hand-editing;
it derives the palette from the sway theme file. See THEME-AUTHORING.md §9.

---

## Sway Keybindings

App-launch bindings (from `40-workspaces.conf`) switch to the workspace and open the app.

| Binding | Action |
|---|---|
| `$mod+Return` | Terminal (foot) — workspace 1 |
| `$mod+Shift+Return` | Floating terminal |
| `$mod+b` | Browser ($browser) → workspace 2 |
| `$mod+d` | Chat ($chat) → workspace 3 |
| `$mod+s` | Toggle layout (tabbed / splith) |
| `$mod+f` | Files (thunar) |
| `$mod+space` | App launcher (wofi) |
| `$mod+t` | Theme picker (paperweight-theme) |
| `$mod+n` | Network picker (paperweight-network) |
| `$mod+p` | Password picker (paperweight-passmenu) — copies to clipboard, clears in 45s |
| `$mod+q` | Kill window |
| `$mod+g` | Toggle floating / tiled |
| `$mod+m` | Fullscreen |
| `$mod+Ctrl+l` | Lock (gtklock) |
| `$mod+Shift+r` | Reload sway config |
| `$mod+Shift+n` | Toggle notification center |
| `$mod+Ctrl+w` | Restart waybar |
| `$mod+r` | Resize mode |
| `$mod+Shift+q` | Exit sway (confirmation dialog) |
| `Ctrl+Alt+Delete` / `Ctrl+Alt+BackSpace` | Power menu (wlogout) — lock/logout/suspend/restart/shutdown (BackSpace binding covers Chromebook keyboards, which lack a Delete key) |
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

# Build + sign + publish all packages to gh-pages apt repo — CI
# (.github/workflows/build-and-publish.yml) does this automatically on
# every push to main. Only run this yourself for a manual/local publish.
bash manual_publish.sh
```

GitHub Pages must be enabled on the repo (Settings → Pages → gh-pages branch, root).

### live-build ISO

Requires Debian's `live-build` (not Ubuntu's ancient 3.x fork). Must run as root.

```bash
# Full build from repo root (15-30 min, requires internet)
bash live-build/build.sh
# Output: live-build/live-image-amd64.hybrid.iso (~2 GB hybrid ISO)

# After editing preseed/paperweight.cfg only (fast, ~2 min, uses cached chroot):
bash live-build/rebuild-preseed.sh

# Test in QEMU (virtio-vga required for KMS/Wayland)
qemu-system-x86_64 -m 2G -enable-kvm \
  -cdrom live-build/live-image-amd64.hybrid.iso -boot d \
  -device virtio-vga -display gtk,gl=on
```

**Preseed delivery:** `preseed/paperweight.cfg` is placed into the ISO at
`install/preseed.cfg` by a binary hook (`config/hooks/normal/0100-install-preseed.hook.binary`).
Do NOT put installer preseeds in `config/preseed/` — lb's `chroot_preseed` stage
processes that directory as debconf input and fails on d-i-owned questions.

**Preseed-only rebuild:** `rebuild-preseed.sh` clears the `binary_hooks`,
`binary_checksums`, and `binary_iso` stage files and reruns `lb binary`.
No chroot rebuild needed. Requires a prior full build.

CI: trigger manually via `Actions → Build ISO → Run workflow`, or push a `v*` tag.
ISO artifacts are uploaded to GitHub Releases on tags, or as build artifacts (14-day retention) on manual trigger.

**live-build working directories** (`binary/`, `chroot/`, `cache/`) are gitignored —
they are large and can be regenerated. Never commit them.

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

- **`/etc/os-release` rebranding**: `paperweight-skel`'s postinst patches
  `PRETTY_NAME`/`NAME`/`VERSION`/`VERSION_ID`/`HOME_URL`/`SUPPORT_URL`/
  `BUG_REPORT_URL` (and adds `ID_LIKE=debian`) in place, since `/etc/os-release`
  is owned by the Essential `base-files` package and can't be shipped directly
  without conflicting with it. `ID` is deliberately left as `debian` — changing
  it risks breaking tooling that keys off an exact `ID=debian` match (package-
  manager detection, VS Code remote-SSH, hardware/driver scripts), which isn't
  worth the identity purity for this project. `VERSION_CODENAME` and
  `DEBIAN_VERSION_FULL` are left untouched too — still genuinely Debian Trixie
  underneath. Because this edits a `base-files` conffile outside its owning
  package, a future `base-files` upgrade may prompt to keep local vs.
  maintainer changes — expected, not a bug. The sed patch is idempotent.

- **ncspot**: Not in Debian Trixie repos — shipped in the paperweight apt repo and
  included in `paperweight-desktop` Depends. Spotify Premium required for playback.

- **yazi**: Not in Debian Trixie repos — shipped in the paperweight apt repo and
  included in `paperweight-desktop` Depends. Provides a TUI file manager alongside
  Thunar.

- **Vesktop**: Available via the paperweight apt repo; included in
  `paperweight-desktop` Recommends. A `/usr/bin/discord` symlink points to it.
  Workspace 3 is bound to `$mod+d`.

- **existing users and `video` group**: The postinst patches `/etc/adduser.conf` so
  new users land in the `video` group for brightnessctl. Users who already exist at
  install time need a manual `usermod -aG video $USER`.

- **gtkgreet / cage flags (Trixie)**: The gtkgreet package in Trixie has no `-f`
  (fullscreen) flag and no `--no-session-selector`. Use `-l` (`--layer-shell`) for
  fullscreen without CSD decorations, and `-c sway` to pre-fill the session command.
  The session-selector combobox is never populated from `/usr/share/wayland-sessions/`
  in this build — it is hidden via CSS instead. The cage package has no `-r` (rootless)
  flag; use `cage -s` (VT switching only).

- **gtkgreet CSS**: GTK4 does not support `display: none`, `max-height`, or unitless
  `font-size: 0`. Any invalid property causes GTK4 to reject the **entire** stylesheet
  and fall back to Adwaita light — there is no partial application. To hide widgets use
  `opacity: 0`, `min-height: 0`, `padding: 0`, `margin: 0` only.
  To override the Adwaita headerbar color you must use both `@define-color headerbar_bg_color`
  (named color override) AND `headerbar { background-color: ... }` — one alone is
  insufficient. The `start-greeter` script must explicitly export `GDK_BACKEND=wayland`
  and `XDG_RUNTIME_DIR` (systemd-logind does not create it for system users with UID < 1000).
  Debug CSS errors with: `GTK_DEBUG=all G_MESSAGES_DEBUG=all gtkgreet -c sway -s /etc/greetd/gtkgreet.css 2>&1`

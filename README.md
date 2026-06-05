# PaperweightOS

A Debian Blend for turning resource-limited x86 laptops into polished,
keyboard-driven development machines.

Built on Debian Stable (Trixie) with Sway, Waybar, and a Catppuccin Macchiato
theme throughout. Ships as installable `.deb` packages via a personal apt repo —
no custom ISO required.

> First target hardware: Dell Chromebook 11 running coreboot.
> Works on any x86 laptop with a standard Debian install underneath.

---

## What's Included

Installing `paperweight-desktop` pulls in:

- **Sway** — tiling Wayland compositor
- **Waybar** — status bar (cpu/mem, workspaces, battery, network, notifications)
- **sway-notification-center** — notification daemon with slide-out panel
- **gtklock** — GTK-themed screen locker
- **wofi** — app launcher
- **kitty** — GPU-accelerated terminal
- **PipeWire** — audio stack with PulseAudio compatibility
- **JetBrains Mono Nerd Font** — monospace font with full icon glyph support
- **mosh, tmux, neovim, btop, zoxide** — developer tooling
- **grim, slurp** — Wayland screenshot tools

Default configs land in `/etc/skel/.config/` via `paperweight-skel` and are
copied to new user home directories automatically.

---

## Add the apt Repository

```bash
curl https://jalexlong.github.io/paperweight-os/pubkey.gpg \
  | sudo tee /etc/apt/trusted.gpg.d/paperweight.gpg

echo "deb https://jalexlong.github.io/paperweight-os trixie main" \
  | sudo tee /etc/apt/sources.list.d/paperweight.list

sudo apt update
```

## Install

```bash
# Full desktop environment
sudo apt install paperweight-desktop

# Chromebook / coreboot hardware add-on (F-key mappings, hardware quirks)
sudo apt install paperweight-chromebook
```

---

## Key Bindings

| Binding | Action |
|---|---|
| `Super+Return` | Terminal (kitty) |
| `Super+Shift+Return` | Floating terminal |
| `Super+d` | App launcher (wofi) |
| `Super+q` | Close window |
| `Super+m` | Fullscreen |
| `Super+Shift+L` | Lock screen |
| `Super+Shift+N` | Toggle notification center |
| `Super+Shift+B` | Restart waybar |
| `Super+r` | Resize mode |
| `Print` | Screenshot → ~/Pictures/ |
| `Super+Print` | Region screenshot |

---

## Packages

| Package | Description |
|---|---|
| `paperweight-skel` | Default configs installed to `/etc/skel/` |
| `paperweight-desktop` | Metapackage: pulls in the full desktop stack |
| `paperweight-fonts` | JetBrains Mono Nerd Font + Symbols Nerd Font |
| `paperweight-chromebook` | *(coming soon)* Chromebook/coreboot hardware support |

---

## Building from Source

```bash
sudo apt install devscripts debhelper build-essential

# Build a single package
cd packaging/paperweight-skel
dpkg-buildpackage -us -uc -b

# Build, sign, and publish all packages to the apt repo
bash setup-gpg.sh   # one-time: generates your GPG signing key
bash publish.sh
```

---

## License

MIT — see [LICENSE](LICENSE).

Fonts in `packaging/paperweight-fonts/` are licensed under the
[SIL Open Font License 1.1](https://openfontlicense.org).

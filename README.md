# PaperweightOS

A Debian Blend for turning resource-limited x86 laptops into polished,
keyboard-driven development machines.

Built on Debian Stable (Trixie) with Sway, Waybar, and a Catppuccin Macchiato
theme throughout. Ships as installable `.deb` packages via a personal apt repo —
no custom ISO required.

> First target hardware: Dell Chromebook 11 3180 running coreboot.
> Works on any x86 laptop with a standard Debian install underneath.

---

## What's Included

Installing `paperweight-desktop` pulls in:

**Desktop**
- **Sway** — tiling Wayland compositor
- **Waybar** — status bar: CPU/memory, audio visualizer, workspace icons, battery, clock
- **sway-notification-center** — notification daemon with slide-out panel
- **gtklock** — GTK-themed screen locker
- **wofi** — app launcher
- **foot** — lightweight Wayland-native terminal
- **Firefox ESR** — browser with first-class Wayland support
- **Thunar** — file manager
- **PipeWire** — audio stack with PulseAudio compatibility

**Media**
- **cava** — audio visualizer (integrated into waybar)
- **ncspot** — lightweight TUI Spotify client (requires Premium) — *not in Trixie; install via `cargo install ncspot`*
- **playerctl** — media key control

**Development**
- **Helix** — modern modal text editor with built-in LSP and tree-sitter
- **Neovim, Vim** — terminal editors
- **tmux, mosh, btop, zoxide** — terminal multiplexer, SSH, process monitor, smart cd
- **git, curl, wget, ca-certificates** — essentials

**Fonts & Theme**
- **JetBrains Mono Nerd Font** — monospace font with full icon glyph support
- **Catppuccin Macchiato** — consistent dark theme across all components

Default configs land in `/etc/skel/.config/` via `paperweight-skel` and are
copied to new user home directories automatically.

### Manual installs (not in Debian repos)

These can't be pulled in via apt and need to be installed separately:

- **Vesktop** (recommended) — open-source Discord client with better Wayland support; `.deb` available at [vencord.dev/download](https://vencord.dev/download)
- **Discord** — official `.deb` at [discord.com/download](https://discord.com/download)

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

# Dell Chromebook 11 3180 hardware add-on
# Configures top-row keys and internal display
sudo apt install paperweight-chromebook
```

---

## Key Bindings

### App launch — switch to workspace and open app

| Binding | Action |
|---|---|
| `Super+t` | Terminal (foot) — workspace 1 |
| `Super+b` | Browser (Firefox) — workspace 2 |
| `Super+e` | Editor (Helix) — workspace 3 |
| `Super+s` | Music (ncspot) — workspace 4 — *ncspot must be installed manually* |
| `Super+c` | Chat (Discord/Vesktop) — workspace 5 |
| `Super+g` | Games — workspace 6 |
| `Super+f` | Files (Thunar) |
| `Super+d` | App launcher (wofi) |
| `Super+Return` | Terminal (alias) |

Add `Shift` to open as a floating window instead: `Super+Shift+t`, `Super+Shift+b`, etc.

### Window management

| Binding | Action |
|---|---|
| `Super+q` | Close window |
| `Super+Space` | Toggle floating |
| `Super+m` | Fullscreen |
| `Super+F5` | Toggle layout (tabbed / split) |
| `Super+r` | Resize mode |
| `Super+h/j/k/l` | Focus left/down/up/right |
| `Super+Shift+h/j/k/l` | Move window |
| `Super+1–0` | Switch workspace |
| `Super+Shift+1–0` | Move window to workspace |
| `Super+minus` | Show scratchpad |
| `Super+Shift+minus` | Send to scratchpad |

### Session & utilities

| Binding | Action |
|---|---|
| `Super+Ctrl+L` | Lock screen (gtklock) |
| `Super+Shift+R` | Reload sway config |
| `Super+Ctrl+W` | Restart waybar |
| `Super+p` | Theme picker (wofi) |
| `Super+Shift+N` | Toggle notification center |
| `Super+Shift+Q` | Exit sway |
| `Print` | Screenshot → ~/Pictures/ |
| `Super+Print` | Region screenshot |

### Media keys

Standard `XF86` brightness and volume keys are bound globally (work from the
lock screen). On the Chromebook, the top-row keys send these by default;
`Super+top-row` sends the literal F1–F10.

---

## Packages

| Package | Version | Description |
|---|---|---|
| `paperweight-skel` | 0.2.3 | Default configs installed to `/etc/skel/` |
| `paperweight-desktop` | — | Metapackage: pulls in the full desktop stack |
| `paperweight-fonts` | — | JetBrains Mono Nerd Font + Symbols Nerd Font |
| `paperweight-chromebook` | 0.1.0 | Dell Chromebook 11 3180 hardware support |

---

## Building from Source

```bash
sudo apt install devscripts debhelper build-essential reprepro

# Build a single package
cd packaging/paperweight-skel
dpkg-buildpackage -us -uc -b

# Build, sign, and publish all packages to the apt repo
bash setup-gpg.sh   # one-time: generate your GPG signing key
bash publish.sh
```

---

## License

MIT — see [LICENSE](LICENSE).

Fonts in `packaging/paperweight-fonts/` are licensed under the
[SIL Open Font License 1.1](https://openfontlicense.org).

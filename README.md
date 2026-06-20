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
- **greetd + gtkgreet** — minimal Wayland login manager with GTK4 greeter; themed to match the active Catppuccin variant
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
- **cmus** — lightweight TUI music player for local audio files
- **ncspot** — TUI Spotify client (Spotify Premium required)
- **playerctl** — media key control

**Chat**
- **Vesktop** — Discord client with Vencord modifications and improved Wayland support; workspace 4 (`Super+d`). Also symlinked as `/usr/bin/discord`

**Development**
- **Helix, Neovim, Vim** — terminal editors
- **yazi** — fast TUI file manager (alongside Thunar for GUI)
- **tmux, mosh, btop, zoxide** — terminal multiplexer, SSH, process monitor, smart cd
- **git, curl, wget, ca-certificates** — essentials

**Fonts & Theme**
- **JetBrains Mono Nerd Font** — monospace font with full icon glyph support
- **Catppuccin themes** — all four variants (Latte, Frappé, Macchiato, Mocha); switch with `Super+t` or `paperweight-theme <name>`

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

# Dell Chromebook 11 3180 hardware add-on
# Configures top-row keys and internal display
sudo apt install paperweight-chromebook
```

Reboot after install. greetd starts automatically; log in and sway launches.

See [HARDWARE.md](HARDWARE.md) for the hardware compatibility matrix, known
issues on generic x86 laptops, and instructions for adding support for new
hardware targets.

---

## First Boot

### Brightness keys

`brightnessctl` requires membership in the `video` group. The postinst adds
this for users created *after* install via `adduser`. If your account existed
before installing `paperweight-desktop`, add yourself manually:

```bash
sudo usermod -aG video $USER
```

Log out and back in (or reboot) for the group change to take effect. Until
then `XF86MonBrightnessUp/Down` will silently do nothing.

### Switching themes

Four Catppuccin variants ship out of the box. Switch with the wofi picker
(`Super+t`) or from a terminal:

```bash
paperweight-theme macchiato   # default
paperweight-theme latte       # light
paperweight-theme frappe
paperweight-theme mocha
```

The active theme is remembered across reboots in
`~/.config/paperweight-os/active-theme`.

Switching themes automatically updates the GRUB boot menu to match — no
password prompt, takes effect on next boot.

To switch the GRUB theme independently (e.g. after a manual install):

```bash
sudo paperweight-grub-theme macchiato   # default
sudo paperweight-grub-theme latte
sudo paperweight-grub-theme frappe
sudo paperweight-grub-theme mocha
```

### Music

`cmus` (local audio) and `ncspot` (Spotify TUI) are both installed. Launch either
from a terminal (`Super+Return`). For cmus, press `5` on first launch to open the
file browser and add your library. ncspot requires a Spotify Premium account.

### Discord / Vesktop

Vesktop is included in `paperweight-desktop` (as a Recommended package) and ships
in the paperweight apt repo. `Super+d` launches it on workspace 4 automatically.

---

## Key Bindings

### App launch

| Binding | Action |
|---|---|
| `Super+Return` | Terminal (foot) — workspace 1 |
| `Super+Shift+Return` | Floating terminal |
| `Super+b` | Browser (Firefox ESR) — workspace 2 |
| `Super+d` | Chat (Vesktop) — workspace 4 |
| `Super+f` | Files (Thunar) |
| `Super+Space` | App launcher (wofi) |

Music (workspace 3) is terminal-launched — `Super+3`, open a terminal, run `ncspot` or `cmus`.

### Layout

| Binding | Action |
|---|---|
| `Super+s` | Toggle layout (tabbed / split) |
| `Super+1–0` | Switch workspace |
| `Super+Shift+1–0` | Move window to workspace |

### Window management

| Binding | Action |
|---|---|
| `Super+q` | Close window |
| `Super+g` | Toggle floating / tiled |
| `Super+Shift+Space` | Toggle focus between floating/tiled |
| `Super+m` | Fullscreen |
| `Super+r` | Resize mode |
| `Super+h/j/k/l` | Focus left/down/up/right |
| `Super+Shift+h/j/k/l` | Move window left/down/up/right |
| `Super+minus` | Show scratchpad |
| `Super+Shift+minus` | Send to scratchpad |

### Session & utilities

| Binding | Action |
|---|---|
| `Super+Ctrl+L` | Lock screen (gtklock) |
| `Super+Shift+R` | Reload sway config |
| `Super+Shift+Q` | Exit sway |
| `Super+Ctrl+W` | Restart waybar |
| `Super+t` | Theme picker |
| `Super+n` | Wi-Fi network picker |
| `Super+Shift+N` | Toggle notification center |
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
| `paperweight-desktop` | 0.1.12 | Metapackage: pulls in the full desktop stack |
| `paperweight-skel` | 0.2.57 | Default configs installed to `/etc/skel/` |
| `paperweight-fonts` | 0.1.1 | JetBrains Mono Nerd Font + Symbols Nerd Font |
| `paperweight-grub` | 0.1.7 | Catppuccin GRUB2 theme — all four variants |
| `paperweight-plymouth` | 0.1.7 | Catppuccin Plymouth boot splash — all four variants |
| `paperweight-chromebook` | 0.1.12 | Dell Chromebook 11 hardware support |
| `ncspot` | 1.3.4 | TUI Spotify client (upstream binary repack) |
| `yazi` | 26.5.6 | Fast TUI file manager (upstream musl binary repack) |
| `vesktop` | 1.6.5 | Discord client with Vencord (upstream binary repack) |
| `paperweight-wallpapers` | 0.3.2 | Catppuccin wallpapers |

---

## Building from Source

```bash
sudo apt install devscripts debhelper build-essential grub-common reprepro

# Build a single package
cd packaging/paperweight-skel
dpkg-buildpackage -us -uc -b

# Build, sign, and publish all packages to the apt repo
bash setup-gpg.sh   # one-time: generate your GPG signing key
bash publish.sh
```

---

## Automated Install (Preseed)

`preseed/paperweight.cfg` automates a Debian Trixie install and bootstraps the desktop.

### Customize before use

Open `preseed/paperweight.cfg` and set these two things:

**1. Target disk** (line `partman-auto/disk`) — the file auto-detects the first
available disk, but verify it matches your hardware:

| Hardware | Device |
|---|---|
| SATA / NVMe laptop | `/dev/sda` or `/dev/nvme0n1` |
| Dell Chromebook 11 3180 (eMMC) | `/dev/mmcblk0` |
| libvirt VM (virtio) | `/dev/vda` |

**2. Locale and timezone:**
```
d-i debian-installer/locale string en_US.UTF-8
d-i keyboard-configuration/xkb-keymap select us
d-i time/zone string UTC
```

Username and password are entered interactively during install — no preseed changes needed.

### Run the install

Boot a [Debian Trixie netinstall ISO](https://www.debian.org/devel/debian-installer/)
and pass the preseed at the boot prompt.

**From USB stick** (place `preseed.cfg` in the root of the stick):
```
auto=true priority=critical file=/cdrom/preseed.cfg
```

**Over HTTP** (serve from another machine):
```
auto=true priority=critical url=http://<server-ip>:8080/preseed/paperweight.cfg
```

**virt-manager:** use the virbr0 gateway (`192.168.122.1` by default), not your
host's physical IP — the VM can't reach it through libvirt NAT:
```bash
# On host, from repo root:
python3 -m http.server 8080
# Boot parameter in the VM:
auto=true priority=critical url=http://192.168.122.1:8080/preseed/paperweight.cfg
```

The `late_command` adds the PaperweightOS apt repo and installs `paperweight-desktop`
inside the target system. After reboot, complete [First Boot](#first-boot) setup.

---

## License

MIT — see [LICENSE](LICENSE).

Fonts in `packaging/paperweight-fonts/` are licensed under the
[SIL Open Font License 1.1](https://openfontlicense.org).

#!/usr/bin/env bash
# Run this script from the root of your paperweight-os repo (or anywhere you
# want the packaging/ directory created). It scaffolds the full Debian source
# package tree for PaperweightOS.
set -euo pipefail

DEST="${1:-.}"
echo "Creating PaperweightOS packaging scaffold in: $DEST"

# ---------------------------------------------------------------------------
# Directory layout
# ---------------------------------------------------------------------------
mkdir -p "$DEST"/packaging/paperweight-desktop/debian
mkdir -p "$DEST"/packaging/paperweight-skel/debian
mkdir -p "$DEST"/packaging/paperweight-skel/etc/skel/.config/sway/config.d
mkdir -p "$DEST"/packaging/paperweight-skel/etc/skel/.config/waybar
mkdir -p "$DEST"/packaging/paperweight-skel/etc/skel/.config/mako
mkdir -p "$DEST"/packaging/paperweight-skel/etc/skel/.config/wofi

# ---------------------------------------------------------------------------
# packaging/README.md
# ---------------------------------------------------------------------------
cat > "$DEST"/packaging/README.md << 'HEREDOC'
# PaperweightOS Packaging

This directory contains Debian source packages for PaperweightOS.

## Package Overview

| Package | Purpose |
|---|---|
| `paperweight-desktop` | Metapackage — depends on the full desktop stack |
| `paperweight-skel` | Ships config files into `/etc/skel/` for new users |
| `paperweight-chromebook` | (planned) Chromebook hardware quirks |

## How Debian Packaging Works (Quick Primer)

A Debian source package is a directory containing a `debian/` subdirectory.
The key files inside `debian/` are:

- **`control`** — Package metadata and dependency list. The `Depends:` field is
  how `apt install paperweight-desktop` pulls in sway, waybar, etc. automatically.
- **`changelog`** — Required. Tracks versions. Use `dch` to add entries rather
  than editing by hand.
- **`rules`** — A Makefile that `dpkg-buildpackage` calls. The one-liner `dh $@`
  is all you need for simple packages; debhelper does the rest.
- **`compat`** — Declares which debhelper version you're targeting (13 for Trixie).
- **`copyright`** — Machine-readable license declaration.
- **`install`** — Used by `dh_install`: maps files in your source tree to their
  destination paths inside the package.

## Building a Package

Install build tools once:
```
sudo apt install devscripts debhelper build-essential
```

Build (run from inside the package directory, e.g. `paperweight-skel/`):
```
dpkg-buildpackage -us -uc -b
```
- `-us -uc` = unsigned source/changes (fine for local builds)
- `-b` = binary only (no source tarball)

The `.deb` lands one directory up. Install it:
```
sudo dpkg -i ../paperweight-skel_0.1.0-1_all.deb
```

Or use `debi` from devscripts, which does both steps:
```
debi
```

## Config Fragment Philosophy

Hardware-specific config lives in `config.d/` drop-in directories.
The base sway config ends with:
```
include ~/.config/sway/config.d/*.conf
```

A `paperweight-chromebook` package ships:
```
etc/skel/.config/sway/config.d/10-chromebook-input.conf
```
...and it gets picked up automatically — no patching of the base config needed.
Same model as `/etc/apt/apt.conf.d/`.
HEREDOC

# ---------------------------------------------------------------------------
# paperweight-desktop/debian/control
# ---------------------------------------------------------------------------
cat > "$DEST"/packaging/paperweight-desktop/debian/control << 'HEREDOC'
Source: paperweight-desktop
Section: metapackages
Priority: optional
Maintainer: Alex Long <johnalexanderlong@gmail.com>
Build-Depends: debhelper-compat (= 13)
Standards-Version: 4.6.2
Homepage: https://github.com/jalexlong/paperweight-os
Rules-Requires-Root: no

Package: paperweight-desktop
Architecture: all
Depends:
 paperweight-skel,
 sway,
 waybar,
 swaylock,
 swayidle,
 mako-notifier,
 wofi,
 kitty,
 grim,
 slurp,
 wl-clipboard,
 brightnessctl,
 playerctl,
 network-manager,
 fonts-jetbrains-mono,
 fonts-font-awesome,
 fonts-noto-color-emoji,
 git,
 curl,
 wget,
 vim,
 neovim,
 tmux,
 btop,
 zoxide,
 ca-certificates,
Description: PaperweightOS desktop environment metapackage
 Installs all packages required for the PaperweightOS Sway-based desktop
 environment on Debian Stable (Trixie). Intended for use on refurbished
 hardware with lightweight Wayland compositing.
 .
 Installing this package pulls in the full desktop stack. Configuration
 defaults are provided by the paperweight-skel package.

Package: paperweight-chromebook
Architecture: all
Depends:
 paperweight-desktop,
 brightnessctl,
 acpi,
 acpid,
Description: PaperweightOS extra dependencies for Chromebook hardware
 Optional add-on for machines running coreboot, providing Chromebook-specific
 keyboard mappings and power management quirks on top of the base desktop.
HEREDOC

# ---------------------------------------------------------------------------
# paperweight-desktop/debian/changelog
# ---------------------------------------------------------------------------
cat > "$DEST"/packaging/paperweight-desktop/debian/changelog << 'HEREDOC'
paperweight-desktop (0.1.0-1) trixie; urgency=low

  * Initial packaging. Metapackage for PaperweightOS Sway desktop stack.

 -- Alex Long <johnalexanderlong@gmail.com>  Wed, 04 Jun 2026 00:00:00 +0000
HEREDOC

# ---------------------------------------------------------------------------
# paperweight-desktop/debian/rules  (must be executable)
# ---------------------------------------------------------------------------
cat > "$DEST"/packaging/paperweight-desktop/debian/rules << 'HEREDOC'
#!/usr/bin/make -f
%:
	dh $@
HEREDOC
chmod +x "$DEST"/packaging/paperweight-desktop/debian/rules

# ---------------------------------------------------------------------------
# paperweight-desktop/debian/compat
# ---------------------------------------------------------------------------
echo "13" > "$DEST"/packaging/paperweight-desktop/debian/compat

# ---------------------------------------------------------------------------
# paperweight-desktop/debian/copyright
# ---------------------------------------------------------------------------
cat > "$DEST"/packaging/paperweight-desktop/debian/copyright << 'HEREDOC'
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: paperweight-desktop
Upstream-Contact: Alex Long <johnalexanderlong@gmail.com>
Source: https://github.com/jalexlong/paperweight-os

Files: *
Copyright: 2026 Alex Long <johnalexanderlong@gmail.com>
License: GPL-3.0-or-later

License: GPL-3.0-or-later
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 .
 On Debian systems, the complete text of the GNU General Public License
 version 3 can be found in /usr/share/common-licenses/GPL-3.
HEREDOC

# ---------------------------------------------------------------------------
# paperweight-skel/debian/control
# ---------------------------------------------------------------------------
cat > "$DEST"/packaging/paperweight-skel/debian/control << 'HEREDOC'
Source: paperweight-skel
Section: misc
Priority: optional
Maintainer: Alex Long <johnalexanderlong@gmail.com>
Build-Depends: debhelper-compat (= 13)
Standards-Version: 4.6.2
Homepage: https://github.com/jalexlong/paperweight-os
Rules-Requires-Root: no

Package: paperweight-skel
Architecture: all
Depends: ${misc:Depends}
Description: PaperweightOS default configuration skeleton
 Provides default XDG configuration files for the PaperweightOS desktop,
 installed to /etc/skel so they are copied into new user home directories
 at account creation time.
 .
 Includes base configs for: sway, waybar, mako, wofi, and kitty.
 Hardware-specific fragments (e.g. Chromebook keys) ship in separate packages
 and are dropped into config.d/ directories for fragment-based composition.
HEREDOC

# ---------------------------------------------------------------------------
# paperweight-skel/debian/changelog
# ---------------------------------------------------------------------------
cat > "$DEST"/packaging/paperweight-skel/debian/changelog << 'HEREDOC'
paperweight-skel (0.1.0-1) trixie; urgency=low

  * Initial packaging. Default config skeleton for PaperweightOS desktop.

 -- Alex Long <johnalexanderlong@gmail.com>  Wed, 04 Jun 2026 00:00:00 +0000
HEREDOC

# ---------------------------------------------------------------------------
# paperweight-skel/debian/rules  (must be executable)
# ---------------------------------------------------------------------------
cat > "$DEST"/packaging/paperweight-skel/debian/rules << 'HEREDOC'
#!/usr/bin/make -f
%:
	dh $@
HEREDOC
chmod +x "$DEST"/packaging/paperweight-skel/debian/rules

# ---------------------------------------------------------------------------
# paperweight-skel/debian/compat
# ---------------------------------------------------------------------------
echo "13" > "$DEST"/packaging/paperweight-skel/debian/compat

# ---------------------------------------------------------------------------
# paperweight-skel/debian/copyright
# ---------------------------------------------------------------------------
cat > "$DEST"/packaging/paperweight-skel/debian/copyright << 'HEREDOC'
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: paperweight-skel
Upstream-Contact: Alex Long <johnalexanderlong@gmail.com>
Source: https://github.com/jalexlong/paperweight-os

Files: *
Copyright: 2026 Alex Long <johnalexanderlong@gmail.com>
License: GPL-3.0-or-later

License: GPL-3.0-or-later
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 .
 On Debian systems, the complete text of the GNU General Public License
 version 3 can be found in /usr/share/common-licenses/GPL-3.
HEREDOC

# ---------------------------------------------------------------------------
# paperweight-skel/debian/install
# ---------------------------------------------------------------------------
cat > "$DEST"/packaging/paperweight-skel/debian/install << 'HEREDOC'
# Format: <source path relative to package root>  <destination in the .deb>
# dh_install uses this to place files during dpkg-buildpackage.

etc/skel/.config/sway/config                    etc/skel/.config/sway/
etc/skel/.config/sway/config.d/                 etc/skel/.config/sway/
etc/skel/.config/waybar/config.jsonc            etc/skel/.config/waybar/
etc/skel/.config/waybar/style.css               etc/skel/.config/waybar/
etc/skel/.config/mako/config                    etc/skel/.config/mako/
etc/skel/.config/wofi/style.css                 etc/skel/.config/wofi/
HEREDOC

# ---------------------------------------------------------------------------
# Config files (sourced from your dotfiles)
# ---------------------------------------------------------------------------

# sway/config
cat > "$DEST"/packaging/paperweight-skel/etc/skel/.config/sway/config << 'HEREDOC'
# Sway Config
# Read `man 5 sway` for a complete reference.

### Variables
set $mod Mod4
set $left h
set $down j
set $up k
set $right l
set $term kitty
set $menu wofi -S drun
set $files nemo
set $browser qutebrowser

gaps inner 5
gaps outer 5
default_border pixel 2

include /etc/sway/config-vars.d/*

### Output configuration
# output * bg /usr/share/backgrounds/sway/Sway_Wallpaper_Blue_1920x1080.png fill

### Idle configuration
#exec swayidle -w \
#         timeout 300 'swaylock -f -c 000000' \
#         timeout 600 'swaymsg "output * power off"' resume 'swaymsg "output * power on"' \
#         before-sleep 'swaylock -f -c 000000'

### Key bindings
    bindsym $mod+Return exec $term
    bindsym $mod+q kill
    bindsym $mod+d exec $menu
    bindsym $mod+e exec $files
    bindsym $mod+Shift+Return exec $browser
    floating_modifier $mod normal
    bindsym $mod+Shift+c reload
    bindsym $mod+Shift+q exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -B 'Yes, exit sway' 'swaymsg exit'

### Focus
    bindsym $mod+$left focus left
    bindsym $mod+$down focus down
    bindsym $mod+$up focus up
    bindsym $mod+$right focus right
    bindsym $mod+Left focus left
    bindsym $mod+Down focus down
    bindsym $mod+Up focus up
    bindsym $mod+Right focus right

### Move
    bindsym $mod+Shift+$left move left
    bindsym $mod+Shift+$down move down
    bindsym $mod+Shift+$up move up
    bindsym $mod+Shift+$right move right
    bindsym $mod+Shift+Left move left
    bindsym $mod+Shift+Down move down
    bindsym $mod+Shift+Up move up
    bindsym $mod+Shift+Right move right

### Workspaces
    bindsym $mod+1 workspace number 1
    bindsym $mod+2 workspace number 2
    bindsym $mod+3 workspace number 3
    bindsym $mod+4 workspace number 4
    bindsym $mod+5 workspace number 5
    bindsym $mod+6 workspace number 6
    bindsym $mod+7 workspace number 7
    bindsym $mod+8 workspace number 8
    bindsym $mod+9 workspace number 9
    bindsym $mod+0 workspace number 10
    bindsym $mod+Shift+1 move container to workspace number 1
    bindsym $mod+Shift+2 move container to workspace number 2
    bindsym $mod+Shift+3 move container to workspace number 3
    bindsym $mod+Shift+4 move container to workspace number 4
    bindsym $mod+Shift+5 move container to workspace number 5
    bindsym $mod+Shift+6 move container to workspace number 6
    bindsym $mod+Shift+7 move container to workspace number 7
    bindsym $mod+Shift+8 move container to workspace number 8
    bindsym $mod+Shift+9 move container to workspace number 9
    bindsym $mod+Shift+0 move container to workspace number 10

### Layout
    bindsym $mod+f fullscreen
    bindsym $mod+Shift+space floating toggle
    bindsym $mod+space focus mode_toggle

### Scratchpad
    bindsym $mod+Shift+minus move scratchpad
    bindsym $mod+minus scratchpad show

### Resize mode
mode "resize" {
    bindsym $left resize shrink width 10px
    bindsym $down resize grow height 10px
    bindsym $up resize shrink height 10px
    bindsym $right resize grow width 10px
    bindsym Left resize shrink width 10px
    bindsym Down resize grow height 10px
    bindsym Up resize shrink height 10px
    bindsym Right resize grow width 10px
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym $mod+r mode "resize"

### Media / brightness keys
    bindsym --locked XF86AudioMute exec wpctl set-mute @DEFAULT_SINK@ toggle
    bindsym --locked XF86AudioLowerVolume exec wpctl set-volume @DEFAULT_SINK@ 5%-
    bindsym --locked XF86AudioRaiseVolume exec wpctl set-volume @DEFAULT_SINK@ 5%+
    bindsym --locked XF86AudioMicMute exec wpctl set-mute @DEFAULT_SOURCE@ toggle
    bindsym --locked XF86MonBrightnessDown exec brightnessctl set 5%-
    bindsym --locked XF86MonBrightnessUp exec brightnessctl set 5%+
    bindsym Print exec grim
    bindsym --locked XF86SelectiveScreenshot exec grim -g "$(slurp)" -t png

### Bar
bar {
    swaybar_command waybar
}

include /etc/sway/config.d/*
include ~/.config/sway/config.d/*.conf
HEREDOC

# sway/config.d/50-desktop-session.conf
cat > "$DEST"/packaging/paperweight-skel/etc/skel/.config/sway/config.d/50-desktop-session.conf << 'HEREDOC'
# Generic Sway session services

exec_always waybar
exec mako
HEREDOC

# waybar/config.jsonc
cat > "$DEST"/packaging/paperweight-skel/etc/skel/.config/waybar/config.jsonc << 'HEREDOC'
// -*- mode: jsonc -*-
{
    "height": 30,
    "spacing": 4,
    "modules-left": [
        "sway/workspaces",
        "sway/mode",
        "sway/scratchpad"
    ],
    "modules-center": [
        "sway/window"
    ],
    "modules-right": [
        "mpd",
        "idle_inhibitor",
        "pulseaudio",
        "network",
        "power-profiles-daemon",
        "cpu",
        "memory",
        "keyboard-state",
        "backlight",
        "battery",
        "battery#bat2",
        "clock",
        "tray",
        "custom/power"
    ],
    "sway/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "warp-on-scroll": false,
        "format": "{name}: {icon}",
        "format-icons": {
            "1": "",
            "2": "",
            "3": "",
            "4": "",
            "5": "",
            "urgent": "",
            "focused": "",
            "default": ""
        }
    },
    "keyboard-state": {
        "numlock": true,
        "capslock": true,
        "format": "{name} {icon}",
        "format-icons": {
            "locked": "",
            "unlocked": ""
        }
    },
    "sway/mode": {
        "format": "<span style=\"italic\">{}</span>"
    },
    "sway/scratchpad": {
        "format": "{icon} {count}",
        "show-empty": false,
        "format-icons": ["", ""],
        "tooltip": true,
        "tooltip-format": "{app}: {title}"
    },
    "idle_inhibitor": {
        "format": "{icon}",
        "format-icons": {
            "activated": "",
            "deactivated": ""
        }
    },
    "tray": {
        "spacing": 10
    },
    "clock": {
        "timezone": "America/Chicago",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
        "format-alt": "{:%Y-%m-%d}"
    },
    "memory": {
        "format": "{}% "
    },
    "cpu": {
        "format": "{usage}% ",
        "tooltip": false
    },
    "temperature": {
        "critical-threshold": 80,
        "format": "{temperatureC}°C {icon}",
        "format-icons": ["", "", ""]
    },
    "backlight": {
        "format": "{percent}% {icon}",
        "format-icons": ["", "", "", "", "", "", "", "", ""]
    },
    "battery": {
        "states": {
            "good": 95,
            "warning": 30,
            "critical": 15
        },
        "format": "{capacity}% {icon}",
        "format-full": "{capacity}% {icon}",
        "format-charging": "{capacity}% ",
        "format-plugged": "{capacity}% ",
        "format-alt": "{time} {icon}",
        "format-icons": ["", "", "", "", ""]
    },
    "battery#bat2": {
        "bat": "BAT2"
    },
    "power-profiles-daemon": {
        "format": "{icon}",
        "tooltip-format": "Power profile: {profile}\nDriver: {driver}",
        "tooltip": true,
        "format-icons": {
            "default": "",
            "performance": "",
            "balanced": "",
            "power-saver": ""
        }
    },
    "network": {
        "family": "ipv4",
        "format-wifi": "{essid} ({signalStrength}%) ",
        "format-ethernet": "{ipaddr}/{cidr} ",
        "tooltip-format": "{ifname} via {gwaddr} ",
        "format-linked": "{ifname} (No IP) ",
        "format-disconnected": "Disconnected ⚠",
        "format-alt": "{ifname}: {ipaddr}/{cidr}"
    },
    "pulseaudio": {
        "format": "{volume}% {icon} {format_source}",
        "format-bluetooth": "{volume}% {icon} {format_source}",
        "format-bluetooth-muted": " {icon} {format_source}",
        "format-muted": " {format_source}",
        "format-source": "{volume}% ",
        "format-source-muted": "",
        "format-icons": {
            "headphone": "",
            "hands-free": "",
            "headset": "",
            "phone": "",
            "portable": "",
            "car": "",
            "default": ["", "", ""]
        },
        "on-click": "pavucontrol"
    },
    "custom/power": {
        "format": "⏻ ",
        "tooltip": false,
        "menu": "on-click",
        "menu-file": "/usr/share/waybar/custom_modules/power_menu.xml",
        "menu-actions": {
            "shutdown": "shutdown",
            "reboot": "reboot",
            "suspend": "systemctl suspend",
            "hibernate": "systemctl hibernate"
        }
    }
}
HEREDOC

# waybar/style.css
cat > "$DEST"/packaging/paperweight-skel/etc/skel/.config/waybar/style.css << 'HEREDOC'
* {
	border: none;
	border-radius: 10;
	font-family: JetBrainsMonoNL-Regular, FontAwesome, Roboto, Helvetica, Arial, sans-serif;
	font-size: 13px;
	min-height: 10px;
}

window#waybar {
	background-color: transparent;
	color: #FFFFFF
}

window#waybar.hidden {
	opacity: 0.2;
}

button {
	box-shadow: inset 0 -3px transparent;
	border: none;
	border-radius: 0;
}

button:hover {
	background: inherit;
	box-shadow: inset 0 -3px #ffffff;
}

#pulseaudio:hover {
	background-color: #a37800;
}

#workspaces button {
	padding: 0 5px;
	background-color: transparent;
	color: #ffffff;
}

#workspaces button:hover {
	background: rgba(0, 0, 0, 0.2);
}

#workspaces button.focused {
	background-color: #64727D;
	box-shadow: inset 0 -3px #ffffff;
}

#workspaces button.urgent {
	background-color: #eb4d4b;
}

#mode {
	background-color: #64727D;
	box-shadow: inset 0 -3px #ffffff;
}

#clock,
#battery,
#cpu,
#memory,
#disk,
#temperature,
#backlight,
#network,
#pulseaudio,
#wireplumber,
#custom-media,
#tray,
#mode,
#idle_inhibitor,
#scratchpad,
#power-profiles-daemon,
#mpd {
	margin-top: 6px;
	margin-left: 8px;
	padding-left: 10px;
	padding-right: 10px;
	margin-bottom: 0px;
	border-radius: 10px;
	transition: none;
	color: #1A1826;
}

#window,
#workspaces {
	margin: 0 4px;
}

.modules-left > widget:first-child > #workspaces {
	margin-left: 0;
}

.modules-right > widget:last-child > #workspaces {
	margin-right: 0;
}

#clock {
	background-color: #94A2ED;
	color: #000000;
}

#battery {
	background-color: #AB79D6;
	color: #000000;
}

#battery.charging, #battery.plugged {
	background-color: #2ecc71;
	color: #000000;
}

@keyframes blink {
	to {
		background-color: #ffffff;
		color: #000000;
	}
}

#battery.critical:not(.charging) {
	background-color: #f53c3c;
	color: #ffffff;
	animation-name: blink;
	animation-duration: 0.5s;
	animation-timing-function: steps(12);
	animation-iteration-count: infinite;
	animation-direction: alternate;
}

#power-profiles-daemon {
	padding-right: 15px;
}

#power-profiles-daemon.performance {
	background-color: #f53c3c;
	color: #ffffff;
}

#power-profiles-daemon.balanced {
	background-color: #2980b9;
	color: #ffffff;
}

#power-profiles-daemon.power-saver {
	background-color: #2ecc71;
	color: #000000;
}

label:focus {
	background-color: #000000;
}

#cpu {
	background-color: #2ecc71;
	color: #000000;
}

#memory {
	background-color: #AB79D6;
}

#disk {
	background-color: #964B00;
}

#backlight {
	background-color: #FAE370;
}

#network {
	color: #161320;
	background-color: #94A2ED;
}

#network.disconnected {
	color: #F53C3C;
	background: #161320;
}

#pulseaudio {
	color: #1A1826;
	background: #FAE3B0;
}

#pulseaudio.muted {
	background-color: #90b1b1;
	color: #2a5c45;
}

#wireplumber {
	background-color: #fff0f5;
	color: #000000;
}

#wireplumber.muted {
	background-color: #f53c3c;
}

#temperature {
	background-color: #f0932b;
}

#temperature.critical {
	background-color: #eb4d4b;
}

#tray {
	background-color: #2980b9;
}

#tray > .passive {
	-gtk-icon-effect: dim;
}

#tray > .needs-attention {
	-gtk-icon-effect: highlight;
	background-color: #eb4d4b;
}

#idle_inhibitor {
	background-color: #2d3436;
}

#idle_inhibitor.activated {
	background-color: #ecf0f1;
	color: #2d3436;
}

#mpd {
	background-color: #66cc99;
	color: #2a5c45;
}

#mpd.disconnected {
	background-color: #f53c3c;
}

#mpd.stopped {
	background-color: #90b1b1;
}

#mpd.paused {
	background-color: #51a37a;
}

#language {
	background: #00b093;
	color: #740864;
	padding: 0 5px;
	margin: 0 5px;
	min-width: 16px;
}

#keyboard-state {
	background: #97e1ad;
	color: #000000;
	padding: 0 0px;
	margin: 0 5px;
	min-width: 16px;
}

#keyboard-state > label {
	padding: 0 5px;
}

#keyboard-state > label.locked {
	background: rgba(0, 0, 0, 0.2);
}

#scratchpad {
	background: rgba(0, 0, 0, 0.2);
}

#scratchpad.empty {
	background-color: transparent;
}

#privacy {
	padding: 0;
}

#privacy-item {
	padding: 0 5px;
	color: white;
}

#privacy-item.screenshare {
	background-color: #cf5700;
}

#privacy-item.audio-in {
	background-color: #1ca000;
}

#privacy-item.audio-out {
	background-color: #0069d4;
}
HEREDOC

# mako/config
cat > "$DEST"/packaging/paperweight-skel/etc/skel/.config/mako/config << 'HEREDOC'
font=JetBrains Mono 9
background-color=#11111b
text-color=#cdd6f4
border-color=#89b4fa
progress-color=over #313244
border-size=2
border-radius=0
padding=8
margin=8
width=360
height=120
default-timeout=5000
ignore-timeout=0
anchor=top-right

[urgency=high]
border-color=#f38ba8
default-timeout=0
HEREDOC

# wofi/style.css
cat > "$DEST"/packaging/paperweight-skel/etc/skel/.config/wofi/style.css << 'HEREDOC'
window {
  margin: 0px;
  border: 2px solid #89b4fa;
  background-color: #11111b;
  font-family: "JetBrains Mono", monospace;
  font-size: 12px;
}

#input {
  margin: 8px;
  padding: 8px;
  border: 1px solid #313244;
  color: #cdd6f4;
  background-color: #181825;
}

#inner-box {
  margin: 8px;
  background-color: #11111b;
}

#outer-box {
  margin: 0px;
  background-color: #11111b;
}

#scroll {
  margin: 0px;
}

#text {
  margin: 4px;
  color: #cdd6f4;
}

#entry {
  padding: 6px;
  background-color: transparent;
}

#entry:selected {
  background-color: #89b4fa;
}

#entry:selected #text {
  color: #11111b;
}
HEREDOC

# ---------------------------------------------------------------------------
echo ""
echo "Done. Files created:"
find "$DEST/packaging" -type f | sort
echo ""
echo "Next steps:"
echo "  sudo apt install devscripts debhelper build-essential"
echo "  cd $DEST/packaging/paperweight-skel"
echo "  dpkg-buildpackage -us -uc -b"
echo "  sudo dpkg -i ../paperweight-skel_0.1.0-1_all.deb"
echo "  dpkg -L paperweight-skel   # verify installed paths"

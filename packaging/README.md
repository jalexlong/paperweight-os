# PaperweightOS Packaging

This directory contains Debian source packages for PaperweightOS.

## Package Overview

| Package | Purpose |
|---|---|
| `paperweight-desktop` | Metapackage — depends on the full desktop stack |
| `paperweight-skel` | Ships config files into `/etc/skel/` for new users |
| `paperweight-fonts` | JetBrains Mono Nerd Font + Symbols Nerd Font |
| `paperweight-chromebook` | Dell Chromebook 11 3180 hardware support |

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

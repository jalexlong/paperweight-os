# PaperweightOS — TODO

## Blocking (required before any real install works)

- [x] **Nerd Font package** — `paperweight-fonts` ships JetBrainsMono NF +
      Symbols Nerd Font under SIL OFL 1.1. Builds and installs cleanly.

- [x] **GPG key + apt repo publish** — repo live at
      `https://jalexlong.github.io/paperweight-os`. Binary key export fixed.

- [x] **GitHub repo + Pages** — `jalexlong/paperweight-os` published,
      gh-pages branch serving the apt repo.

- [x] **First working VM install** — paperweight-desktop installs and sway
      launches on a fresh Debian Trixie VM. Waybar, swaync, wofi all working.

- [ ] **Verify gtklock is in Trixie** — run `apt-cache show gtklock`.
      If not: substitute swaylock + Macchiato config from dotfiles.

- [ ] **Wallpaper** — sway config references `/usr/share/paperweight-os/wallpapers/default.jpg`.
      Create a `paperweight-wallpapers` package or inline a fallback.
      Without it, sway logs an error on start.

- [ ] **Keybinding audit** — test all bindings in VM; identify what fails
      and whether it's missing deps or VM-specific issues.

---

## Near-term (next few sessions)

- [ ] **`paperweight-chromebook` source package** — currently just a stub in
      `paperweight-desktop/debian/control`. Needs its own source tree under
      `packaging/paperweight-chromebook/` with:
      - `debian/control`, `changelog`, `rules`, `copyright`
      - `etc/skel/.config/sway/config.d/20-keys.conf` (F-key mappings from dotfiles)
      - `etc/skel/.config/sway/config.d/40-workspaces.conf` (app assignments)
      - A chromebook output fragment (wallpaper path override)

- [ ] **brightnessctl udev rule** — add a udev rule or postinst so
      `brightnessctl` works without sudo. Users need to be in the `video` group.

- [ ] **postinst for xdg-user-dirs** — run `xdg-user-dirs-update` on first
      login so ~/Pictures/, ~/Downloads/ etc. exist (screenshot keybinds
      write to ~/Pictures/).

---

## Polish / Roadmap

- [ ] **Theme switcher** — script that swaps `waybar/style.css` imports,
      `90-theme.conf` colors, `swaync/style.css`, and `gtklock/style.css`
      atomically. Triggered via wofi or a keybind.

- [ ] **Additional themes** — Catppuccin Latte (light), Rosé Pine, Gruvbox Material.

- [ ] **`paperweight-wallpapers` package** — curated wallpapers in
      `/usr/share/paperweight-os/wallpapers/`. Default referenced in sway config.

- [ ] **Plymouth splash** — Macchiato-themed boot splash.

- [ ] **GRUB theme** — match Macchiato palette.

- [ ] **Preseed file** — unattended Debian installer config for one-shot installs.

- [ ] **CI via GitHub Actions** — auto-build `.deb`s on push, publish to `gh-pages`.

- [ ] **`live-build` ISO** — long term, after .debs are solid and the apt repo
      is stable.

# PaperweightOS — TODO

## Blocking (required before any real install works)

- [x] **Nerd Font package** — `paperweight-fonts` ships JetBrainsMono NF +
      Symbols Nerd Font under SIL OFL 1.1. Builds and installs cleanly.

- [ ] **Verify gtklock is in Trixie** — run `apt-cache show gtklock`.
      If not: substitute swaylock + Macchiato config from dotfiles.

- [ ] **Wallpaper** — sway config references `/usr/share/paperweight-os/wallpapers/default.jpg`.
      Create a `paperweight-wallpapers` package or inline a fallback.
      Without it, sway logs an error on start.

- [ ] **Rebuild paperweight-skel** — configs changed significantly since the
      last build. Run `dpkg-buildpackage -us -uc -b` in `packaging/paperweight-skel/`.

---

## Near-term (next few sessions)

- [ ] **`paperweight-chromebook` source package** — currently just a stub in
      `paperweight-desktop/debian/control`. Needs its own source tree under
      `packaging/paperweight-chromebook/` with:
      - `debian/control`, `changelog`, `rules`, `copyright`
      - `etc/skel/.config/sway/config.d/20-keys.conf` (F-key mappings from dotfiles)
      - `etc/skel/.config/sway/config.d/40-workspaces.conf` (app assignments)
      - A chromebook output fragment (wallpaper path override)

- [ ] **kitty config in skel** — kitty is the default terminal but has no
      skel config yet. At minimum: Macchiato colors, JetBrains Mono NF font,
      reasonable font size for small laptop screens.

- [ ] **brightnessctl udev rule** — add a udev rule or postinst so
      `brightnessctl` works without sudo. Users need to be in the `video` group.

- [ ] **postinst for xdg-user-dirs** — run `xdg-user-dirs-update` on first
      login so ~/Pictures/, ~/Downloads/ etc. exist (screenshot keybinds
      write to ~/Pictures/).

- [ ] **GitHub repo** — create `jalexlong/paperweight-os`, push this tree,
      enable GitHub Pages on the `gh-pages` branch.

- [ ] **GPG key** — run `bash setup-gpg.sh`, back up the secret key.
      Required before `publish.sh` works.

- [ ] **First apt repo publish** — `bash publish.sh` after GitHub Pages is live.

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

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

- [x] **Verify gtklock is in Trixie** — confirmed at version 4.0.0-1.

- [x] **Wallpaper fallback** — `output * bg $base solid_color` added to
      90-theme.conf; sway shows Macchiato base (#24273a) until a wallpaper
      package is available.

- [ ] **Keybinding audit** — test all bindings in VM; identify what fails
      and whether it's missing deps or VM-specific issues.

---

## Near-term (next few sessions)

- [x] **`paperweight-chromebook` source package** — full source tree created at
      `packaging/paperweight-chromebook/`. Keyboard (1:1:AT_Translated_Set_2_keyboard)
      uses xkb_model "chromebook"; output (eDP-1) set to 1366x768@60Hz.

- [x] **`40-workspaces.conf`** — workspace assignments and app-launch keybinds.
      ws1 terminal, ws2 browser, ws3 helix, ws4 ncspot, ws5 chat, ws6 games.
      Floating variants via $mod+Shift+key. helix/ncspot/cava added to deps.

- [x] **brightnessctl udev rule** — 70-paperweight-backlight.rules grants
      video group write access to brightness sysfs on device discovery.
      postinst enables ADD_EXTRA_GROUPS and adds 'video' to EXTRA_GROUPS
      in /etc/adduser.conf so new users land in the group automatically.

- [x] **xdg-user-dirs on session start** — `exec xdg-user-dirs-update` added
      to 50-desktop-session.conf; runs as user on sway startup.

- [ ] **Publish updated packages** — new packages (paperweight-chromebook,
      skel 0.2.3) need `bash publish.sh` run on the dev laptop with the GPG key.
      Requires: `sudo apt install debhelper reprepro` if not already present.

- [ ] **Verify ncspot, helix, cava in Trixie** — added to paperweight-desktop
      Depends but not confirmed in repos. Run `apt-cache show ncspot helix cava`
      before publishing. Remove from Depends if absent.

- [ ] **Discord/Vesktop floating hack** — `$mod+Shift+c` uses `sleep 2` before
      applying floating via swaymsg. Replace with a polling script that waits
      for the window to appear. May need longer sleep on slow hardware.

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

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

- [x] **Keybinding audit** — all bindings verified against Depends. Fixed:
      removed duplicate $mod+t/$mod+b from base config (superseded by
      config.d/40-workspaces.conf); added XF86AudioPlay/Stop/Prev/Next
      via playerctl. Known silent failures: $mod+s (ncspot), $mod+c (discord).

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

- [x] **CI publishing** — GitHub Actions builds all packages on every push/PR
      and publishes to gh-pages on push to main. `bash publish.sh` is still
      available for local publishing with the GPG key.

- [x] **Verify ncspot, helix, cava in Trixie** — cava ✓ (0.10.4+dfsg-1),
      helix ✓ (package name is `hx`, fixed in control), ncspot ✗ not in Trixie.
      ncspot removed from Depends; install manually via `cargo install ncspot`
      or a third-party .deb. ws4 `$mod+s` keybind will silently fail without it.

- [x] **Discord/Vesktop floating hack** — replaced `sleep 2` with
      `~/.local/bin/sway-wait-float`: polls sway IPC every 0.2s (6s max)
      and applies floating only once the window actually appears.

---

## Polish / Roadmap

- [x] **Theme switcher** — `~/.local/bin/paperweight-theme` applies a named
      theme atomically: sway colors, waybar imports, swaync CSS, gtklock CSS.
      Prompts via wofi with no args. Bound to `$mod+p`.

- [x] **All four Catppuccin variants** — Latte (light), Frappé, Macchiato, Mocha.
      All five per-theme files wired up for each variant.
- [ ] **Additional themes** — Rosé Pine, Gruvbox Material.

- [x] **`paperweight-wallpapers` package** — solid-color Catppuccin wallpapers
      (Latte, Frappé, Macchiato, Mocha) in `/usr/share/paperweight-os/wallpapers/`.
      Includes `91-wallpaper.conf` skel fragment; `paperweight-theme` applies
      wallpaper immediately via swaymsg when the package is installed.

- [x] **Display manager** — greetd + gtkgreet; GTK4 greeter themed with
      Catppuccin CSS. `/etc/greetd/themes/` holds per-variant CSS files.
      `paperweight-theme` updates the login screen via a sudoers-gated
      helper (`paperweight-set-greeter-theme`) on every theme switch.

- [ ] **Plymouth splash** — Macchiato-themed boot splash.

- [x] **GRUB theme** — `paperweight-grub`: Catppuccin Macchiato palette,
      JetBrainsMono Nerd Font compiled to PF2, mauve selection highlight.
      Recommended by `paperweight-desktop`. `paperweight-chromebook` sets
      `GRUB_GFXMODE=1366x768,auto` in its postinst.

- [x] **Preseed file** — `preseed/paperweight.cfg`: automates a Trixie install,
      then adds the PaperweightOS apt repo and installs `paperweight-desktop`
      via `late_command`. Customize disk, locale, and password before use.

- [x] **CI via GitHub Actions** — `.github/workflows/build-and-publish.yml` builds
      all packages on every push/PR; publishes to `gh-pages` on push to `main`
      (requires `GPG_PRIVATE_KEY` + `GPG_PASSPHRASE` secrets in repo settings).

- [ ] **`live-build` ISO** — long term, after .debs are solid and the apt repo
      is stable.

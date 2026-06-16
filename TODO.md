# PaperweightOS — TODO

---

## Completed (summary)

All blocking items are done. The apt repo is live, CI publishes on push to main,
greetd/gtkgreet/Plymouth/GRUB are packaged, all four Catppuccin variants ship,
the theme switcher works end-to-end, and a preseed file exists for semi-automated
Trixie installs. See git log for details.

---

## Bugs / Correctness

- [x] **wofi theming wired up** — `wofi/themes/` ships all four Catppuccin
  variants; `paperweight-theme` copies the active theme to `wofi/style.css`
  alongside swaync and gtklock. `style.css` synced to authoritative macchiato
  palette. Bumped to 0.2.31-1.

- [x] **Duplicate gap/border declarations removed** — dead `gaps inner 5`,
  `gaps outer 5`, `default_border pixel 2` removed from `sway/config`;
  `90-theme.conf` is authoritative. Load-order dependency on `90-colors.conf`
  documented in a comment. Bumped to 0.2.32-1.

- [x] **`cava-waybar` `BARS` derived from config** — script now reads `bars`
  from `~/.config/cava/waybar-config` via `configparser` (fallback 10).
  Hardcoded value removed; the two can no longer silently diverge. 0.2.33-1.

- [x] **`paperweight-theme` validates all theme files upfront** — checks all
  six files (sway, waybar palette+waybar, swaync, gtklock, wofi) before
  touching anything. Lists missing files in the error notification. 0.2.34-1.

- [x] **`paperweight-theme` waybar reload fixed** — replaced `pkill -x waybar;
  waybar &` with `pkill -SIGUSR1 waybar || waybar &`. Graceful reload, no
  double-instance race. Matches the `$mod+Ctrl+w` keybind pattern. 0.2.35-1.

- [ ] **`sway-wait-float` exits silently on timeout** — after 30 polls (6 s) with
  no match it exits 0 with no feedback. Add a `notify-send` or stderr message on
  timeout so the user knows the float never appeared.

- [ ] **`90-theme.conf` depends on `90-colors.conf` load order** — `output * bg
  $base solid_color` requires `$base` from `90-colors.conf`, which sorts earlier
  alphabetically. This is correct today but breaks silently if either file is
  renamed. Add a comment documenting the dependency.

---

## Packaging

- [x] **`waypaper` replaced with yad+wofi picker** — `paperweight-wallpaper`
  now uses `yad --list` with an IMG thumbnail column (scanning system wallpapers
  and `~/Pictures/`) with a `wofi --dmenu` fallback. `waypaper` dep dropped;
  `yad` + `swaybg` added to Depends. Bumped to 0.3.2-1.

- [ ] **`swaybg` undeclared in `paperweight-wallpapers`** — pulled in transitively
  by sway but not listed in `Depends`. Low risk; add it for correctness.

- [ ] **`paperweight-grub` missing `grub-pc | grub-efi-amd64 | grub2` dependency**
  — installs silently on non-GRUB systems. The postinst `/etc/default/grub` guard
  is safe but misleading. Add a soft dependency or a postinst warning.

- [ ] **`paperweight-grub` implicit build-time dep on `paperweight-fonts`** —
  `debian/rules` hardcodes `../paperweight-fonts/usr/share/fonts/...`. Works today
  because alphabetical glob order puts fonts before grub, but will silently break
  if a new package sorts between them. Fix: vendor the TTF into `paperweight-grub`
  or add an explicit check at the top of the build target.

- [ ] **No prerm/postrm for system-level changes** — `postinst` masks
  `getty@tty1`, creates the `greeter` user, and patches `adduser.conf`. None of
  these are undone on `apt remove` or `apt purge`. Acceptable for a personal
  distro today; required before submitting to any archive.

- [ ] **`Replaces: greetd` has no version ceiling** — applies to all past and
  future greetd versions. Add `Replaces: greetd (<< <next-breaking-version>)`
  once greetd stabilizes in Trixie.

- [ ] **frappe and mocha have no artwork wallpapers** — only solid PNGs ship for
  those two flavours; latte and macchiato each have two JPEG artwork variants.
  Either add artwork for all four or document the asymmetry.

- [ ] **README.md package table is stale** — lists `paperweight-wallpapers` at
  `0.1.0` (current: `0.3.0`) and `paperweight-skel` at `0.2.29` (current:
  `0.2.30`). Update to match current changelogs.

- [ ] **`create-packaging.sh` is stale scaffolding** — references kitty, mako,
  nemo, and qutebrowser; none of these are in the shipped stack. Either update
  it to reflect the real package list or delete it to avoid confusing contributors.

---

## CI / Pipeline

- [ ] **No version bump guard** — pushing to `main` without bumping the changelog
  version causes `reprepro` to skip the package silently. Nothing warns that the
  publish was a no-op. Add a pre-publish check that errors if the `.deb` version
  already exists in the pool.

- [ ] **No lintian run in CI** — packages are built with `-us -uc` but never
  lintian-checked. Add a `lintian --fail-on error *.deb` step to the `build` job.

- [ ] **No git tags on published versions** — after a successful publish there is
  no durable mark in git. Tag each published version (e.g. `paperweight-skel/0.2.30`)
  so the apt repo state is always traceable to a commit.

- [ ] **`build` job apt-installs are not declarative** — currently hardcodes
  `debhelper build-essential grub-common`. New build-dep additions require a
  manual CI edit. Consider auto-parsing `Build-Depends` from each `debian/control`
  and installing them, or at least add `plymouth` tools now that
  `paperweight-plymouth` is in the tree.

- [ ] **`preseed/paperweight.cfg` is never validated in CI** — syntax errors only
  surface at install time. Add a `debconf-set-selections --checkonly` or
  `preseed-verify` step to the `build` job.

---

## Roadmap — Path to Full Distro Status

- [ ] **`live-build` ISO** — long term, after the apt repo is stable and
  installation has been verified on real hardware. Start with a netinstall ISO
  that downloads packages; full offline ISO later.

- [ ] **Hardware test matrix** — only the Dell Chromebook 11 (coreboot) has been
  tested as a target. Document which generic x86 laptops work out of the box and
  what (if anything) breaks on non-Chromebook targets.

- [ ] **ncspot in the personal apt repo** — `$mod+s` silently fails without it and
  it is not in Trixie. Options: pre-built .deb in the repo, or find a Trixie-native
  TUI music player to replace it (`cmus`, `musikcube`).

- [ ] **`paperweight-network` script** — yad-based Wi-Fi manager wrapping
  nmcli. Flow: `nmcli -t dev wifi list` → `yad --list` table (IN-USE,
  SSID, signal, security columns) → on selection, `yad --entry --hide-text`
  for password if needed → `nmcli device wifi connect`. Bind to a keybind
  (e.g. `$mod+n`). yad is already a dep via paperweight-wallpapers so no
  new package dependency required.

- [ ] **User-facing install docs** — the README has the four-line apt snippet but
  nothing covering: locale/timezone during preseed, disk partitioning choices,
  post-install first-boot steps, or how to add `video` group membership for
  existing users (currently documented only in CLAUDE.md Known Issues).

- [ ] **Theme authoring guide** — CLAUDE.md documents the five per-theme files
  but `wofi/themes/` doesn't exist yet (see bug above), and gtkgreet themes live
  under `/etc/greetd/themes/` (system) not skel. Reconcile the guide with reality
  once wofi theming is fixed.

- [ ] **Additional themes beyond Catppuccin** — the architecture supports arbitrary
  themes but only Catppuccin variants exist. A Nord or Dracula variant would
  validate that the theme switcher works across palette families (especially
  important for the Latte → dark-theme contrast path).

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

- [x] **`swaybg` declared in `paperweight-wallpapers`** — already added with
  the yad change (0.3.2-1). No further action needed.

- [x] **`paperweight-grub` GRUB Recommends added** — `Recommends: grub-pc |
  grub-efi-amd64 | grub-efi-arm64` added to control. 0.1.2-1.

- [x] **`paperweight-grub` build-time dep made explicit** — `debian/rules` now
  fails fast with a clear error if `paperweight-fonts` hasn't been built first,
  rather than passing a missing path to grub-mkfont. 0.1.2-1.

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

- [x] **README.md package table updated** — all versions current; added
  `Super+w` wallpaper picker binding to keybindings table.

- [x] **`create-packaging.sh` deleted** — stale scaffold referencing kitty,
  mako, nemo, qutebrowser. Actual package structure in `packaging/` is
  authoritative.

---

## CI / Pipeline

- [x] **Version bump notice added** — publish job tracks published vs skipped
  counts; emits a `::notice::` if all packages were skipped (version not bumped).

- [x] **Lintian added to CI** — `lintian --fail-on error packaging/*.deb` runs
  in the `build` job after building.

- [x] **Git tags on published versions** — publish job tags each newly included
  package as `<package>/<version>` and pushes tags to origin.

- [x] **Build-Depends now declarative** — CI parses `Build-Depends` from all
  `debian/control` files at runtime and installs them. `lintian` and
  `debconf-utils` added as fixed extras. No more manual apt list maintenance.

- [x] **Preseed validated in CI** — `debconf-set-selections --checkonly
  preseed/paperweight.cfg` runs in the `build` job.

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

- [x] **`paperweight-network` script** — yad Wi-Fi picker wrapping nmcli.
  Signal bar column, password prompt for secured networks, notify-send on
  result. Bound to `$mod+n`. All yad windows float via
  `for_window [app_id="yad"] floating enable` in 90-theme.conf. 0.2.36-1.

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

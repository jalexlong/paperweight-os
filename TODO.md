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
  _(Partially fixed — see 0.2.47 below.)_

- [x] **`paperweight-theme` waybar crash on theme switch fixed** — `swaymsg reload`
  is synchronous and causes sway to kill+relaunch waybar (sway-managed bar); the
  `pkill -SIGUSR1 waybar` on the next line then hit the freshly started process
  during initialization, crashing it. Removed the redundant SIGUSR1 line entirely.
  Also made `waybar/style.css` write atomic (tmp file + `mv`) so waybar can't read
  a truncated file during its restart window. 0.2.47-1.

- [x] **`sway-wait-float` exits silently on timeout** — now emits a `notify-send`
  on timeout and exits 1. 0.2.37-1.

- [x] **`90-theme.conf` depends on `90-colors.conf` load order** — comment
  already present in the file header; documents the alphabetical load-order
  dependency and the requirement that 90-colors.conf sorts first.

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

- [x] **No prerm/postrm for system-level changes** — `postrm` now unmasks
  `getty@tty1` on remove/purge and removes the `greeter` system user on purge
  (only if greetd is also gone). `adduser.conf` EXTRA_GROUPS change is
  intentionally left in place — stripping video group from existing users
  on uninstall is too invasive.

- [x] **`Replaces: greetd` has no version ceiling** — capped at `(<< 1.0)`;
  greetd in Trixie is 0.10.3-4. Will need revisiting if greetd hits 1.0.

- [x] **frappe and mocha have no artwork wallpapers** — frappe-wallpaper1.jpg
  and mocha-wallpaper1.jpg added (placeholder artwork). All four variants now
  have at least one JPEG alongside their solid-color PNG.

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

- [x] **Hardware test matrix** — HARDWARE.md written. Covers the Dell Chromebook
  11 3180 as the primary confirmed target, generic x86 compatibility by category
  (GPU, input, audio, WiFi, power, storage), known issues (NVIDIA, Broadcom,
  HiDPI), and the pattern for adding new hardware packages. Linked from README.

- [x] **ncspot replaced with cmus** — `cmus` added to `paperweight-desktop` Depends.
  `$mod+s` repurposed as layout toggle (tabbed / splith). Workspace 4 still
  reserved for music; launch cmus from a foot terminal. 0.1.11-1 / 0.2.38-1.

- [x] **`paperweight-network` script** — yad Wi-Fi picker wrapping nmcli.
  Signal bar column, password prompt for secured networks, notify-send on
  result. Bound to `$mod+n`. All yad windows float via
  `for_window [app_id="yad"] floating enable` in 90-theme.conf. 0.2.36-1.

- [x] **User-facing install docs** — README now has a First Boot section
  (video group, theme switching, cmus, Discord) and an expanded Preseed
  section (disk selection table, locale/timezone, password hash, HTTP/USB
  boot instructions, virt-manager note).

- [x] **Theme authoring guide** — THEME-AUTHORING.md written; covers all
  seven per-user files (sway, waybar ×2, swaync, gtklock, wofi, foot),
  system surfaces (gtkgreet, GRUB, Plymouth), wallpaper convention, packaging
  registration steps, and a testing checklist. CLAUDE.md stub updated to
  reference it and corrected from "five files" to seven.

- [ ] **Additional themes beyond Catppuccin** — the architecture supports arbitrary
  themes but only Catppuccin variants exist. A Nord or Dracula variant would
  validate that the theme switcher works across palette families (especially
  important for the Latte → dark-theme contrast path).

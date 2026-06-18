# PaperweightOS Hardware Compatibility

## Status key

| Symbol | Meaning |
|---|---|
| ✅ | Tested on real hardware, works |
| ⚠️ | Works with caveats or manual setup |
| ❌ | Known not to work |
| 🔲 | Untested — expected to work but unverified |

---

## Tested hardware

### Dell Chromebook 11 3180 ("Paperweight Pro") — Primary target

| Component | Status | Notes |
|---|---|---|
| **Boot** | ✅ | coreboot + SeaBIOS or UEFI/Tianocore payload |
| **CPU** | ✅ | Intel Celeron N3060 (Braswell, 2C/2T, 1.6–2.48 GHz) |
| **iGPU / Wayland** | ✅ | Intel HD 400 (Braswell); sway/wlroots via i915 |
| **eMMC storage** | ✅ | `/dev/mmcblk0`; 16 or 32 GB depending on config |
| **Display** | ✅ | Chimei Innolux eDP-1, 1366×768@60 Hz, scale 1 |
| **Internal keyboard** | ✅ | AT Translated Set 2; top-row remapped by `paperweight-chromebook` |
| **Touchpad** | ✅ | libinput; tap-to-click, natural scroll, dwt enabled |
| **Audio** | ✅ | PipeWire + WirePlumber; HDMI audio untested |
| **WiFi** | ✅ | Intel Wireless 7265; firmware-iwlwifi from non-free-firmware |
| **Bluetooth** | 🔲 | Hardware present; not tested |
| **USB** | ✅ | USB 3.0 ports; USB boot confirmed |
| **SD card reader** | 🔲 | Present; not tested |
| **Webcam** | 🔲 | Present; not tested under Wayland |
| **Backlight** | ✅ | brightnessctl via video group; keys bound in sway |
| **Suspend / resume** | 🔲 | swayidle configured; not tested on this unit |
| **Battery** | ✅ | waybar battery module shows charge/discharge |

**Required:** Install `paperweight-chromebook` after `paperweight-desktop`.
This adds keyboard remapping, top-row media keys, and sets
`GRUB_GFXMODE=1366x768` in `/etc/default/grub`.

---

## Generic x86 laptop compatibility

`paperweight-desktop` targets any x86 laptop running Debian Trixie. The
following reflects expected behavior based on Debian and wlroots compatibility,
not systematic testing on multiple machines.

### Graphics / display

| Scenario | Status | Notes |
|---|---|---|
| Intel iGPU (Haswell and newer) | 🔲 | i915 + wlroots; should work |
| Intel iGPU (Braswell/Bay Trail) | ✅ | Tested on Chromebook 11 |
| AMD iGPU (GCN and newer) | 🔲 | amdgpu + wlroots; should work |
| AMD iGPU (pre-GCN) | 🔲 | radeon driver; wlroots support varies |
| NVIDIA (discrete or MX series) | ⚠️ | nouveau unreliable under Wayland; proprietary driver needed but not in Depends |
| HiDPI display | ⚠️ | sway `scale` must be set manually in a `config.d/` fragment; no auto-detection |
| Multi-monitor | 🔲 | sway supports it; config fragments required per setup |
| External display via HDMI/DP | 🔲 | Should work via wlroots output management |

### Input

| Scenario | Status | Notes |
|---|---|---|
| PS/2 and USB keyboards | 🔲 | Should work; `10-input.conf` sets generic repeat rate |
| Synaptics / libinput touchpads | 🔲 | `10-input.conf` configures libinput tap, scroll, dwt |
| Touchscreens | ❌ | Not configured; no wlr-touch bindings in skel |
| Fingerprint readers | ❌ | fprintd not in Depends; not integrated |
| Stylus / drawing tablets | 🔲 | Not configured |

### Audio

| Scenario | Status | Notes |
|---|---|---|
| Intel HDA (most laptops) | 🔲 | PipeWire + WirePlumber; should work |
| USB audio | 🔲 | Should work via PipeWire |
| HDMI/DP audio passthrough | 🔲 | Untested |

### Networking

| Scenario | Status | Notes |
|---|---|---|
| Intel WiFi (iwlwifi) | ✅ | Confirmed on Chromebook; firmware-iwlwifi required |
| Realtek WiFi (rtw88/rtw89) | 🔲 | firmware-realtek required; should work |
| Mediatek WiFi | 🔲 | firmware-mediatek required |
| Broadcom WiFi (BCM43xx) | ⚠️ | Needs firmware-b43 or broadcom-sta (non-free); notoriously painful on Debian |
| Ethernet (Intel/Realtek) | 🔲 | Should work; NetworkManager handles it |

### Power

| Scenario | Status | Notes |
|---|---|---|
| Battery reporting | 🔲 | waybar battery module; requires `upower` (in Debian base) |
| Backlight control | ✅ | brightnessctl; user must be in `video` group (postinst adds for new users) |
| Suspend to RAM (S3) | 🔲 | swayidle calls `swaymsg "output * power off"`; full S3 untested |
| Hibernate | ❌ | Not configured |
| `power-profiles-daemon` | 🔲 | In Depends; D-Bus interface available but no sway binding yet |

### Storage / boot

| Scenario | Status | Notes |
|---|---|---|
| SATA SSD/HDD | 🔲 | Standard Debian install; preseed uses `/dev/sda` |
| NVMe SSD | 🔲 | Preseed includes `/dev/nvme0n1` option |
| eMMC | ✅ | Confirmed on Chromebook 11; preseed uses `/dev/mmcblk0` |
| UEFI boot | 🔲 | `paperweight-grub` ships GRUB EFI; standard Debian installer handles it |
| Legacy BIOS boot | 🔲 | `paperweight-grub` supports it; `grub-pc` in Recommends |
| Secure Boot | ⚠️ | Not configured; MOK enrollment not documented |

---

## Known issues on generic hardware

**NVIDIA discrete GPU:** nouveau (the open-source driver) has poor Wayland
support and may fail to start sway entirely. The proprietary `nvidia` driver
works but is not in `Depends` and requires manual setup. On laptops with
NVIDIA Optimus (Intel + NVIDIA), the Intel iGPU should drive Wayland normally
with NVIDIA unused or disabled in BIOS.

**Broadcom WiFi:** Broadcom chips are notoriously difficult on Debian.
`firmware-b43` (non-free) or `broadcom-sta` (dkms, requires kernel headers)
may be required. Neither is in `Depends`. If WiFi is unavailable after install,
connect via USB Ethernet or a USB WiFi adapter to run `apt install`.

**HiDPI:** sway does not auto-detect the correct scale. Add a `config.d/`
fragment to set the output scale:
```
# ~/.config/sway/config.d/51-hidpi.conf
output eDP-1 scale 2   # or 1.5 for 125%
```
The `paperweight-chromebook` package is the model for this pattern.

**Existing users and `video` group:** `postinst` patches `adduser.conf` so
new users land in the `video` group for `brightnessctl`. Users who exist at
install time need a manual `sudo usermod -aG video $USER` and re-login.

---

## Adding hardware support for a new target

The `paperweight-chromebook` package demonstrates the pattern:

1. Create a new package under `packaging/paperweight-<hardware>/`
2. Add `config.d/` fragments for input overrides, output config, and any
   hardware-specific keybindings (use a numeric prefix that slots correctly
   between the base skel fragments — e.g. `15-` for input overrides after
   skel's `10-input.conf`)
3. Add a `postinst` to set any system-level parameters (e.g. GRUB_GFXMODE)
4. Set `Depends: paperweight-desktop` so the full stack is present

The fragment include in sway config (`include ~/.config/sway/config.d/*.conf`)
picks up hardware fragments automatically. No changes to base packages needed.

---

## Contributing test results

If you test PaperweightOS on hardware not listed here, please open an issue
at https://github.com/jalexlong/paperweight-os with:
- Machine make/model and year
- CPU and iGPU
- WiFi chip (from `lspci -k | grep -A2 Network`)
- Whether `paperweight-desktop` installed and started sway successfully
- Any components that didn't work and what errors appeared

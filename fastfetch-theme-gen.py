#!/usr/bin/env python3
"""Generate a PaperweightOS fastfetch theme file from a sway theme palette.

fastfetch doesn't accept raw hex in its jsonc color fields — it wants ANSI
SGR parameter strings (e.g. "1;38;2;138;173;244" for bold truecolor). This
reads the 26-variable palette already defined in a sway theme file (the
canonical source per THEME-AUTHORING.md) and emits a matching
~/.config/fastfetch/themes/<name>.jsonc, so a new theme's fastfetch colors
never have to be hand-converted or re-typed.

The logo is a fixed ASCII-art rock (ROCK_LOGO below), rendered via
fastfetch's "data" logo type and two-toned grey/silver with `$1`/`$2`
placeholders. The two grey shades are fixed hex (GREY_ON_DARK_BG /
GREY_ON_LIGHT_BG below), not sourced from the theme's own palette: an
earlier version used Catppuccin's `overlay2`/`overlay0` neutral-scale
roles, but Catppuccin's whole neutral scale is tinted toward the same
blue-violet family as `lavender`, so it still read as "the accent color"
rather than true silver. Which fixed pair applies is chosen per theme by
checking whether its `base` role is dark or light (is_dark_hex() below,
WCAG relative luminance) — same fixed grey for all three dark themes
(macchiato/mocha/frappe), a different, contrast-flipped pair for latte,
since a single fixed pair can't have good contrast against both a
near-black and a near-white background at once.

"data" was chosen over the earlier "chafa" raster approach (which shelled
out to chafa to downsample paperweight-plymouth's rock.png) because it
needs no external image, no chafa dependency, and no width/height/aspect-
ratio tuning to keep fastfetch's cursor math aligned with the info lines —
it's just text, so it renders identically in any terminal, including over
SSH and inside tmux with no passthrough configuration. The art and its
light/dark split are theme-agnostic; only the two colors change per theme.

Usage:
    ./fastfetch-theme-gen.py <name> [--label "Display Name"]
    ./fastfetch-theme-gen.py macchiato
    ./fastfetch-theme-gen.py sunset --label "Sunset"

    # Convert a single hex color to fastfetch's SGR format, e.g. for
    # spot-checking a value or using in a hand-written jsonc file:
    ./fastfetch-theme-gen.py --hex 8aadf4 --bold

By default reads from and writes to the packaging tree paths used by
paperweight-skel:
    packaging/paperweight-skel/etc/skel/.config/sway/themes/<name>.conf
    packaging/paperweight-skel/etc/skel/.config/fastfetch/themes/<name>.jsonc
"""

import argparse
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent
SKEL_CONFIG = REPO_ROOT / "packaging" / "paperweight-skel" / "etc" / "skel" / ".config"
SWAY_THEMES = SKEL_CONFIG / "sway" / "themes"
FASTFETCH_THEMES = SKEL_CONFIG / "fastfetch" / "themes"

# Fixed ASCII-art rock logo, two-toned via inline `$1`/`$2` markers (see
# apply_two_tone() and TEMPLATE below). Kept here as a plain multi-line
# string, not per-theme.
#
# Traced from the actual rock.png brand asset (see
# packaging/paperweight-plymouth/.../rock.png), not hand-drawn: that PNG is
# a cel-shaded low-poly rock with a handful of discrete facet grays and a
# black outline, so it was sampled on a small supersampled grid and each
# facet's luminance quantized onto the classic ` .:-=+*#%@` density ramp
# (light facets → sparse chars, the outline/dark facets → dense chars).
# That keeps the silhouette's flat-bottomed, angular-topped shape and its
# light-upper-left / dark-lower-right shading faithful to the source art,
# at roughly a third the line count of the earlier hand-drawn blob.
ROCK_LOGO = """        @@..----@@
      @....------*@
    @@--.--------**@
  @....----------***@
@------+++++++++*****@
@*----+++++++****%%**@
@**--++++++******%%%%@
@***%%%%%*********%@
  @@%%%%%%****@@%
         @%@"""

# Which density characters get the light vs. dark tone (see apply_two_tone).
# '.' and '-' are the brighter/highlight facets; '+', '*', '%', '@' cover the
# mid-tone facets, dark facets, and the black outline.
LIGHT_CHARS = ".-"
DARK_CHARS = "+*%@"


def apply_two_tone(art: str, light_chars: str = LIGHT_CHARS, dark_chars: str = DARK_CHARS) -> str:
    """Insert `$1`/`$2` color markers into ASCII art at each light/dark run boundary.

    fastfetch's "data" logo type substitutes `$1`, `$2`, ... verbatim with the
    matching entry from the logo's "color" object and lets the terminal's own
    SGR state carry that color forward until the next marker — so a marker is
    only needed where the tone actually changes, not on every character.
    Whitespace and newlines don't affect the active tone (no marker needed
    around them), which keeps the output free of redundant markers.
    """
    out = []
    active = None
    for ch in art:
        if ch in light_chars and active != "1":
            out.append("$1")
            active = "1"
        elif ch in dark_chars and active != "2":
            out.append("$2")
            active = "2"
        out.append(ch)
    return "".join(out)

# Maps the fastfetch theme's semantic roles to sway palette variable names.
# See THEME-AUTHORING.md's "26 palette variables" table. "base" isn't
# rendered into the template directly — it's only read to pick which fixed
# grey pair the logo uses (see is_dark_hex() and generate()).
ROLES = {
    "lavender": "lavender",
    "blue": "blue",
    "overlay1": "overlay1",
    "surface2": "surface2",
    "text": "text",
    "green": "green",
    "yellow": "yellow",
    "red": "red",
    "base": "base",
}

# Fixed achromatic grey pairs for the logo's light/dark facets — deliberately
# not derived from the theme palette (see module docstring). Values chosen
# by rendering the logo against all four themes' actual backgrounds and
# checking WCAG contrast; GREY_ON_LIGHT_BG's tones are darker overall than
# GREY_ON_DARK_BG's since latte's background is inverted (near-white).
GREY_ON_DARK_BG = ("#c8ccd0", "#6b6f75")   # (light facet, dark facet)
GREY_ON_LIGHT_BG = ("#787d84", "#33363b")

TEMPLATE = """// PaperweightOS fastfetch theme — {label}
// Generated by fastfetch-theme-gen.py from sway/themes/{name}.conf.
// Written by paperweight-theme at runtime; edit this file (or the sway
// palette + regenerate), not the live ~/.config/fastfetch/config.jsonc.
{{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {{
        "type": "data",
        "source": {logo_source},
        "color": {{ "1": "{grey_light_bold}", "2": "{grey_dark}" }},
        "padding": {{ "top": 1, "right": 2 }}
    }},
    "display": {{
        "separator": " ",
        "key": {{ "width": 10 }},
        "color": {{
            "keys": "{lavender_bold}",
            "output": "{text}",
            "separator": "{surface2}"
        }},
        "percent": {{
            "color": {{
                "green": "{green}",
                "yellow": "{yellow}",
                "red": "{red}"
            }}
        }}
    }},
    "modules": [
        {{
            "type": "title",
            "color": {{ "user": "{blue_bold}", "at": "{overlay1}", "host": "{lavender_bold}" }}
        }},
        "separator",
        {{ "type": "os", "key": "OS" }},
        {{ "type": "kernel", "key": "Kernel" }},
        {{ "type": "uptime", "key": "Uptime" }},
        {{ "type": "cpu", "key": "CPU" }},
        {{ "type": "memory", "key": "Memory" }},
        {{ "type": "disk", "folders": "/", "key": "Disk" }},
        {{ "type": "localip", "defaultRouteOnly": true, "key": "IP" }},
        {{
            "type": "battery",
            "key": "Battery",
            "format": "{{capacity}} ({{time-hours}}h {{time-minutes}}m remaining) [{{status}}]"
        }}
    ]
}}
"""

HEX_RE = re.compile(r"^#?([0-9a-fA-F]{6})$")


def hex_to_sgr(hexval: str, bold: bool = False) -> str:
    """Convert a #rrggbb color to a fastfetch truecolor SGR string."""
    m = HEX_RE.match(hexval.strip())
    if not m:
        raise ValueError(f"not a 6-digit hex color: {hexval!r}")
    h = m.group(1)
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    prefix = "1;" if bold else ""
    return f"{prefix}38;2;{r};{g};{b}"


def is_dark_hex(hexval: str) -> bool:
    """WCAG relative luminance test: True if hexval reads as a dark background."""
    m = HEX_RE.match(hexval.strip())
    if not m:
        raise ValueError(f"not a 6-digit hex color: {hexval!r}")
    h = m.group(1)

    def lin(c: float) -> float:
        c /= 255
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4

    r, g, b = (lin(int(h[i:i + 2], 16)) for i in (0, 2, 4))
    luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
    return luminance < 0.5


def parse_sway_palette(conf_path: Path) -> dict[str, str]:
    """Parse `set $name #hexhex` lines out of a sway theme file."""
    palette = {}
    line_re = re.compile(r"^\s*set\s+\$(\w+)\s+(#[0-9a-fA-F]{6})\s*$")
    for line in conf_path.read_text().splitlines():
        m = line_re.match(line)
        if m:
            palette[m.group(1)] = m.group(2)
    return palette


def guess_label(conf_path: Path, name: str) -> str:
    """Pull a display label from the theme file's leading comment, if any."""
    first_line = conf_path.read_text().splitlines()[0] if conf_path.exists() else ""
    m = re.match(r"#\s*(.+?)\s*—", first_line)
    if m:
        return m.group(1)
    return name.capitalize()


def generate(
    name: str,
    label: str | None,
    sway_dir: Path,
    out_dir: Path,
) -> Path:
    conf_path = sway_dir / f"{name}.conf"
    if not conf_path.is_file():
        sys.exit(f"error: no sway theme found at {conf_path}")

    palette = parse_sway_palette(conf_path)
    missing = [var for var in ROLES.values() if var not in palette]
    if missing:
        sys.exit(f"error: {conf_path} is missing palette variable(s): {', '.join(missing)}")

    label = label or guess_label(conf_path, name)

    grey_light, grey_dark = GREY_ON_DARK_BG if is_dark_hex(palette["base"]) else GREY_ON_LIGHT_BG

    content = TEMPLATE.format(
        name=name,
        label=label,
        logo_source=json.dumps(apply_two_tone(ROCK_LOGO)),
        lavender_bold=hex_to_sgr(palette["lavender"], bold=True),
        grey_light_bold=hex_to_sgr(grey_light, bold=True),
        grey_dark=hex_to_sgr(grey_dark),
        blue_bold=hex_to_sgr(palette["blue"], bold=True),
        overlay1=hex_to_sgr(palette["overlay1"]),
        surface2=hex_to_sgr(palette["surface2"]),
        text=hex_to_sgr(palette["text"]),
        green=hex_to_sgr(palette["green"]),
        yellow=hex_to_sgr(palette["yellow"]),
        red=hex_to_sgr(palette["red"]),
    )

    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"{name}.jsonc"
    out_path.write_text(content)
    return out_path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("name", nargs="?", help="theme name, e.g. macchiato (matches sway/themes/<name>.conf)")
    parser.add_argument("--label", help="display label for the generated file's header comment")
    parser.add_argument("--sway-dir", type=Path, default=SWAY_THEMES, help="directory containing sway theme .conf files")
    parser.add_argument("--out-dir", type=Path, default=FASTFETCH_THEMES, help="directory to write the fastfetch theme .jsonc into")
    parser.add_argument("--hex", help="convert a single #rrggbb color to fastfetch SGR format and exit")
    parser.add_argument("--bold", action="store_true", help="with --hex, emit the bold variant")
    args = parser.parse_args()

    if args.hex:
        print(hex_to_sgr(args.hex, bold=args.bold))
        return

    if not args.name:
        parser.error("name is required unless --hex is given")

    out_path = generate(args.name, args.label, args.sway_dir, args.out_dir)
    print(f"wrote {out_path.relative_to(REPO_ROOT)}")


if __name__ == "__main__":
    main()
